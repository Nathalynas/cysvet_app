package com.cysvet.backend.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.cysvet.backend.entity.Empresa;
import com.cysvet.backend.entity.Perfil;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.repository.EmpresaRepository;
import com.cysvet.backend.repository.UsuarioRepository;
import com.cysvet.backend.service.AccessEmailSender;
import com.cysvet.backend.support.TestAccounts;
import com.jayway.jsonpath.JsonPath;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronizationManager;

@SpringBootTest
@Transactional
@AutoConfigureMockMvc
class SuperAdminIntegrationTest {

    private static final String PASSWORD = "123456";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TestAccounts testAccounts;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private EmpresaRepository empresaRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @MockitoBean
    private AccessEmailSender accessEmailSender;

    private final String superEmail = "super." + java.util.UUID.randomUUID() + "@example.com";
    private String superToken;

    @BeforeEach
    void setUp() throws Exception {
        when(accessEmailSender.sendTemporaryPassword(anyString(), anyString(), anyString(), anyString()))
                .thenReturn(true);
        when(accessEmailSender.sendNewTemporaryPassword(anyString(), anyString(), anyString(), anyString()))
                .thenReturn(true);
        superToken = loginSuperAdmin();
    }

    @Test
    void createsCompanyAndResponsibleAndSendsEmail() throws Exception {
        MvcResult result = createCompany("Fazenda Nova", "Maria", "maria@fazenda.com")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.company.name").value("Fazenda Nova"))
                .andExpect(jsonPath("$.company.responsibleName").value("Maria"))
                .andExpect(jsonPath("$.company.responsibleEmail").value("maria@fazenda.com"))
                .andExpect(jsonPath("$.company.status").value("AGUARDANDO_PRIMEIRO_ACESSO"))
                .andExpect(jsonPath("$.emailSent").value(true))
                .andReturn();

        String temporaryPassword = capturedPasswords(1).get(0);
        assertFalse(result.getResponse().getContentAsString().contains(temporaryPassword));

        mockMvc.perform(login("maria@fazenda.com", temporaryPassword))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.trocarSenha").value(true));
    }

    @Test
    void createReturnsEmailSentFalseWhenSendingFails() throws Exception {
        when(accessEmailSender.sendTemporaryPassword(anyString(), anyString(), anyString(), anyString()))
                .thenReturn(false);

        createCompany("Fazenda Sem Email", "Joao", "joao@fazenda.com")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.emailSent").value(false));

        mockMvc.perform(authorized(get("/api/super/companies")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.name == 'Fazenda Sem Email')]").isNotEmpty());
    }

