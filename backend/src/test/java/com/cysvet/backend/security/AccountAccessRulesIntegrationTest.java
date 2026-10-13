package com.cysvet.backend.security;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.cysvet.backend.dto.auth.AuthResponse;
import com.cysvet.backend.entity.Empresa;
import com.cysvet.backend.entity.Perfil;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.entity.UsuarioEmpresa;
import com.cysvet.backend.repository.EmpresaRepository;
import com.cysvet.backend.repository.UsuarioEmpresaRepository;
import com.cysvet.backend.repository.UsuarioRepository;
import com.cysvet.backend.support.TestAccounts;
import com.jayway.jsonpath.JsonPath;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.RequestBuilder;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@Transactional
@AutoConfigureMockMvc
class AccountAccessRulesIntegrationTest {

    private static final String PASSWORD = "123456";

    @Autowired
    private TestAccounts testAccounts;

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private EmpresaRepository empresaRepository;

    @Autowired
    private UsuarioEmpresaRepository usuarioEmpresaRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Test
    void deactivatedCompanyBlocksLoginWithEmpresaDesativada() throws Exception {
        String email = "access.login@example.com";
        testAccounts.createAdmin("Login", email, PASSWORD);
        deactivate(testAccounts.companyOf(email));

        mockMvc.perform(login(email))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Empresa desativada"));
    }

    @Test
    void deactivatedCompanyBlocksExistingAccessTokenImmediately() throws Exception {
        String email = "access.token@example.com";
        AuthResponse auth = testAccounts.createAdmin("Token", email, PASSWORD);
        Empresa empresa = testAccounts.companyOf(email);
        deactivate(empresa);

        mockMvc.perform(get("/api/properties")
                        .header("Authorization", "Bearer " + auth.accessToken())
                        .header("empresaid", empresa.getId()))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Empresa desativada"));
    }

    @Test
    void deactivatedCompanyBlocksRefresh() throws Exception {
        String email = "access.refresh@example.com";
        AuthResponse auth = testAccounts.createAdmin("Refresh", email, PASSWORD);
        deactivate(testAccounts.companyOf(email));

        mockMvc.perform(post("/api/auth/refresh")
                        .contentType("application/json")
                        .content("{\"refreshToken\": \"" + auth.refreshToken() + "\"}"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Empresa desativada"));
    }

    @Test
    void userWithAnotherActiveCompanyStillLogsIn() throws Exception {
        String email = "access.multi@example.com";
        testAccounts.createAdmin("Multi", email, PASSWORD);
        Usuario usuario = usuarioRepository.findByEmail(email).orElseThrow();
        Empresa empresaA = testAccounts.companyOf(email);
        Empresa empresaB = newCompany("Empresa B ativa");
        link(usuario, empresaB);
        deactivate(empresaA);

        mockMvc.perform(login(email))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.empresas.length()").value(1))
                .andExpect(jsonPath("$.empresas[0].id").value(empresaB.getId()))
                .andExpect(jsonPath("$.empresaAtivaId").value(empresaB.getId()));
    }

    @Test
    void passwordChangeRequiredBlocksDataRoutes() throws Exception {
        String email = "access.password@example.com";
        testAccounts.createAdmin("Senha", email, PASSWORD);
        Usuario usuario = usuarioRepository.findByEmail(email).orElseThrow();
        usuario.setTrocarSenha(true);
        usuarioRepository.saveAndFlush(usuario);
        Empresa empresa = testAccounts.companyOf(email);

        String body = mockMvc.perform(login(email))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.trocarSenha").value(true))
                .andReturn().getResponse().getContentAsString();
        String accessToken = JsonPath.read(body, "$.accessToken");

        mockMvc.perform(get("/api/properties")
                        .header("Authorization", "Bearer " + accessToken)
                        .header("empresaid", empresa.getId()))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Troca de senha obrigatoria"));
    }

    @Test
    void superAdminLoginReturnsNoCompany() throws Exception {
        String email = createSuperAdmin("super.login@example.com");

        mockMvc.perform(login(email))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.perfil").value("SUPER_ADMIN"))
                .andExpect(jsonPath("$.empresas").isEmpty())
                .andExpect(jsonPath("$.empresaAtivaId").doesNotExist());
    }

    @Test
    void superAdminCannotReadClinicData() throws Exception {
        String email = createSuperAdmin("super.clinic@example.com");
        Empresa empresa = newCompany("Empresa alheia");
        String body = mockMvc.perform(login(email)).andReturn().getResponse().getContentAsString();
        String accessToken = JsonPath.read(body, "$.accessToken");

        mockMvc.perform(get("/api/properties")
                        .header("Authorization", "Bearer " + accessToken)
                        .header("empresaid", empresa.getId()))
                .andExpect(status().isForbidden());

        int withoutHeader = mockMvc.perform(get("/api/properties")
                        .header("Authorization", "Bearer " + accessToken))
                .andReturn().getResponse().getStatus();
        assertTrue(withoutHeader == 400 || withoutHeader == 403, "status sem header: " + withoutHeader);
    }

    @Test
    void adminCannotCallSuperRoutes() throws Exception {
        AuthResponse auth = testAccounts.createAdmin("Admin", "access.admin@example.com", PASSWORD);

        mockMvc.perform(get("/api/super/companies")
                        .header("Authorization", "Bearer " + auth.accessToken()))
                .andExpect(status().isForbidden());
    }

    private RequestBuilder login(String email) {
        return post("/api/auth/login")
                .contentType("application/json")
                .content("{\"email\": \"" + email + "\", \"password\": \"" + PASSWORD + "\"}");
    }

    private void deactivate(Empresa empresa) {
        empresa.setAtivo(false);
        empresaRepository.saveAndFlush(empresa);
    }

    private Empresa newCompany(String name) {
        Empresa empresa = new Empresa();
        empresa.setEmpresaId(UUID.randomUUID().toString());
        empresa.setNome(name);
        empresa.setEmail(UUID.randomUUID() + "@example.com");
        empresa.setAtivo(true);
        return empresaRepository.saveAndFlush(empresa);
    }

    private void link(Usuario usuario, Empresa empresa) {
        UsuarioEmpresa membership = new UsuarioEmpresa();
        membership.setUsuario(usuario);
        membership.setEmpresa(empresa);
        membership.setAtivo(true);
        usuarioEmpresaRepository.saveAndFlush(membership);
    }

    private String createSuperAdmin(String email) {
        Usuario user = new Usuario();
        user.setNome("Super");
        user.setEmail(email);
        user.setSenha(passwordEncoder.encode(PASSWORD));
        user.setPerfil(Perfil.SUPER_ADMIN);
        usuarioRepository.saveAndFlush(user);
        return email;
    }
}
