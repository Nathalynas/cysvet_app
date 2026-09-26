package com.cysvet.backend.security;

import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
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
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Sessao expirada ou ausente responde 401 (o app manda para o login ou renova o
 * token), falta de permissao responde 403 e erros de requisicao nao viram 500.
 */
@SpringBootTest
@AutoConfigureMockMvc
class AuthenticationErrorsIntegrationTest {

    private static int sequence = 0;

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private AuthService authService;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private UsuarioEmpresaRepository usuarioEmpresaRepository;

    @Autowired
    private ObjectMapper objectMapper;

    private String email;
    private String accessToken;
    private String refreshToken;
    private Long tenantId;
    private String expiredToken;

    @BeforeEach
    void authenticate() throws Exception {
        sequence++;
        email = "sessao" + sequence + "@example.com";
        authService.register(new RegisterRequest("Sessao", email, "123456"));
        JsonNode login = login(email, "123456");
        accessToken = login.path("accessToken").asText();
        refreshToken = login.path("refreshToken").asText();

        Usuario usuario = usuarioRepository.findByEmail(email).orElseThrow();
        tenantId = usuarioEmpresaRepository.findAllByUsuarioIdAndAtivoTrueOrderByEmpresaNomeAsc(usuario.getId())
                .get(0).getEmpresa().getId();
        expiredToken = jwtService.generateToken(
                usuario,
                List.of(new SimpleGrantedAuthority("ROLE_ADMIN")),
                Instant.now().minus(Duration.ofHours(2)));
    }

    @Test
    void requestWithoutTokenShouldReturn401() throws Exception {
        mockMvc.perform(get("/api/properties").header("empresaid", tenantId))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401));
    }

    @Test
    void expiredOrInvalidTokenShouldReturn401() throws Exception {
        mockMvc.perform(get("/api/properties")
                        .header("Authorization", "Bearer " + expiredToken)
                        .header("empresaid", tenantId))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Sessao expirada ou token invalido"));
        mockMvc.perform(get("/api/properties")
                        .header("Authorization", "Bearer token-que-nao-e-jwt")
                        .header("empresaid", tenantId))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void refreshShouldWorkEvenWhenClientSendsTheExpiredAccessToken() throws Exception {
        mockMvc.perform(post("/api/auth/refresh")
                        .header("Authorization", "Bearer " + expiredToken)
                        .contentType(APPLICATION_JSON)
                        .content("{ \"refreshToken\": \"%s\" }".formatted(refreshToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty());
    }

    @Test
    void wrongPasswordShouldReturn401() throws Exception {
        mockMvc.perform(post("/api/auth/login")
                        .contentType(APPLICATION_JSON)
                        .content("{ \"email\": \"%s\", \"password\": \"errada\" }".formatted(email)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("E-mail ou senha invalidos"));
    }

    @Test
    void requestErrorsShouldNotBecome500() throws Exception {
        mockMvc.perform(authenticated(get("/api/rota-que-nao-existe")))
                .andExpect(status().isNotFound());
        mockMvc.perform(authenticated(get("/api/visits/abc")))
                .andExpect(status().isBadRequest());
        mockMvc.perform(authenticated(multipart("/api/animals/import/xlsx/preview")
                        .file("file", new byte[] {1})
                        .param("idPropriedade", "1")))
                .andExpect(status().isBadRequest());
        mockMvc.perform(authenticated(post("/api/properties/1")))
                .andExpect(status().isMethodNotAllowed());
    }

    private org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder authenticated(
            org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder request) {
        return request.header("Authorization", "Bearer " + accessToken).header("empresaid", tenantId);
    }

    private JsonNode login(String email, String password) throws Exception {
        return objectMapper.readTree(mockMvc.perform(post("/api/auth/login")
                        .contentType(APPLICATION_JSON)
                        .content("{ \"email\": \"%s\", \"password\": \"%s\" }".formatted(email, password)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
    }
}