    @Test
    void rejectsDuplicateEmailIgnoringCaseAndSpaces() throws Exception {
        testAccounts.createAdmin("Ana", "ana@x.com", PASSWORD);
        long before = empresaRepository.count();

        createCompany("Outra", "Ana Dois", "  ANA@x.com ")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("E-mail ja cadastrado"));
        createCompany("Outra", "Super Dois", " " + superEmail.toUpperCase() + " ")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("E-mail ja cadastrado"));

        assertEquals(before, empresaRepository.count());
    }

    @Test
    void listsCompaniesWithStatus() throws Exception {
        testAccounts.createAdmin("Ativa", "ativa@x.com", PASSWORD);
        Empresa ativa = testAccounts.companyOf("ativa@x.com");
        ativa.setResponsavel(usuarioRepository.findByEmail("ativa@x.com").orElseThrow());
        empresaRepository.saveAndFlush(ativa);

        createCompany("Aguardando", "Beto", "beto@x.com").andExpect(status().isCreated());

        long desativadaId = createdCompanyId("Desativada", "Caio", "caio@x.com");
        mockMvc.perform(authorized(patch("/api/super/companies/" + desativadaId + "/status"))
                        .contentType("application/json")
                        .content("{\"active\": false}"))
                .andExpect(status().isOk());

        mockMvc.perform(authorized(get("/api/super/companies")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.name == 'Empresa de Ativa')].status").value("ATIVA"))
                .andExpect(jsonPath("$[?(@.name == 'Aguardando')].status").value("AGUARDANDO_PRIMEIRO_ACESSO"))
                .andExpect(jsonPath("$[?(@.name == 'Desativada')].status").value("DESATIVADA"));
    }

    @Test
    void deactivateBlocksUsersAndRevokesRefreshTokens() throws Exception {
        long id = createdCompanyId("Para Desativar", "Dora", "dora@x.com");
        String temporaryPassword = capturedPasswords(1).get(0);
        String oldRefresh = JsonPath.read(
                mockMvc.perform(login("dora@x.com", temporaryPassword)).andReturn().getResponse().getContentAsString(),
                "$.refreshToken");

        mockMvc.perform(authorized(patch("/api/super/companies/" + id + "/status"))
                        .contentType("application/json")
                        .content("{\"active\": false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("DESATIVADA"));

        assertRefreshRejected(oldRefresh);

        mockMvc.perform(login("dora@x.com", temporaryPassword))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Empresa desativada"));

        mockMvc.perform(authorized(patch("/api/super/companies/" + id + "/status"))
                        .contentType("application/json")
                        .content("{\"active\": true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("AGUARDANDO_PRIMEIRO_ACESSO"));

        mockMvc.perform(login("dora@x.com", temporaryPassword))
                .andExpect(status().isOk());
    }

    @Test
    void resendAccessGeneratesNewPasswordAndRequiresChange() throws Exception {
        long id = createdCompanyId("Reenvio", "Eva", "eva@x.com");
        String oldPassword = capturedPasswords(1).get(0);
        String oldRefresh = JsonPath.read(
                mockMvc.perform(login("eva@x.com", oldPassword)).andReturn().getResponse().getContentAsString(),
                "$.refreshToken");

        mockMvc.perform(authorized(post("/api/super/companies/" + id + "/resend-access")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.emailSent").value(true));

        String newPassword = capturedResentPasswords(1).get(0);
        assertFalse(oldPassword.equals(newPassword));

        mockMvc.perform(login("eva@x.com", oldPassword)).andExpect(status().isUnauthorized());
        mockMvc.perform(login("eva@x.com", newPassword))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.trocarSenha").value(true));

        assertRefreshRejected(oldRefresh);
    }

    @Test
    void resendForDeactivatedCompanyReturns400() throws Exception {
        long id = createdCompanyId("Reenvio Inativa", "Ivo", "ivo@x.com");
        String password = capturedPasswords(1).get(0);
        mockMvc.perform(authorized(patch("/api/super/companies/" + id + "/status"))
                        .contentType("application/json")
                        .content("{\"active\": false}"))
                .andExpect(status().isOk());

        mockMvc.perform(authorized(post("/api/super/companies/" + id + "/resend-access")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Empresa desativada"));

        verify(accessEmailSender, never())
                .sendNewTemporaryPassword(anyString(), anyString(), anyString(), anyString());
        mockMvc.perform(authorized(patch("/api/super/companies/" + id + "/status"))
                        .contentType("application/json")
                        .content("{\"active\": true}"))
                .andExpect(status().isOk());
        mockMvc.perform(login("ivo@x.com", password)).andExpect(status().isOk());
    }

    @Test
    void resendForCompanyWithoutResponsibleReturns400() throws Exception {
        testAccounts.createAdmin("Sem", "sem@x.com", PASSWORD);
        Empresa empresa = testAccounts.companyOf("sem@x.com");

        mockMvc.perform(authorized(post("/api/super/companies/" + empresa.getId() + "/resend-access")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Empresa sem responsavel"));
    }

    @Test
    void unknownCompanyReturns404() throws Exception {
        mockMvc.perform(authorized(patch("/api/super/companies/999999/status"))
                        .contentType("application/json")
                        .content("{\"active\": false}"))
                .andExpect(status().isNotFound());
        mockMvc.perform(authorized(post("/api/super/companies/999999/resend-access")))
                .andExpect(status().isNotFound());
    }

    @Test
    @Transactional(propagation = Propagation.NOT_SUPPORTED)
    void createSendsEmailOnlyAfterCommit() throws Exception {
        String email = "after.commit." + java.util.UUID.randomUUID() + "@x.com";
        AtomicReference<String> observed = new AtomicReference<>();
        when(accessEmailSender.sendTemporaryPassword(anyString(), anyString(), anyString(), anyString()))
                .thenAnswer(invocation -> {
                    boolean noTransaction = !TransactionSynchronizationManager.isActualTransactionActive();
                    boolean visible = usuarioRepository.existsByEmailIgnoreCase(email);
                    observed.set(noTransaction + "/" + visible);
                    return true;
                });

        createCompany("Apos Commit", "Fabio", email).andExpect(status().isCreated());

        assertEquals("true/true", observed.get());
    }

    @Test
    @Transactional(propagation = Propagation.NOT_SUPPORTED)
    void resendSendsEmailOnlyAfterCommit() throws Exception {
        String email = "resend.commit." + java.util.UUID.randomUUID() + "@x.com";
        long id = createdCompanyId("Reenvio Commit", "Gil", email);
        String oldPassword = capturedPasswords(1).get(0);
        AtomicReference<String> observed = new AtomicReference<>();
        when(accessEmailSender.sendNewTemporaryPassword(anyString(), anyString(), anyString(), anyString()))
                .thenAnswer(invocation -> {
                    String newPassword = invocation.getArgument(3);
                    boolean noTransaction = !TransactionSynchronizationManager.isActualTransactionActive();
                    Usuario stored = usuarioRepository.findByEmail(email).orElseThrow();
                    boolean committed = passwordEncoder.matches(newPassword, stored.getSenha());
                    observed.set(noTransaction + "/" + committed);
                    return true;
                });

        mockMvc.perform(authorized(post("/api/super/companies/" + id + "/resend-access")))
                .andExpect(status().isOk());

        assertEquals("true/true", observed.get());
        assertFalse(oldPassword.isEmpty());
    }

    private void assertRefreshRejected(String refreshToken) throws Exception {
        // O refresh revogado e tratado como token invalido (400) pelo fluxo de autenticacao existente.
        mockMvc.perform(post("/api/auth/refresh")
                        .contentType("application/json")
                        .content("{\"refreshToken\": \"" + refreshToken + "\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Refresh token invalido"));
    }

    private ResultActions createCompany(String companyName, String responsibleName, String email) throws Exception {
        return mockMvc.perform(authorized(post("/api/super/companies"))
                .contentType("application/json")
                .content("{\"companyName\": \"" + companyName + "\", \"responsibleName\": \""
                        + responsibleName + "\", \"responsibleEmail\": \"" + email + "\"}"));
    }

    private long createdCompanyId(String companyName, String responsibleName, String email) throws Exception {
        String body = createCompany(companyName, responsibleName, email)
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return ((Number) JsonPath.read(body, "$.company.id")).longValue();
    }

    private List<String> capturedPasswords(int expectedCalls) {
        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(accessEmailSender, times(expectedCalls))
                .sendTemporaryPassword(anyString(), anyString(), anyString(), captor.capture());
        return captor.getAllValues();
    }

    private List<String> capturedResentPasswords(int expectedCalls) {
        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(accessEmailSender, times(expectedCalls))
                .sendNewTemporaryPassword(anyString(), anyString(), anyString(), captor.capture());
        return captor.getAllValues();
    }

    private MockHttpServletRequestBuilder authorized(MockHttpServletRequestBuilder builder) {
        return builder.header("Authorization", "Bearer " + superToken);
    }

    private MockHttpServletRequestBuilder login(String email, String password) {
        return post("/api/auth/login")
                .contentType("application/json")
                .content("{\"email\": \"" + email + "\", \"password\": \"" + password + "\"}");
    }

    private String loginSuperAdmin() throws Exception {
        Usuario user = new Usuario();
        user.setNome("Super");
        user.setEmail(superEmail);
        user.setSenha(passwordEncoder.encode(PASSWORD));
        user.setPerfil(Perfil.SUPER_ADMIN);
        usuarioRepository.saveAndFlush(user);
        String body = mockMvc.perform(login(superEmail, PASSWORD))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(body, "$.accessToken");
    }
}
