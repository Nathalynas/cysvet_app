package com.cysvet.backend.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.entity.UsuarioEmpresa;
import com.cysvet.backend.repository.UsuarioEmpresaRepository;
import com.cysvet.backend.repository.UsuarioRepository;
import com.cysvet.backend.service.AccessEmailSender;
import com.cysvet.backend.support.TestAccounts;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@Transactional
@AutoConfigureMockMvc
class UserTeamIntegrationTest {

    @Autowired
    private TestAccounts testAccounts;

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private UsuarioEmpresaRepository usuarioEmpresaRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @MockitoBean
    private AccessEmailSender accessEmailSender;

    @Test
    void newMemberReceivesTemporaryPasswordByEmailAndMustChangeIt() throws Exception {
        AuthContext admin = registerAndAuthenticate("invite.admin@example.com", "Admin Convite", "123456");
        when(accessEmailSender.sendTeamInvite(anyString(), anyString(), anyString(), anyString())).thenReturn(true);

        mockMvc.perform(post("/api/users")
                        .header("Authorization", admin.authorization())
                        .header("empresaid", admin.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "Nina Vet",
                                  "email": "nina.vet@example.com"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.emailSent").value(true))
                .andExpect(jsonPath("$.existingAccount").value(false))
                .andExpect(jsonPath("$.user.perfil").value("VETERINARIO"))
                .andExpect(jsonPath("$.user.awaitingFirstAccess").value(true));

        ArgumentCaptor<String> password = ArgumentCaptor.forClass(String.class);
        verify(accessEmailSender).sendTeamInvite(
                eq("nina.vet@example.com"), eq("Nina Vet"), eq("Empresa de Admin Convite"), password.capture());

        String loginResponse = loginResponse("nina.vet@example.com", password.getValue());
        JsonNode session = objectMapper.readTree(loginResponse);
        assertTrue(session.path("user").path("trocarSenha").asBoolean());

        mockMvc.perform(get("/api/users")
                        .header("Authorization", "Bearer " + session.path("accessToken").asText())
                        .header("empresaid", admin.tenantId()))
                .andExpect(status().isForbidden());
    }

    @Test
    void adminShouldResendAccessWithNewTemporaryPassword() throws Exception {
        AuthContext admin = registerAndAuthenticate("resend.admin@example.com", "Admin Reenvio", "123456");
        JsonNode member = createVeterinarian(admin, "Rui Vet", "rui.vet@example.com", "senhaAntiga");
        when(accessEmailSender.sendNewTemporaryPassword(anyString(), anyString(), anyString(), anyString()))
                .thenReturn(true);

        mockMvc.perform(post("/api/users/{userId}/resend-access", member.path("id").asLong())
                        .header("Authorization", admin.authorization())
                        .header("empresaid", admin.tenantId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.emailSent").value(true));

        ArgumentCaptor<String> password = ArgumentCaptor.forClass(String.class);
        verify(accessEmailSender).sendNewTemporaryPassword(
                eq("rui.vet@example.com"), eq("Rui Vet"), anyString(), password.capture());

        mockMvc.perform(post("/api/auth/login")
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {"email": "rui.vet@example.com", "password": "senhaAntiga"}
                                """))
                .andExpect(status().isUnauthorized());
        JsonNode session = objectMapper.readTree(loginResponse("rui.vet@example.com", password.getValue()));
        assertTrue(session.path("user").path("trocarSenha").asBoolean());
    }

    @Test
    void veterinarianShouldNotResendAccess() throws Exception {
        AuthContext admin = registerAndAuthenticate("resend.forbidden@example.com", "Admin Bloqueio", "123456");
        JsonNode other = createVeterinarian(admin, "Lia Vet", "lia.vet@example.com", "123456");
        createVeterinarian(admin, "Teo Vet", "teo.vet@example.com", "123456");
        AuthContext veterinarian = login("teo.vet@example.com", "123456");

        mockMvc.perform(post("/api/users/{userId}/resend-access", other.path("id").asLong())
                        .header("Authorization", veterinarian.authorization())
                        .header("empresaid", veterinarian.tenantId()))
                .andExpect(status().isForbidden());
        verify(accessEmailSender, never())
                .sendNewTemporaryPassword(anyString(), anyString(), anyString(), anyString());
    }

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
    void adminShouldUpdateTeamMember() throws Exception {
        AuthContext admin = registerAndAuthenticate("update.admin@example.com", "Admin Update", "123456");
        JsonNode createdUser = createVeterinarian(
                admin,
                "Felipe Vet",
                "felipe.vet@example.com",
                "123456"
        );
        long userId = createdUser.path("id").asLong();

        mockMvc.perform(put("/api/users/{userId}", userId)
                        .header("Authorization", admin.authorization())
                        .header("empresaid", admin.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "Felipe Silva",
                                  "email": "felipe.silva@example.com"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(userId))
                .andExpect(jsonPath("$.name").value("Felipe Silva"))
                .andExpect(jsonPath("$.email").value("felipe.silva@example.com"))
                .andExpect(jsonPath("$.perfil").value("VETERINARIO"))
                .andExpect(jsonPath("$.status").value("ATIVO"));

        Usuario usuario = usuarioRepository.findById(userId)
                .orElseThrow(() -> new AssertionError("Usuario nao encontrado"));
        assertEquals("Felipe Silva", usuario.getNome());
        assertEquals("felipe.silva@example.com", usuario.getEmail());
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
    void linkingVeterinarianWithoutCompanyShouldKeepTheirPasswordAndName() throws Exception {
        AuthContext firstAdmin = registerAndAuthenticate("orfao.admin1@example.com", "Admin Um", "123456");
        long userId = createVeterinarian(firstAdmin, "Eva Vet", "eva.vet@example.com", "senha-da-eva").path("id").asLong();
        mockMvc.perform(delete("/api/users/{userId}", userId)
                        .header("Authorization", firstAdmin.authorization())
                        .header("empresaid", firstAdmin.tenantId()))
                .andExpect(status().isNoContent());

        // Outro administrador informa o mesmo e-mail: a conta e vinculada sem trocar nome nem senha.
        AuthContext otherAdmin = registerAndAuthenticate("orfao.admin2@example.com", "Admin Dois", "123456");
        JsonNode linked = createVeterinarian(otherAdmin, "Nome Trocado", "eva.vet@example.com", "senha-do-outro-admin");

        assertEquals(userId, linked.path("id").asLong());
        assertEquals("Eva Vet", linked.path("name").asText());
        login("eva.vet@example.com", "senha-da-eva");
        mockMvc.perform(post("/api/auth/login")
                        .contentType(APPLICATION_JSON)
                        .content("""
                                { "email": "eva.vet@example.com", "password": "senha-do-outro-admin" }
                                """))
                .andExpect(status().isUnauthorized());
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

        mockMvc.perform(put("/api/users/{userId}", createdUser.path("id").asLong())
                        .header("Authorization", veterinarian.authorization())
                        .header("empresaid", veterinarian.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "Eva Editada",
                                  "email": "eva.editada@example.com"
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
                                  "email": "%s"
                                }
                                """.formatted(name, email)))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
        JsonNode created = objectMapper.readTree(response);
        // Conta ja existente mantem a senha do dono; so a conta nova passa pelo primeiro acesso.
        if (!created.path("existingAccount").asBoolean()) {
            testAccounts.completeFirstAccess(email, password);
        }
        return created.path("user");
    }

    private AuthContext registerAndAuthenticate(String email, String name, String password) throws Exception {
        testAccounts.createAdmin(name, email, password);
        return login(email, password);
    }

    private String loginResponse(String email, String password) throws Exception {
        return mockMvc.perform(post("/api/auth/login")
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
