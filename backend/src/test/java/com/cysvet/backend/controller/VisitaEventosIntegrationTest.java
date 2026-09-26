package com.cysvet.backend.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.cysvet.backend.dto.auth.RegisterRequest;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.repository.UsuarioEmpresaRepository;
import com.cysvet.backend.repository.UsuarioRepository;
import com.cysvet.backend.service.AuthService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Visita gerando eventos e resumo reprodutivo recalculado a partir deles,
 * incluindo visitas feitas offline e sincronizadas fora de ordem.
 */
@SpringBootTest
@AutoConfigureMockMvc
class VisitaEventosIntegrationTest {

    // Visitas no futuro ficam depois da base gravada no cadastro do animal (agora).
    private static final LocalDate HOJE = LocalDate.now();

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
    void visitaGeraEventosEAtualizaResumoDoAnimalSemDuplicarNoReenvio() throws Exception {
        AuthContext auth = registerAndAuthenticate("visita.eventos@example.com");
        long propertyId = createProperty(auth, "prop-ve-1");
        createAnimal(auth, propertyId, "animal-ve-1", "VE-01", "pev");
        LocalDate ia = HOJE.plusDays(1);

        String visit = visitPayload("visit-ve-1", "prop-ve-1", HOJE.plusDays(1), """
                {
                  "animalIdExterno": "animal-ve-1",
                  "situacaoReprodutiva": "inseminada st",
                  "decisao": "pg",
                  "dataUltimaIa": "%s",
                  "numeroIaRecebida": 1
                }
                """.formatted(ia));
        long visitId = createVisit(auth, visit).path("id").asLong();

        JsonNode events = listEvents(auth, animalId(auth, "animal-ve-1"));
        assertEquals(2, events.size());
        JsonNode insemination = eventOfType(events, "INSEMINATION");
        assertEquals(ia.toString(), insemination.path("dataEvento").asText());
        assertEquals(ia.plusDays(282).toString(), insemination.path("dataPrevistaParto").asText());
        assertEquals("visit-ve-1", insemination.path("idExternoVisita").asText());
        JsonNode check = eventOfType(events, "REPRODUCTIVE_STATUS_CHECK");
        assertEquals("inseminada st", check.path("detalhes").path("status").asText());
        assertEquals("pg", check.path("observacoes").asText());

        JsonNode animal = animal(auth, "animal-ve-1");
        assertEquals("inseminada st", animal.path("statusReprodutivo").asText());
        assertEquals(ia.toString(), animal.path("dataInseminacao").asText());

        mockMvc.perform(put("/api/visits/" + visitId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content(visit))
                .andExpect(status().isOk());
        assertEquals(2, listEvents(auth, animalId(auth, "animal-ve-1")).size());
    }

    @Test
    void visitasOfflineSincronizadasForaDeOrdemProduzemOMesmoResumo() throws Exception {
        AuthContext auth = registerAndAuthenticate("visita.offline@example.com");
        long propertyId = createProperty(auth, "prop-ve-2");
        createAnimal(auth, propertyId, "animal-ve-2", "VE-02", "pev");
        LocalDate ia = HOJE.plusDays(2);

        String laterVisit = visitPayload("visit-ve-2b", "prop-ve-2", HOJE.plusDays(30), """
                { "animalIdExterno": "animal-ve-2", "situacaoReprodutiva": "prenha", "dataUltimaIa": "%s" }
                """.formatted(ia));
        String earlierVisit = visitPayload("visit-ve-2a", "prop-ve-2", ia, """
                { "animalIdExterno": "animal-ve-2", "situacaoReprodutiva": "inseminada st", "dataUltimaIa": "%s" }
                """.formatted(ia));

        // A visita mais recente chega primeiro ao servidor.
        syncVisit(auth, "mut-ve-2b", laterVisit);
        syncVisit(auth, "mut-ve-2a", earlierVisit);

        JsonNode animal = animal(auth, "animal-ve-2");
        assertEquals("prenha", animal.path("statusReprodutivo").asText());
        assertEquals(ia.toString(), animal.path("dataInseminacao").asText());
        assertEquals(1, countOfType(listEvents(auth, animal.path("id").asLong()), "INSEMINATION"));
    }

    @Test
    void editarOuExcluirVisitaRefazOResumoAPartirDaBase() throws Exception {
        AuthContext auth = registerAndAuthenticate("visita.edicao@example.com");
        long propertyId = createProperty(auth, "prop-ve-3");
        createAnimal(auth, propertyId, "animal-ve-3", "VE-03", "pev");
        String item = """
                { "animalIdExterno": "animal-ve-3", "situacaoReprodutiva": "inseminada st", "dataUltimaIa": "%s" }
                """.formatted(HOJE.plusDays(3));

        long visitId = createVisit(auth, visitPayload("visit-ve-3", "prop-ve-3", HOJE.plusDays(3), item)).path("id").asLong();
        assertEquals("inseminada st", animal(auth, "animal-ve-3").path("statusReprodutivo").asText());

        mockMvc.perform(put("/api/visits/" + visitId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content(visitPayload("visit-ve-3", "prop-ve-3", HOJE.plusDays(3))))
                .andExpect(status().isOk());
        JsonNode animal = animal(auth, "animal-ve-3");
        assertEquals("pev", animal.path("statusReprodutivo").asText());
        assertTrue(animal.path("dataInseminacao").isNull());
        assertEquals(0, listEvents(auth, animal.path("id").asLong()).size());

        long secondVisitId = createVisit(auth, visitPayload("visit-ve-3b", "prop-ve-3", HOJE.plusDays(4), item))
                .path("id").asLong();
        assertEquals("inseminada st", animal(auth, "animal-ve-3").path("statusReprodutivo").asText());

        mockMvc.perform(delete("/api/visits/" + secondVisitId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isNoContent());
        assertEquals("pev", animal(auth, "animal-ve-3").path("statusReprodutivo").asText());
    }

    @Test
    void partoInformadoPorDuasVisitasContaUmaLactacaoESobreviveAExclusaoDeUmaDelas() throws Exception {
        AuthContext auth = registerAndAuthenticate("visita.parto@example.com");
        long propertyId = createProperty(auth, "prop-ve-4");
        createAnimal(auth, propertyId, "animal-ve-4", "VE-04", "prenha");
        LocalDate parto = HOJE.plusDays(10);
        String item = """
                { "animalIdExterno": "animal-ve-4", "situacaoReprodutiva": "pev", "dataUltimoParto": "%s" }
                """.formatted(parto);

        long firstVisitId = createVisit(auth, visitPayload("visit-ve-4a", "prop-ve-4", parto, item)).path("id").asLong();
        createVisit(auth, visitPayload("visit-ve-4b", "prop-ve-4", HOJE.plusDays(20), item));

        JsonNode animal = animal(auth, "animal-ve-4");
        assertEquals(2, animal.path("numeroLactacao").asInt());
        assertEquals(parto.toString(), animal.path("dataUltimoParto").asText());
        assertEquals("pev", animal.path("statusReprodutivo").asText());
        assertEquals(1, countOfType(listEvents(auth, animal.path("id").asLong()), "CALVING"));

        mockMvc.perform(delete("/api/visits/" + firstVisitId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isNoContent());

        animal = animal(auth, "animal-ve-4");
        assertEquals(2, animal.path("numeroLactacao").asInt());
        JsonNode calving = eventOfType(listEvents(auth, animal.path("id").asLong()), "CALVING");
        assertEquals("visit-ve-4b", calving.path("idExternoVisita").asText());
    }

    @Test
    void iaRemovidaDeUmaVisitaPassaParaAOutraSemReprocessarOsDemaisAnimais() throws Exception {
        AuthContext auth = registerAndAuthenticate("visita.fato.unico@example.com");
        long propertyId = createProperty(auth, "prop-ve-7");
        createAnimal(auth, propertyId, "animal-ve-7a", "VE-07A", "pev");
        createAnimal(auth, propertyId, "animal-ve-7b", "VE-07B", "pev");
        LocalDate ia = HOJE.plusDays(2);
        String iaDo7a = """
                { "animalIdExterno": "animal-ve-7a", "situacaoReprodutiva": "inseminada", "dataUltimaIa": "%s" }
                """.formatted(ia);
        String situacaoDo7b = """
                { "animalIdExterno": "animal-ve-7b", "situacaoReprodutiva": "vazia" }
                """;

        long firstVisitId = createVisit(auth, visitPayload("visit-ve-7a", "prop-ve-7", ia, iaDo7a, situacaoDo7b))
                .path("id").asLong();
        createVisit(auth, visitPayload("visit-ve-7b", "prop-ve-7", HOJE.plusDays(5), iaDo7a));
        long animal7a = animal(auth, "animal-ve-7a").path("id").asLong();
        long animal7b = animal(auth, "animal-ve-7b").path("id").asLong();
        assertEquals("visit-ve-7a", eventOfType(listEvents(auth, animal7a), "INSEMINATION").path("idExternoVisita").asText());
        long versaoDo7bAntes = eventOfType(listEvents(auth, animal7b), "REPRODUCTIVE_STATUS_CHECK").path("versao").asLong();

        String semIa = """
                { "animalIdExterno": "animal-ve-7a", "situacaoReprodutiva": "inseminada" }
                """;
        mockMvc.perform(put("/api/visits/" + firstVisitId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content(visitPayload("visit-ve-7a", "prop-ve-7", ia, semIa, situacaoDo7b)))
                .andExpect(status().isOk());

        JsonNode insemination = eventOfType(listEvents(auth, animal7a), "INSEMINATION");
        assertEquals("visit-ve-7b", insemination.path("idExternoVisita").asText());
        assertEquals(ia.toString(), insemination.path("dataEvento").asText());
        assertEquals(1, countOfType(listEvents(auth, animal7a), "INSEMINATION"));
        assertEquals(ia.toString(), animal(auth, "animal-ve-7a").path("dataInseminacao").asText());
        assertEquals(versaoDo7bAntes,
                eventOfType(listEvents(auth, animal7b), "REPRODUCTIVE_STATUS_CHECK").path("versao").asLong());
    }

    @Test
    void correcaoManualPrevaleceSobreEventosAnterioresMasNaoSobreOsPosteriores() throws Exception {
        AuthContext auth = registerAndAuthenticate("visita.correcao@example.com");
        long propertyId = createProperty(auth, "prop-ve-5");
        createAnimal(auth, propertyId, "animal-ve-5", "VE-05", null);

        createVisit(auth, visitPayload("visit-ve-5a", "prop-ve-5", HOJE.minusDays(5), """
                { "animalIdExterno": "animal-ve-5", "situacaoReprodutiva": "aguardando dg" }
                """));
        assertEquals("aguardando dg", animal(auth, "animal-ve-5").path("statusReprodutivo").asText());

        updateAnimalReproductiveStatus(auth, "animal-ve-5", "vazia");
        assertEquals("vazia", animal(auth, "animal-ve-5").path("statusReprodutivo").asText());

        createVisit(auth, visitPayload("visit-ve-5b", "prop-ve-5", HOJE.plusDays(3), """
                { "animalIdExterno": "animal-ve-5", "situacaoReprodutiva": "prenha" }
                """));
        assertEquals("prenha", animal(auth, "animal-ve-5").path("statusReprodutivo").asText());
    }

    @Test
    void excluirEventoDePartoDesfazALactacao() throws Exception {
        AuthContext auth = registerAndAuthenticate("evento.parto@example.com");
        long propertyId = createProperty(auth, "prop-ve-6");
        long animalId = createAnimal(auth, propertyId, "animal-ve-6", "VE-06", "prenha").path("id").asLong();

        JsonNode calving = readResponse(mockMvc.perform(post("/api/events")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "idExterno": "event-ve-6",
                                  "idPropriedade": %d,
                                  "idAnimal": %d,
                                  "tipo": "CALVING",
                                  "dataEvento": "%s"
                                }
                                """.formatted(propertyId, animalId, HOJE.plusDays(1))))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString());
        assertEquals(2, animal(auth, "animal-ve-6").path("numeroLactacao").asInt());

        mockMvc.perform(delete("/api/events/" + calving.path("id").asLong())
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isNoContent());

        JsonNode animal = animal(auth, "animal-ve-6");
        assertEquals(1, animal.path("numeroLactacao").asInt());
        assertEquals("2025-01-10", animal.path("dataUltimoParto").asText());
        assertEquals("prenha", animal.path("statusReprodutivo").asText());
    }

    private long createProperty(AuthContext auth, String idExterno) throws Exception {
        return readResponse(mockMvc.perform(post("/api/properties")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content("""
                                { "idExterno": "%s", "nome": "Fazenda %s", "nomeProprietario": "Produtor" }
                                """.formatted(idExterno, idExterno)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).path("id").asLong();
    }

    private JsonNode createAnimal(AuthContext auth, long propertyId, String idExterno, String codigo, String status)
            throws Exception {
        String statusJson = status == null ? "null" : "\"" + status + "\"";
        return readResponse(mockMvc.perform(post("/api/animals")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "idExterno": "%s",
                                  "idPropriedade": %d,
                                  "codigo": "%s",
                                  "numeroLactacao": 1,
                                  "dataUltimoParto": "2025-01-10",
                                  "statusReprodutivo": %s
                                }
                                """.formatted(idExterno, propertyId, codigo, statusJson)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString());
    }

    private void updateAnimalReproductiveStatus(AuthContext auth, String idExterno, String status) throws Exception {
        ObjectNode payload = (ObjectNode) animal(auth, idExterno).deepCopy();
        payload.put("statusReprodutivo", status);
        mockMvc.perform(put("/api/animals/" + payload.path("id").asLong())
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isOk());
    }

    private String visitPayload(String idExterno, String idExternoPropriedade, LocalDate data, String... items) {
        return """
                {
                  "idExterno": "%s",
                  "idExternoPropriedade": "%s",
                  "dataVisita": "%s",
                  "animais": [%s]
                }
                """.formatted(idExterno, idExternoPropriedade, data, String.join(",", items));
    }

    private JsonNode createVisit(AuthContext auth, String payload) throws Exception {
        return readResponse(mockMvc.perform(post("/api/visits")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString());
    }

    private void syncVisit(AuthContext auth, String chaveMutacao, String visitPayload) throws Exception {
        mockMvc.perform(post("/api/sync")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "items": [
                                    {
                                      "chaveMutacao": "%s",
                                      "operationType": "CREATE",
                                      "entity": "visit",
                                      "payload": %s
                                    }
                                  ]
                                }
                                """.formatted(chaveMutacao, visitPayload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].status").value("SYNCED"));
    }

    private JsonNode listEvents(AuthContext auth, long animalId) throws Exception {
        return readResponse(mockMvc.perform(get("/api/events")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .queryParam("idAnimal", Long.toString(animalId)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
    }

    private JsonNode animal(AuthContext auth, String idExterno) throws Exception {
        JsonNode animals = readResponse(mockMvc.perform(get("/api/animals")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
        for (JsonNode animal : animals) {
            if (idExterno.equals(animal.path("idExterno").asText())) {
                return animal;
            }
        }
        throw new AssertionError("Animal nao encontrado: " + idExterno);
    }

    private long animalId(AuthContext auth, String idExterno) throws Exception {
        return animal(auth, idExterno).path("id").asLong();
    }

    private JsonNode eventOfType(JsonNode events, String tipo) {
        List<JsonNode> matches = new ArrayList<>();
        events.forEach(event -> {
            if (tipo.equals(event.path("tipo").asText())) {
                matches.add(event);
            }
        });
        assertEquals(1, matches.size(), "eventos do tipo " + tipo);
        return matches.get(0);
    }

    private long countOfType(JsonNode events, String tipo) {
        long count = 0;
        for (JsonNode event : events) {
            if (tipo.equals(event.path("tipo").asText())) {
                count++;
            }
        }
        return count;
    }

    private AuthContext registerAndAuthenticate(String email) throws Exception {
        authService.register(new RegisterRequest("Admin " + email, email, "123456"));
        JsonNode response = readResponse(mockMvc.perform(post("/api/auth/login")
                        .contentType(APPLICATION_JSON)
                        .content("""
                                { "email": "%s", "password": "123456" }
                                """.formatted(email)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());

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
