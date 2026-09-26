package com.cysvet.backend.security;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.http.MediaType.APPLICATION_JSON;
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
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * Um usuario da empresa B nao pode ler, alterar, excluir nem referenciar
 * registros da empresa A informando o id numerico deles.
 */
@SpringBootTest
@AutoConfigureMockMvc
class TenantIsolationByIdIntegrationTest {

    private static int sequence = 0;

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

    private AuthContext companyA;
    private AuthContext companyB;
    private long propertyA;
    private long lotA;
    private long animalA;
    private long visitA;
    private long eventA;

    @BeforeEach
    void createCompanyAData() throws Exception {
        sequence++;
        companyA = registerAndAuthenticate("isolamento.a" + sequence + "@example.com");
        companyB = registerAndAuthenticate("isolamento.b" + sequence + "@example.com");

        propertyA = create(companyA, "/api/properties", """
                { "idExterno": "prop-iso-%d", "nome": "Fazenda A", "nomeProprietario": "Dono A" }
                """.formatted(sequence));
        lotA = create(companyA, "/api/lots", """
                { "idExterno": "lot-iso-%d", "idPropriedade": %d, "nome": "Lote A" }
                """.formatted(sequence, propertyA));
        animalA = create(companyA, "/api/animals", """
                { "idExterno": "animal-iso-%d", "idPropriedade": %d, "codigo": "A-1", "numeroLactacao": 1, "statusReprodutivo": "prenha" }
                """.formatted(sequence, propertyA));
        visitA = create(companyA, "/api/visits", """
                { "idExterno": "visit-iso-%d", "idPropriedade": %d, "dataVisita": "2026-09-20", "animais": [] }
                """.formatted(sequence, propertyA));
        eventA = create(companyA, "/api/events", """
                { "idExterno": "event-iso-%d", "idPropriedade": %d, "idAnimal": %d, "tipo": "HEALTH_TREATMENT", "dataEvento": "2026-09-20" }
                """.formatted(sequence, propertyA, animalA));
    }

    @Test
    void companyBCannotReadCompanyARecordsById() throws Exception {
        expectNotFound(get("/api/properties/" + propertyA));
        expectNotFound(get("/api/visits/" + visitA));
        expectNotFound(get("/api/animals/" + animalA + "/history"));
        expectNotFound(get("/api/reports/property/" + propertyA + "/pdf"));
        expectNotFound(get("/api/reports/property/" + propertyA + "/xlsx"));
        expectNotFound(get("/api/reports/visit/" + visitA + "/pdf"));
        expectNotFound(get("/api/reports/visit/" + visitA + "/xlsx"));
    }

    @Test
    void companyBCannotChangeCompanyARecordsById() throws Exception {
        expectNotFound(put("/api/properties/" + propertyA).contentType(APPLICATION_JSON).content("""
                { "idExterno": "prop-iso-%d", "nome": "Alterada por B", "nomeProprietario": "B" }
                """.formatted(sequence)));
        expectNotFound(patch("/api/properties/" + propertyA + "/status").contentType(APPLICATION_JSON)
                .content("{ \"status\": \"INATIVO\" }"));
        expectNotFound(put("/api/lots/" + lotA).contentType(APPLICATION_JSON).content("""
                { "idExterno": "lot-iso-%d", "idExternoPropriedade": "prop-iso-%d", "nome": "Alterado por B" }
                """.formatted(sequence, sequence)));
        expectNotFound(patch("/api/animals/" + animalA + "/status").contentType(APPLICATION_JSON)
                .content("{ \"status\": \"OBITO\" }"));
        expectNotFound(put("/api/visits/" + visitA).contentType(APPLICATION_JSON).content("""
                { "idExterno": "visit-iso-%d", "idExternoPropriedade": "prop-iso-%d", "dataVisita": "2026-09-21" }
                """.formatted(sequence, sequence)));
        expectNotFound(delete("/api/events/" + eventA));
        expectNotFound(delete("/api/visits/" + visitA));
        expectNotFound(delete("/api/animals/" + animalA));
        expectNotFound(delete("/api/lots/" + lotA));
        expectNotFound(delete("/api/properties/" + propertyA));

        JsonNode property = read(companyA, get("/api/properties/" + propertyA));
        assertEquals("Fazenda A", property.path("nome").asText());
        assertEquals("ATIVO", property.path("status").asText());
        JsonNode animal = read(companyA, get("/api/animals/" + animalA + "/history")).path("animal");
        assertEquals("ATIVO", animal.path("status").asText());
        assertEquals(1, read(companyA, get("/api/events").queryParam("idAnimal", Long.toString(animalA))).size());
    }

    @Test
    void companyBCannotReferenceCompanyARecordsById() throws Exception {
        expectNotFound(post("/api/animals").contentType(APPLICATION_JSON).content("""
                { "idExterno": "animal-b-%d", "idPropriedade": %d, "codigo": "B-1", "numeroLactacao": 0 }
                """.formatted(sequence, propertyA)));
        expectNotFound(post("/api/lots").contentType(APPLICATION_JSON).content("""
                { "idExterno": "lot-b-%d", "idPropriedade": %d, "nome": "Lote B" }
                """.formatted(sequence, propertyA)));
        expectNotFound(post("/api/visits").contentType(APPLICATION_JSON).content("""
                { "idExterno": "visit-b-%d", "idPropriedade": %d, "dataVisita": "2026-09-21" }
                """.formatted(sequence, propertyA)));
        expectNotFound(post("/api/events").contentType(APPLICATION_JSON).content("""
                { "idExterno": "event-b-%d", "idPropriedade": %d, "idAnimal": %d, "tipo": "DEATH", "dataEvento": "2026-09-21" }
                """.formatted(sequence, propertyA, animalA)));
        expectNotFound(post("/api/indicators/snapshot").queryParam("idPropriedade", Long.toString(propertyA)));

        mockMvc.perform(authenticated(companyB, post("/api/sync").contentType(APPLICATION_JSON).content("""
                        {
                          "items": [
                            {
                              "chaveMutacao": "mut-iso-%d",
                              "operationType": "CREATE",
                              "entity": "animal",
                              "payload": { "idExterno": "animal-sync-b-%d", "idPropriedade": %d, "codigo": "B-2", "numeroLactacao": 0 }
                            }
                          ]
                        }
                        """.formatted(sequence, sequence, propertyA))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].status").value("REJECTED"));
    }

    private void expectNotFound(MockHttpServletRequestBuilder request) throws Exception {
        mockMvc.perform(authenticated(companyB, request)).andExpect(status().isNotFound());
    }

    private long create(AuthContext auth, String path, String payload) throws Exception {
        return readResponse(mockMvc.perform(authenticated(auth, post(path).contentType(APPLICATION_JSON).content(payload)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).path("id").asLong();
    }

    private JsonNode read(AuthContext auth, MockHttpServletRequestBuilder request) throws Exception {
        return readResponse(mockMvc.perform(authenticated(auth, request))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
    }

    private MockHttpServletRequestBuilder authenticated(AuthContext auth, MockHttpServletRequestBuilder request) {
        return request.header("Authorization", auth.authorization()).header("empresaid", auth.tenantId());
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
