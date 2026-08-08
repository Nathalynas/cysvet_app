package com.cysvet.backend.controller;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
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
import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
class PropertyAnimalIntegrationTest {

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
    void propertyEndpointsShouldPersistContatoStatusAndSupportSoftDelete() throws Exception {
        AuthContext auth = registerAndAuthenticate("property.status@example.com");

        JsonNode created = createProperty(auth, """
                {
                  "idExterno": "prop-ext-1",
                  "nome": "Fazenda Aurora",
                  "nomeProprietario": "Joao",
                  "contato": "51999999999",
                  "cidade": "Cascavel",
                  "estado": "PR",
                  "observacoes": "Teste",
                  "status": "ATIVO"
                }
                """);
        long propertyId = created.path("id").asLong();

        mockMvc.perform(get("/api/properties")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .queryParam("search", "519999")
                        .queryParam("status", "ATIVO"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(propertyId))
                .andExpect(jsonPath("$[0].contato").value("51999999999"))
                .andExpect(jsonPath("$[0].status").value("ATIVO"));

        mockMvc.perform(get("/api/properties/{id}", propertyId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(propertyId))
                .andExpect(jsonPath("$.contato").value("51999999999"))
                .andExpect(jsonPath("$.status").value("ATIVO"));

        mockMvc.perform(get("/api/lots")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .queryParam("idPropriedade", Long.toString(propertyId))
                        .queryParam("status", "ATIVO"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].idPropriedade").value(propertyId))
                .andExpect(jsonPath("$[0].nome").value("Lote 1"))
                .andExpect(jsonPath("$[0].status").value("ATIVO"));

        mockMvc.perform(patch("/api/properties/{id}/status", propertyId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "status": "ARQUIVADO"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("INATIVO"));

        mockMvc.perform(put("/api/properties/{id}", propertyId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "idExterno": "prop-ext-1",
                                  "nome": "Fazenda Aurora",
                                  "nomeProprietario": "Joao",
                                  "contato": "51999999999",
                                  "cidade": "Cascavel",
                                  "estado": "PR",
                                  "observacoes": "Reativada"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("INATIVO"));

        mockMvc.perform(patch("/api/properties/{id}/status", propertyId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "status": "ATIVO"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ATIVO"));

        mockMvc.perform(delete("/api/properties/{id}", propertyId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/properties")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .queryParam("status", "INATIVO"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(propertyId))
                .andExpect(jsonPath("$[0].status").value("INATIVO"));
    }

    @Test
    void animalEndpointsShouldPersistSexoStatusAndSupportSoftDelete() throws Exception {
        AuthContext auth = registerAndAuthenticate("animal.status@example.com");
        JsonNode property = createProperty(auth, """
                {
                  "idExterno": "prop-ext-2",
                  "nome": "Fazenda B",
                  "nomeProprietario": "Maria",
                  "status": "ATIVO"
                }
                """);

        long propertyId = property.path("id").asLong();
        JsonNode lote = firstLotForProperty(auth, propertyId);
        long loteId = lote.path("id").asLong();

        createLot(auth, """
                {
                  "idExterno": "lote-ext-1",
                  "idPropriedade": %d,
                  "nome": "Lote Lactacao",
                  "descricao": "Animais em lactacao",
                  "status": "ATIVO"
                }
                """.formatted(propertyId));

        JsonNode created = createAnimal(auth, """
                {
                  "idExterno": "animal-ext-1",
                  "idPropriedade": %d,
                  "idLote": %d,
                  "codigo": "A-001",
                  "categoria": "Bovino",
                  "sexo": "Femea",
                  "numeroLactacao": 2,
                  "dataInseminacao": "2026-05-01",
                  "historicoReprodutivo": "Sem intercorrencias",
                  "statusReprodutivo": "pregnant",
                  "status": "ATIVO"
                }
                """.formatted(propertyId, loteId));
        long animalId = created.path("id").asLong();

        mockMvc.perform(get("/api/animals")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .queryParam("idPropriedade", Long.toString(propertyId))
                        .queryParam("idLote", Long.toString(loteId))
                        .queryParam("search", "femea")
                        .queryParam("status", "ATIVO"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(animalId))
                .andExpect(jsonPath("$[0].idLote").value(loteId))
                .andExpect(jsonPath("$[0].nomeLote").value("Lote 1"))
                .andExpect(jsonPath("$[0].sexo").value("Femea"))
                .andExpect(jsonPath("$[0].dataInseminacao").value("2026-05-01"))
                .andExpect(jsonPath("$[0].statusReprodutivo").value("prenha"))
                .andExpect(jsonPath("$[0].status").value("ATIVO"));

        mockMvc.perform(patch("/api/animals/{id}/status", animalId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "status": "VENDIDO"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("VENDIDO"));

        mockMvc.perform(delete("/api/animals/{id}", animalId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/animals")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .queryParam("status", "INATIVO"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(animalId))
                .andExpect(jsonPath("$[0].status").value("INATIVO"));
    }

    @Test
    void lotEndpointsShouldPersistPropertyRelationAndSupportSoftDelete() throws Exception {
        AuthContext auth = registerAndAuthenticate("lot.status@example.com");
        JsonNode property = createProperty(auth, """
                {
                  "idExterno": "prop-lot-1",
                  "nome": "Fazenda Lote",
                  "nomeProprietario": "Rafael",
                  "status": "ATIVO"
                }
                """);

        long propertyId = property.path("id").asLong();

        mockMvc.perform(get("/api/lots")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .queryParam("idPropriedade", Long.toString(propertyId))
                        .queryParam("status", "ATIVO"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].nome").value("Lote 1"));

        JsonNode created = createLot(auth, """
                {
                  "idExterno": "lote-ext-2",
                  "idPropriedade": %d,
                  "nome": "Lote Secas",
                  "descricao": "Animais secando",
                  "status": "ATIVO"
                }
                """.formatted(propertyId));
        long loteId = created.path("id").asLong();

        mockMvc.perform(get("/api/lots")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .queryParam("idPropriedade", Long.toString(propertyId))
                        .queryParam("search", "secas")
                        .queryParam("status", "ATIVO"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(loteId))
                .andExpect(jsonPath("$[0].idPropriedade").value(propertyId))
                .andExpect(jsonPath("$[0].descricao").value("Animais secando"))
                .andExpect(jsonPath("$[0].status").value("ATIVO"));

        mockMvc.perform(patch("/api/lots/{id}/status", loteId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "status": "ARQUIVADO"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("INATIVO"));

        mockMvc.perform(put("/api/lots/{id}", loteId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "idExterno": "lote-ext-2",
                                  "idPropriedade": %d,
                                  "nome": "Lote Secas",
                                  "descricao": "Lote atualizado"
                                }
                                """.formatted(propertyId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.descricao").value("Lote atualizado"))
                .andExpect(jsonPath("$.status").value("INATIVO"));

        mockMvc.perform(patch("/api/lots/{id}/status", loteId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "status": "ATIVO"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ATIVO"));

        mockMvc.perform(delete("/api/lots/{id}", loteId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/lots")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .queryParam("status", "INATIVO"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(loteId))
                .andExpect(jsonPath("$[0].status").value("INATIVO"));
    }

    @Test
    void syncPullShouldReturnSoftDeletedPropertyLotAndAnimalWithoutDeletionMarkers() throws Exception {
        AuthContext auth = registerAndAuthenticate("sync.status@example.com");
        JsonNode property = createProperty(auth, """
                {
                  "idExterno": "prop-sync-1",
                  "nome": "Fazenda Sync",
                  "nomeProprietario": "Carlos"
                }
                """);
        long propertyId = property.path("id").asLong();
        JsonNode lote = firstLotForProperty(auth, propertyId);
        long loteId = lote.path("id").asLong();

        JsonNode animal = createAnimal(auth, """
                {
                  "idExterno": "animal-sync-1",
                  "idPropriedade": %d,
                  "idLote": %d,
                  "codigo": "SYNC-01",
                  "categoria": "Bovino",
                  "sexo": "Macho",
                  "numeroLactacao": 0
                }
                """.formatted(propertyId, loteId));
        long animalId = animal.path("id").asLong();

        String since = Instant.now().minusSeconds(5).toString();

        mockMvc.perform(delete("/api/properties/{id}", propertyId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isNoContent());

        mockMvc.perform(delete("/api/animals/{id}", animalId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isNoContent());

        mockMvc.perform(delete("/api/lots/{id}", loteId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/sync/pull")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .queryParam("since", since))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.properties[0].id").value(propertyId))
                .andExpect(jsonPath("$.properties[0].status").value("INATIVO"))
                .andExpect(jsonPath("$.lots[0].id").value(loteId))
                .andExpect(jsonPath("$.lots[0].status").value("INATIVO"))
                .andExpect(jsonPath("$.animals[0].id").value(animalId))
                .andExpect(jsonPath("$.animals[0].idLote").value(loteId))
                .andExpect(jsonPath("$.animals[0].status").value("INATIVO"))
                .andExpect(jsonPath("$.deletedRecords").isEmpty());
    }

    @Test
    void visitEndpointsShouldPersistAnimalCollection() throws Exception {
        AuthContext auth = registerAndAuthenticate("visit.animals@example.com");
        JsonNode property = createProperty(auth, """
                {
                  "idExterno": "prop-visit-1",
                  "nome": "Fazenda Visita",
                  "nomeProprietario": "Diego"
                }
                """);

        long propertyId = property.path("id").asLong();

        JsonNode animal = createAnimal(auth, """
                {
                  "idExterno": "animal-visit-1",
                  "idPropriedade": %d,
                  "codigo": "46344",
                  "categoria": "VACA",
                  "sexo": "Femea",
                  "numeroLactacao": 3,
                  "dataInseminacao": "2025-11-10",
                  "status": "ATIVO"
                }
                """.formatted(propertyId));

        long animalId = animal.path("id").asLong();

        MvcResult createdVisit = mockMvc.perform(post("/api/visits")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "idExterno": "visit-001",
                                  "idPropriedade": %d,
                                  "dataVisita": "2026-05-18",
                                  "observacoes": "Coleta por animal",
                                  "animais": [
                                    {
                                      "animalId": %d,
                                      "animalIdExterno": "animal-visit-1",
                                      "animalCodigo": "46344",
                                      "animalCategoria": "VACA",
                                      "idadeMeses": 83,
                                      "dataNascimento": "2020-01-15",
                                      "situacaoProdutiva": "lactante",
                                      "situacaoReprodutiva": "inseminada",
                                      "decisao": "ST cef+pg",
                                      "dataPrimeiroParto": "2022-03-01",
                                      "dataUltimoParto": "2026-03-03",
                                      "dataPartoAnterior": "2025-02-02",
                                      "numeroPartos": 3,
                                      "dataPrimeiraIa": "2025-09-10",
                                      "dataSegundaIa": "2025-10-01",
                                      "numeroIaRecebida": 1,
                                      "dataSecagemEfetiva": "2026-04-20",
                                      "entradaPreParto": "2026-05-29",
                                      "controleLeiteiro": 29.5,
                                      "diasPrenhez": 22,
                                      "diagnostico": "pg",
                                      "del": 76,
                                      "idadePrimeiroPartoMeses": 25.5,
                                      "idadePrimeiraIa": 16.4,
                                      "mesParto": "Marco",
                                      "anoUltimoParto": 2026,
                                      "iepAtual": 12.3,
                                      "classificacaoPartos": "Multipara",
                                      "vacaApta": true,
                                      "intervalo1e2Ia": 21,
                                      "mediaIntervaloIa": 21.0,
                                      "previsaoRetornoCio": "2026-06-10",
                                      "delPrimeiraIa": 62,
                                      "periodoServico": 118,
                                      "diasParaSecar": 168,
                                      "previsaoSecagem": "2026-10-31",
                                      "mesSecagem": "Outubro",
                                      "diferencaSecagem": 12,
                                      "periodoLactacao": 305,
                                      "dataPreParto": "2026-11-20",
                                      "mesPreParto": "Novembro",
                                      "duracaoPreParto": 30,
                                      "previsaoParto": "2026-12-20",
                                      "mesPrevistoParto": "Dezembro",
                                      "iepProjetado": 13.1,
                                      "controleLeiteiroComDesconto": 27.4
                                    }
                                  ]
                                }
                                """.formatted(propertyId, animalId)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.idUsuario").isNumber())
                .andExpect(jsonPath("$.nomeUsuario").value("Teste Integracao"))
                .andExpect(jsonPath("$.animais[0].animalId").value(animalId))
                .andExpect(jsonPath("$.animais[0].animalCodigo").value("46344"))
                .andExpect(jsonPath("$.animais[0].dataNascimento").value("2020-01-15"))
                .andExpect(jsonPath("$.animais[0].dataPrimeiraIa").value("2025-09-10"))
                .andExpect(jsonPath("$.animais[0].situacaoReprodutiva").value("inseminada"))
                .andExpect(jsonPath("$.animais[0].numeroIaRecebida").value(1))
                .andReturn();

        long visitId = objectMapper.readTree(createdVisit.getResponse().getContentAsString()).path("id").asLong();

        mockMvc.perform(get("/api/visits")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .queryParam("idPropriedade", Long.toString(propertyId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].idExterno").value("visit-001"))
                .andExpect(jsonPath("$[0].nomeUsuario").value("Teste Integracao"))
                .andExpect(jsonPath("$[0].animais[0].animalCodigo").value("46344"))
                .andExpect(jsonPath("$[0].animais[0].numeroIaRecebida").value(1))
                .andExpect(jsonPath("$[0].animais[0].decisao").value("ST cef+pg"));

        mockMvc.perform(get("/api/visits/{id}", visitId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(visitId))
                .andExpect(jsonPath("$.nomeUsuario").value("Teste Integracao"))
                .andExpect(jsonPath("$.animais[0].controleLeiteiro").value(29.5))
                .andExpect(jsonPath("$.animais[0].controleLeiteiroComDesconto").value(27.4))
                .andExpect(jsonPath("$.animais[0].previsaoParto").value("2026-12-20"));

        mockMvc.perform(post("/api/events")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "idExterno": "evt-visit-1",
                                  "idPropriedade": %d,
                                  "idAnimal": %d,
                                  "tipo": "PREGNANCY_DIAGNOSIS",
                                  "dataEvento": "2026-05-20",
                                  "prenhezConfirmada": true,
                                  "observacoes": "Confirmada por US"
                                }
                                """.formatted(propertyId, animalId)))
                .andExpect(status().isCreated());

        mockMvc.perform(get("/api/animals/{id}/history", animalId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.animal.id").value(animalId))
                .andExpect(jsonPath("$.animal.statusReprodutivo").value("prenha"))
                .andExpect(jsonPath("$.eventos[0].tipo").value("PREGNANCY_DIAGNOSIS"))
                .andExpect(jsonPath("$.visitas[0].id").value(visitId))
                .andExpect(jsonPath("$.visitas[0].animais[0].animalId").value(animalId))
                .andExpect(jsonPath("$.visitas[0].animais[0].previsaoSecagem").value("2026-10-31"));

        MvcResult report = mockMvc.perform(get("/api/reports/visit/{visitId}/pdf", visitId)
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isOk())
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.content().contentType(MediaType.APPLICATION_PDF))
                .andReturn();

        assertTrue(report.getResponse().getContentAsByteArray().length > 1000);
    }

    private JsonNode createProperty(AuthContext auth, String payload) throws Exception {
        String response = mockMvc.perform(post("/api/properties")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
        return objectMapper.readTree(response);
    }

    private JsonNode createAnimal(AuthContext auth, String payload) throws Exception {
        String response = mockMvc.perform(post("/api/animals")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
        return objectMapper.readTree(response);
    }

    private JsonNode createLot(AuthContext auth, String payload) throws Exception {
        String response = mockMvc.perform(post("/api/lots")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
        return objectMapper.readTree(response);
    }

    private JsonNode firstLotForProperty(AuthContext auth, long propertyId) throws Exception {
        String response = mockMvc.perform(get("/api/lots")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .queryParam("idPropriedade", Long.toString(propertyId))
                        .queryParam("status", "ATIVO"))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        return objectMapper.readTree(response).path(0);
    }

    private AuthContext registerAndAuthenticate(String email) throws Exception {
        authService.register(new RegisterRequest("Teste Integracao", email, "123456"));

        String responseBody = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "%s",
                                  "password": "123456"
                                }
                                """.formatted(email)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new AssertionError("Usuario nao encontrado"));
        Long tenantId = usuarioEmpresaRepository.findAllByUsuarioIdAndAtivoTrueOrderByEmpresaNomeAsc(usuario.getId())
                .stream()
                .findFirst()
                .orElseThrow(() -> new AssertionError("Empresa nao encontrada"))
                .getEmpresa()
                .getId();

        JsonNode response = objectMapper.readTree(responseBody);
        return new AuthContext("Bearer " + response.path("accessToken").asText(), tenantId);
    }

    private record AuthContext(String authorization, Long tenantId) {
    }
}
