package com.cysvet.backend.controller;

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

        JsonNode created = createAnimal(auth, """
                {
                  "idExterno": "animal-ext-1",
                  "idPropriedade": %d,
                  "codigo": "A-001",
                  "categoria": "Bovino",
                  "sexo": "Femea",
                  "numeroLactacao": 2,
                  "historicoReprodutivo": "Sem intercorrencias",
                  "status": "ATIVO"
                }
                """.formatted(propertyId));
        long animalId = created.path("id").asLong();

        mockMvc.perform(get("/api/animals")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .queryParam("idPropriedade", Long.toString(propertyId))
                        .queryParam("search", "femea")
                        .queryParam("status", "ATIVO"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(animalId))
                .andExpect(jsonPath("$[0].sexo").value("Femea"))
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
    void syncPullShouldReturnSoftDeletedPropertyAndAnimalWithoutDeletionMarkers() throws Exception {
        AuthContext auth = registerAndAuthenticate("sync.status@example.com");
        JsonNode property = createProperty(auth, """
                {
                  "idExterno": "prop-sync-1",
                  "nome": "Fazenda Sync",
                  "nomeProprietario": "Carlos"
                }
                """);
        long propertyId = property.path("id").asLong();

        JsonNode animal = createAnimal(auth, """
                {
                  "idExterno": "animal-sync-1",
                  "idPropriedade": %d,
                  "codigo": "SYNC-01",
                  "categoria": "Bovino",
                  "sexo": "Macho",
                  "numeroLactacao": 0
                }
                """.formatted(propertyId));
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

        mockMvc.perform(get("/api/sync/pull")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .queryParam("since", since))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.properties[0].id").value(propertyId))
                .andExpect(jsonPath("$.properties[0].status").value("INATIVO"))
                .andExpect(jsonPath("$.animals[0].id").value(animalId))
                .andExpect(jsonPath("$.animals[0].status").value("INATIVO"))
                .andExpect(jsonPath("$.deletedRecords").isEmpty());
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
