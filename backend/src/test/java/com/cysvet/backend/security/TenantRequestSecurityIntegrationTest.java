package com.cysvet.backend.security;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.cysvet.backend.dto.auth.RegisterRequest;
import com.cysvet.backend.entity.Empresa;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.entity.UsuarioEmpresa;
import com.cysvet.backend.repository.EmpresaRepository;
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
class TenantRequestSecurityIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private AuthService authService;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private EmpresaRepository empresaRepository;

    @Autowired
    private UsuarioEmpresaRepository usuarioEmpresaRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void authenticatedRequestShouldRequireTenantHeader() throws Exception {
        String token = registerAndExtractToken("tenant.required@example.com");

        mockMvc.perform(get("/api/properties")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isBadRequest());
    }

    @Test
    void authenticatedRequestShouldRejectTenantOutsideMembership() throws Exception {
        String token = registerAndExtractToken("tenant.forbidden@example.com");

        mockMvc.perform(get("/api/properties")
                        .header("Authorization", "Bearer " + token)
                        .header("empresaid", "999999"))
                .andExpect(status().isForbidden());
    }

    @Test
    void authenticatedRequestShouldAcceptAuthorizedTenant() throws Exception {
        String email = "tenant.authorized@example.com";
        String token = registerAndExtractToken(email);
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new AssertionError("Usuario nao encontrado"));

        Empresa empresa = new Empresa();
        empresa.setEmpresaId("tenant-extra-autorizado");
        empresa.setNome("Empresa extra");
        empresa.setEmail("empresa.extra@example.com");
        empresa.setAtivo(true);
        Empresa savedEmpresa = empresaRepository.saveAndFlush(empresa);

        UsuarioEmpresa membership = new UsuarioEmpresa();
        membership.setUsuario(usuario);
        membership.setEmpresa(savedEmpresa);
        membership.setAtivo(true);
        usuarioEmpresaRepository.saveAndFlush(membership);

        mockMvc.perform(get("/api/properties")
                        .header("Authorization", "Bearer " + token)
                        .header("empresaid", savedEmpresa.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }

    @Test
    void adminShouldUpdateActiveCompany() throws Exception {
        String email = "company.update.admin@example.com";
        String token = registerAndExtractToken(email);
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new AssertionError("Usuario nao encontrado"));
        Long tenantId = usuarioEmpresaRepository.findAllByUsuarioIdAndAtivoTrueOrderByEmpresaNomeAsc(usuario.getId())
                .stream()
                .findFirst()
                .orElseThrow(() -> new AssertionError("Empresa nao encontrada"))
                .getEmpresa()
                .getId();

        mockMvc.perform(put("/api/companies/active")
                        .header("Authorization", "Bearer " + token)
                        .header("empresaid", tenantId)
                        .contentType("application/json")
                        .content("""
                                {
                                  "name": "Empresa Atualizada",
                                  "email": "empresa.atualizada@example.com"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(tenantId))
                .andExpect(jsonPath("$.name").value("Empresa Atualizada"))
                .andExpect(jsonPath("$.email").value("empresa.atualizada@example.com"));

        Empresa empresa = empresaRepository.findById(tenantId)
                .orElseThrow(() -> new AssertionError("Empresa nao persistida"));
        assertEquals("Empresa Atualizada", empresa.getNome());
        assertEquals("empresa.atualizada@example.com", empresa.getEmail());
    }

    private String registerAndExtractToken(String email) throws Exception {
        authService.register(new RegisterRequest("Teste Tenant", email, "123456"));

        String responseBody = mockMvc.perform(post("/api/auth/login")
                        .with(csrf())
                        .contentType("application/json")
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

        JsonNode response = objectMapper.readTree(responseBody);
        return response.path("accessToken").asText();
    }
}
