package com.cysvet.backend.security;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.cysvet.backend.dto.auth.AuthResponse;
import com.cysvet.backend.entity.Empresa;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.repository.UsuarioRepository;
import com.cysvet.backend.support.TestAccounts;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@Transactional
@AutoConfigureMockMvc
class AccountPasswordIntegrationTest {

    private static final String PASSWORD = "123456";
    private static final String NEW_PASSWORD = "novaSenha1";

    @Autowired
    private TestAccounts testAccounts;

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Test
    void changesRequiredPasswordAndUnblocksDataRoutes() throws Exception {
        String email = "account.change@example.com";
        String accessToken = createUserRequiringPasswordChange(email);
        Empresa empresa = testAccounts.companyOf(email);

        mockMvc.perform(get("/api/properties")
                        .header("Authorization", "Bearer " + accessToken)
                        .header("empresaid", empresa.getId()))
                .andExpect(status().isForbidden());

        mockMvc.perform(changePassword(accessToken, NEW_PASSWORD))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/properties")
                        .header("Authorization", "Bearer " + accessToken)
                        .header("empresaid", empresa.getId()))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/auth/login")
                        .contentType("application/json")
                        .content("{\"email\": \"" + email + "\", \"password\": \"" + NEW_PASSWORD + "\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.trocarSenha").value(false));
    }

    @Test
    void rejectsShortPassword() throws Exception {
        String accessToken = createUserRequiringPasswordChange("account.short@example.com");

        mockMvc.perform(changePassword(accessToken, "12345"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void rejectsWhenChangeNotRequired() throws Exception {
        AuthResponse auth = testAccounts.createAdmin("Normal", "account.normal@example.com", PASSWORD);

        mockMvc.perform(changePassword(auth.accessToken(), NEW_PASSWORD))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Troca de senha nao solicitada"));
    }

    @Test
    void requiresAuthentication() throws Exception {
        mockMvc.perform(post("/api/account/password")
                        .contentType("application/json")
                        .content("{\"newPassword\": \"" + NEW_PASSWORD + "\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void publicRegisterEndpointIsGone() throws Exception {
        long before = usuarioRepository.count();

        int httpStatus = mockMvc.perform(post("/api/auth/register")
                        .contentType("application/json")
                        .content("{\"name\": \"Intruso\", \"email\": \"intruso@example.com\", \"password\": \"123456\"}"))
                .andReturn().getResponse().getStatus();

        org.junit.jupiter.api.Assertions.assertTrue(
                httpStatus == 404 || httpStatus == 405 || httpStatus == 401 || httpStatus == 403,
                "register must not succeed, got " + httpStatus);
        assertEquals(before, usuarioRepository.count());
        assertEquals(true, usuarioRepository.findByEmail("intruso@example.com").isEmpty());
    }

    private String createUserRequiringPasswordChange(String email) throws Exception {
        testAccounts.createAdmin("Troca", email, PASSWORD);
        Usuario usuario = usuarioRepository.findByEmail(email).orElseThrow();
        usuario.setTrocarSenha(true);
        usuarioRepository.saveAndFlush(usuario);
        String body = mockMvc.perform(post("/api/auth/login")
                        .contentType("application/json")
                        .content("{\"email\": \"" + email + "\", \"password\": \"" + PASSWORD + "\"}"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return com.jayway.jsonpath.JsonPath.read(body, "$.accessToken");
    }

    private MockHttpServletRequestBuilder changePassword(String accessToken, String newPassword) {
        return post("/api/account/password")
                .header("Authorization", "Bearer " + accessToken)
                .contentType("application/json")
                .content("{\"newPassword\": \"" + newPassword + "\"}");
    }
}
