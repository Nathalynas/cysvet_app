package com.cysvet.backend.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.cysvet.backend.dto.auth.RegisterRequest;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.entity.UsuarioEmpresa;
import com.cysvet.backend.repository.UsuarioEmpresaRepository;
import com.cysvet.backend.repository.UsuarioRepository;
import com.cysvet.backend.service.AuthService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@Transactional
@AutoConfigureMockMvc
class UserTeamIntegrationTest {

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
    void adminShouldCreateAndListTeamMembers() throws Exception {
        AuthContext admin = registerAndAuthenticate("team.admin@example.com", "Admin Equipe", "123456");

        JsonNode createdUser = createVeterinarian(
                admin,
                "Bia Vet",
                "bia.vet@example.com",
                "123456"
        );

        mockMvc.perform(get("/api/users")
                        .header("Authorization", admin.authorization())
                        .header("empresaid", admin.tenantId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].companyId").value(admin.tenantId()))
                .andExpect(jsonPath("$[0].companyName").isNotEmpty())
                .andExpect(jsonPath("$[1].id").value(createdUser.path("id").asLong()))
                .andExpect(jsonPath("$[1].name").value("Bia Vet"))
                .andExpect(jsonPath("$[1].email").value("bia.vet@example.com"))
                .andExpect(jsonPath("$[1].perfil").value("VETERINARIO"))
                .andExpect(jsonPath("$[1].status").value("ATIVO"));
    }

    @Test
    void adminShouldUpdateMembershipStatus() throws Exception {
        AuthContext admin = registerAndAuthenticate("status.admin@example.com", "Admin Status", "123456");
        JsonNode createdUser = createVeterinarian(
                admin,
                "Carlos Vet",
                "carlos.vet@example.com",
                "123456"
        );
        long userId = createdUser.path("id").asLong();

        mockMvc.perform(patch("/api/users/{userId}/status", userId)
                        .header("Authorization", admin.authorization())
                        .header("empresaid", admin.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "status": "INATIVO"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(userId))
                .andExpect(jsonPath("$.status").value("INATIVO"));

        UsuarioEmpresa membership = usuarioEmpresaRepository.findByUsuarioIdAndEmpresaId(userId, admin.tenantId())
                .orElseThrow(() -> new AssertionError("Vinculo nao encontrado"));
        assertFalse(membership.isAtivo());

        mockMvc.perform(post("/api/auth/login")
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "carlos.vet@example.com",
                                  "password": "123456"
                                }
                                """))
                .andExpect(status().isForbidden());

        mockMvc.perform(patch("/api/users/{userId}/status", userId)
                        .header("Authorization", admin.authorization())
                        .header("empresaid", admin.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "status": "ATIVO"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ATIVO"));

        membership = usuarioEmpresaRepository.findByUsuarioIdAndEmpresaId(userId, admin.tenantId())
                .orElseThrow(() -> new AssertionError("Vinculo nao encontrado"));
        assertTrue(membership.isAtivo());
    }

    @Test
    void adminShouldRemoveMemberFromActiveCompany() throws Exception {
        AuthContext admin = registerAndAuthenticate("remove.admin@example.com", "Admin Remove", "123456");
        JsonNode createdUser = createVeterinarian(
                admin,
                "Dani Vet",
                "dani.vet@example.com",
                "123456"
        );
        long userId = createdUser.path("id").asLong();

        mockMvc.perform(delete("/api/users/{userId}", userId)
                        .header("Authorization", admin.authorization())
                        .header("empresaid", admin.tenantId()))
                .andExpect(status().isNoContent());

        assertTrue(usuarioEmpresaRepository.findByUsuarioIdAndEmpresaId(userId, admin.tenantId()).isEmpty());

        mockMvc.perform(get("/api/users")
                        .header("Authorization", admin.authorization())
                        .header("empresaid", admin.tenantId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1));
    }

    @Test
    void veterinarianShouldNotManageTeam() throws Exception {
        AuthContext admin = registerAndAuthenticate("guard.admin@example.com", "Admin Guard", "123456");
        JsonNode createdUser = createVeterinarian(
                admin,
                "Eva Vet",
                "eva.vet@example.com",
                "123456"
        );

        AuthContext veterinarian = login("eva.vet@example.com", "123456");

        mockMvc.perform(get("/api/users")
                        .header("Authorization", veterinarian.authorization())
                        .header("empresaid", veterinarian.tenantId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2));

        mockMvc.perform(post("/api/users")
                        .header("Authorization", veterinarian.authorization())
                        .header("empresaid", veterinarian.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "Outra Vet",
                                  "email": "outra.vet@example.com",
                                  "password": "123456"
                                }
                                """))
                .andExpect(status().isForbidden());

        mockMvc.perform(patch("/api/users/{userId}/status", createdUser.path("id").asLong())
                        .header("Authorization", veterinarian.authorization())
                        .header("empresaid", veterinarian.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "status": "INATIVO"
                                }
                                """))
                .andExpect(status().isForbidden());
    }

    @Test
    void adminShouldNotChangeOwnMembership() throws Exception {
        AuthContext admin = registerAndAuthenticate("self.admin@example.com", "Admin Self", "123456");
        Usuario usuario = usuarioRepository.findByEmail("self.admin@example.com")
                .orElseThrow(() -> new AssertionError("Usuario admin nao encontrado"));

        mockMvc.perform(patch("/api/users/{userId}/status", usuario.getId())
                        .header("Authorization", admin.authorization())
                        .header("empresaid", admin.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "status": "INATIVO"
                                }
                                """))
                .andExpect(status().isBadRequest());
    }

    private JsonNode createVeterinarian(AuthContext auth, String name, String email, String password) throws Exception {
        String response = mockMvc.perform(post("/api/users")
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
                .getContentAsString();
        return objectMapper.readTree(response);
    }

    private AuthContext registerAndAuthenticate(String email, String name, String password) throws Exception {
        authService.register(new RegisterRequest(name, email, password));
        return login(email, password);
    }

    private AuthContext login(String email, String password) throws Exception {
        String responseBody = mockMvc.perform(post("/api/auth/login")
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
        assertEquals(tenantId, response.path("empresaAtivaId").asLong());
        return new AuthContext("Bearer " + response.path("accessToken").asText(), tenantId);
    }

    private record AuthContext(String authorization, Long tenantId) {
    }
}
