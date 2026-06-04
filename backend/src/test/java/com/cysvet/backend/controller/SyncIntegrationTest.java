package com.cysvet.backend.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.cysvet.backend.dto.auth.RegisterRequest;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.repository.UsuarioEmpresaRepository;
import com.cysvet.backend.repository.UsuarioRepository;
import com.cysvet.backend.service.AuthService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Instant;
import java.util.Iterator;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class SyncIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private AuthService authService;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private UsuarioEmpresaRepository usuarioEmpresaRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void syncPullShouldReturnCompleteSnapshotForRehydration() throws Exception {
        AuthContext auth = registerAndAuthenticate("sync.snapshot@example.com", "Admin Snapshot", "123456");

        JsonNode property = createProperty(auth, """
                {
                  "idExterno": "prop-sync-full-1",
                  "nome": "Fazenda Snapshot",
                  "nomeProprietario": "Helena"
                }
                """);
        long propertyId = property.path("id").asLong();
        JsonNode lot = firstLotForProperty(auth, propertyId);
        long lotId = lot.path("id").asLong();

        createAnimal(auth, """
                {
                  "idExterno": "animal-sync-full-1",
                  "idPropriedade": %d,
                  "idLote": %d,
                  "codigo": "A-SYNC-01",
                  "categoria": "VACA",
                  "sexo": "Femea",
                  "numeroLactacao": 2
                }
                """.formatted(propertyId, lotId));

        createVisit(auth, """
                {
                  "idExterno": "visit-sync-full-1",
                  "idPropriedade": %d,
                  "dataVisita": "2026-05-20",
                  "observacoes": "Visita de snapshot",
                  "animais": [
                    {
                      "animalId": %d,
                      "animalIdExterno": "animal-sync-full-1",
                      "animalCodigo": "A-SYNC-01"
                    }
                  ]
                }
                """.formatted(propertyId, findAnimalIdByExternalId(auth, "animal-sync-full-1")));

        createEvent(auth, """
                {
                  "idExterno": "event-sync-full-1",
                  "idPropriedade": %d,
                  "idExternoAnimal": "animal-sync-full-1",
                  "tipo": "INSEMINATION",
                  "dataEvento": "2026-05-21",
                  "prenhezConfirmada": false
                }
                """.formatted(propertyId));

        JsonNode pull = pullSnapshot(auth, null);

        assertNotNull(pull.path("serverTime").asText(null));
        assertEquals("prop-sync-full-1", findByExternalId(pull.path("properties"), "prop-sync-full-1").path("idExterno").asText());
        assertEquals("prop-sync-full-1", findByExternalId(pull.path("lots"), lot.path("idExterno").asText()).path("idExternoPropriedade").asText());
        assertEquals(lot.path("idExterno").asText(), findByExternalId(pull.path("animals"), "animal-sync-full-1").path("idExternoLote").asText());
        assertEquals("prop-sync-full-1", findByExternalId(pull.path("visits"), "visit-sync-full-1").path("idExternoPropriedade").asText());
        assertEquals("animal-sync-full-1", findByExternalId(pull.path("visits"), "visit-sync-full-1").path("animais").path(0).path("animalIdExterno").asText());
        assertEquals("animal-sync-full-1", findByExternalId(pull.path("events"), "event-sync-full-1").path("idExternoAnimal").asText());
        assertFalse(hasDeletedRecord(pull.path("deletedRecords"), "visit", "visit-sync-full-1"));
    }

    @Test
    void syncShouldValidatePayloadAndReplayIdempotentlyWithExternalId() throws Exception {
        AuthContext auth = registerAndAuthenticate("sync.validation@example.com", "Admin Validation", "123456");

        mockMvc.perform(post("/api/sync")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "items": [
                                    {
                                      "chaveMutacao": "mut-lot-invalid-1",
                                      "operationType": "CREATE",
                                      "entity": "lot",
                                      "payload": {
                                        "idExterno": "lot-invalid-1",
                                        "nome": "Lote sem propriedade"
                                      }
                                    }
                                  ]
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Lote deve informar idPropriedade ou idExternoPropriedade"));

        String syncRequest = """
                {
                  "items": [
                    {
                      "chaveMutacao": "mut-property-sync-1",
                      "operationType": "CREATE",
                      "entity": "property",
                      "payload": {
                        "idExterno": "prop-sync-idem-1",
                        "nome": "Fazenda Idempotente",
                        "nomeProprietario": "Marina"
                      }
                    }
                  ]
                }
                """;

        mockMvc.perform(post("/api/sync")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content(syncRequest))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].idExterno").value("prop-sync-idem-1"))
                .andExpect(jsonPath("$.items[0].status").value("SYNCED"));

        mockMvc.perform(post("/api/sync")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content(syncRequest))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].idExterno").value("prop-sync-idem-1"))
                .andExpect(jsonPath("$.items[0].message").value("Operacao reaproveitada por idempotencia"));
    }

    @Test
    void deletedRecordShouldBeClearedAcrossUsersInSameTenantWhenEntityIsRecreated() throws Exception {
        AuthContext admin = registerAndAuthenticate("sync.deleted.admin@example.com", "Admin Deleted", "123456");
        createVeterinarian(admin, "Vet Deleted", "sync.deleted.vet@example.com", "123456");
        AuthContext veterinarian = login("sync.deleted.vet@example.com", "123456");

        JsonNode property = createProperty(admin, """
                {
                  "idExterno": "prop-deleted-shared-1",
                  "nome": "Fazenda Shared",
                  "nomeProprietario": "Bianca"
                }
                """);
        long propertyId = property.path("id").asLong();

        JsonNode visit = createVisit(admin, """
                {
                  "idExterno": "visit-shared-1",
                  "idPropriedade": %d,
                  "dataVisita": "2026-05-18",
                  "observacoes": "Primeira visita"
                }
                """.formatted(propertyId));
        long visitId = visit.path("id").asLong();

        String since = Instant.now().minusSeconds(5).toString();

        mockMvc.perform(delete("/api/visits/{id}", visitId)
                        .header("Authorization", admin.authorization())
                        .header("empresaid", admin.tenantId()))
                .andExpect(status().isNoContent());

        JsonNode deletedPull = pullSnapshot(veterinarian, since);
        assertFalse(deletedPull.path("deletedRecords").isEmpty());
        assertEquals(true, hasDeletedRecord(deletedPull.path("deletedRecords"), "visit", "visit-shared-1"));

        createVisit(veterinarian, """
                {
                  "idExterno": "visit-shared-1",
                  "idExternoPropriedade": "prop-deleted-shared-1",
                  "dataVisita": "2026-05-19",
                  "observacoes": "Visita recriada"
                }
                """);

        JsonNode recreatedPull = pullSnapshot(admin, since);
        assertFalse(hasDeletedRecord(recreatedPull.path("deletedRecords"), "visit", "visit-shared-1"));
        assertEquals("visit-shared-1", findByExternalId(recreatedPull.path("visits"), "visit-shared-1").path("idExterno").asText());
    }

    @Test
    void syncUpsertShouldNotApplyCalvingSideEffectTwiceForExistingEvent() throws Exception {
        AuthContext auth = registerAndAuthenticate("sync.calving@example.com", "Admin Calving", "123456");

        JsonNode property = createProperty(auth, """
                {
                  "idExterno": "prop-calving-1",
                  "nome": "Fazenda Calving",
                  "nomeProprietario": "Lucas"
                }
                """);
        long propertyId = property.path("id").asLong();

        createAnimal(auth, """
                {
                  "idExterno": "animal-calving-1",
                  "idPropriedade": %d,
                  "codigo": "CALV-01",
                  "categoria": "VACA",
                  "sexo": "Femea",
                  "numeroLactacao": 0
                }
                """.formatted(propertyId));

        String firstSync = """
                {
                  "items": [
                    {
                      "chaveMutacao": "mut-calving-1",
                      "operationType": "CREATE",
                      "entity": "event",
                      "payload": {
                        "idExterno": "event-calving-1",
                        "idExternoPropriedade": "prop-calving-1",
                        "idExternoAnimal": "animal-calving-1",
                        "tipo": "CALVING",
                        "dataEvento": "2026-05-10"
                      }
                    }
                  ]
                }
                """;

        String secondSync = firstSync.replace("mut-calving-1", "mut-calving-2");

        mockMvc.perform(post("/api/sync")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content(firstSync))
                .andExpect(status().isOk());

        assertEquals(1, findAnimalByExternalId(auth, "animal-calving-1").path("numeroLactacao").asInt());

        mockMvc.perform(post("/api/sync")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content(secondSync))
                .andExpect(status().isOk());

        assertEquals(1, findAnimalByExternalId(auth, "animal-calving-1").path("numeroLactacao").asInt());
    }

    private JsonNode createProperty(AuthContext auth, String payload) throws Exception {
        return readResponse(mockMvc.perform(post("/api/properties")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString());
    }

    private JsonNode createAnimal(AuthContext auth, String payload) throws Exception {
        return readResponse(mockMvc.perform(post("/api/animals")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString());
    }

    private JsonNode createVisit(AuthContext auth, String payload) throws Exception {
        return readResponse(mockMvc.perform(post("/api/visits")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString());
    }

    private JsonNode createEvent(AuthContext auth, String payload) throws Exception {
        return readResponse(mockMvc.perform(post("/api/events")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString());
    }

    private JsonNode firstLotForProperty(AuthContext auth, long propertyId) throws Exception {
        JsonNode lots = readResponse(mockMvc.perform(get("/api/lots")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .queryParam("idPropriedade", Long.toString(propertyId))
                        .queryParam("status", "ATIVO"))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString());
        return lots.path(0);
    }

    private JsonNode pullSnapshot(AuthContext auth, String since) throws Exception {
        var request = get("/api/sync/pull")
                .header("Authorization", auth.authorization())
                .header("empresaid", auth.tenantId());
        if (since != null) {
            request = request.queryParam("since", since);
        }

        return readResponse(mockMvc.perform(request)
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString());
    }

    private long findAnimalIdByExternalId(AuthContext auth, String idExterno) throws Exception {
        return findAnimalByExternalId(auth, idExterno).path("id").asLong();
    }

    private JsonNode findAnimalByExternalId(AuthContext auth, String idExterno) throws Exception {
        JsonNode animals = readResponse(mockMvc.perform(get("/api/animals")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString());
        return findByExternalId(animals, idExterno);
    }

    private JsonNode findByExternalId(JsonNode items, String idExterno) {
        Iterator<JsonNode> iterator = items.elements();
        while (iterator.hasNext()) {
            JsonNode item = iterator.next();
            if (idExterno.equals(item.path("idExterno").asText())) {
                return item;
            }
        }
        throw new AssertionError("Registro nao encontrado para idExterno=" + idExterno);
    }

    private boolean hasDeletedRecord(JsonNode items, String nomeEntidade, String idExterno) {
        Iterator<JsonNode> iterator = items.elements();
        while (iterator.hasNext()) {
            JsonNode item = iterator.next();
            if (nomeEntidade.equals(item.path("nomeEntidade").asText()) && idExterno.equals(item.path("idExterno").asText())) {
                return true;
            }
        }
        return false;
    }

    private JsonNode createVeterinarian(AuthContext auth, String name, String email, String password) throws Exception {
        return readResponse(mockMvc.perform(post("/api/users")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "%s",
                                  "email": "%s",
                                  "password": "%s"
                                }
                                """.formatted(name, email, password)))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString());
    }

    private AuthContext registerAndAuthenticate(String email, String name, String password) throws Exception {
        authService.register(new RegisterRequest(name, email, password));
        return login(email, password);
    }

    private AuthContext login(String email, String password) throws Exception {
        JsonNode response = readResponse(mockMvc.perform(post("/api/auth/login")
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "%s",
                                  "password": "%s"
                                }
                                """.formatted(email, password)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString());

        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new AssertionError("Usuario nao encontrado"));
        Long tenantId = usuarioEmpresaRepository.findAllByUsuarioIdAndAtivoTrueOrderByEmpresaNomeAsc(usuario.getId())
                .stream()
                .findFirst()
                .orElseThrow(() -> new AssertionError("Empresa nao encontrada"))
                .getEmpresa()
                .getId();

        return new AuthContext("Bearer " + response.path("accessToken").asText(), tenantId);
    }

    private JsonNode readResponse(String content) throws Exception {
        return objectMapper.readTree(content);
    }

    private record AuthContext(String authorization, Long tenantId) {
    }
}
