package com.cysvet.backend.controller;

import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.cysvet.backend.support.TestAccounts;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Preferencias da conta: atalhos de situacao reprodutiva da visita, guardados
 * por usuario no servidor para valerem em qualquer aparelho.
 */
@SpringBootTest
@AutoConfigureMockMvc
class AccountPreferencesIntegrationTest {

    @Autowired
    private TestAccounts testAccounts;

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void semEscolhaDevolveOsQuatroAtalhosPadrao() throws Exception {
        Auth auth = login("preferencias.padrao@example.com");

        mockMvc.perform(get("/api/account/preferences")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.atalhosSituacaoReprodutiva.length()").value(4))
                .andExpect(jsonPath("$.atalhosSituacaoReprodutiva[0]").value("prenha"))
                .andExpect(jsonPath("$.atalhosSituacaoReprodutiva[1]").value("vazia"))
                .andExpect(jsonPath("$.atalhosSituacaoReprodutiva[2]").value("inseminada"))
                .andExpect(jsonPath("$.atalhosSituacaoReprodutiva[3]").value("aguardando dg"))
                .andExpect(jsonPath("$.atalhosPadrao").value(true));
    }

    @Test
    void salvaOsAtalhosNormalizadosSemRepetirEValeEmOutroLogin() throws Exception {
        Auth auth = login("preferencias.salvar@example.com");

        mockMvc.perform(put("/api/account/preferences")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content("""
                                { "atalhosSituacaoReprodutiva": ["Em Protocolo", "prenha", "pregnant", "inducao"] }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.atalhosSituacaoReprodutiva.length()").value(3))
                .andExpect(jsonPath("$.atalhosSituacaoReprodutiva[0]").value("em protocolo"))
                .andExpect(jsonPath("$.atalhosSituacaoReprodutiva[1]").value("prenha"))
                .andExpect(jsonPath("$.atalhosSituacaoReprodutiva[2]").value("inducao"))
                .andExpect(jsonPath("$.atalhosPadrao").value(false));

        Auth again = login("preferencias.salvar@example.com", false);
        mockMvc.perform(get("/api/account/preferences")
                        .header("Authorization", again.authorization())
                        .header("empresaid", again.tenantId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.atalhosSituacaoReprodutiva[0]").value("em protocolo"));
    }

    @Test
    void recusaSituacaoInvalidaSecaListaVaziaOuMaisDeOito() throws Exception {
        Auth auth = login("preferencias.invalida@example.com");

        for (String body : new String[] {
                "{ \"atalhosSituacaoReprodutiva\": [\"prenha\", \"qualquer coisa\"] }",
                "{ \"atalhosSituacaoReprodutiva\": [\"seca\"] }",
                "{ \"atalhosSituacaoReprodutiva\": [] }",
                "{ \"atalhosSituacaoReprodutiva\": [\"em protocolo\", \"vazia\", \"liberada\", \"atrasada\","
                        + " \"aguardando dg\", \"inseminada st\", \"prenha\", \"inducao\", \"descarte\"] }"
        }) {
            mockMvc.perform(put("/api/account/preferences")
                            .header("Authorization", auth.authorization())
                            .header("empresaid", auth.tenantId())
                            .contentType(APPLICATION_JSON)
                            .content(body))
                    .andExpect(status().isBadRequest());
        }
    }

    @Test
    void voltarAoPadraoApagaAEscolha() throws Exception {
        Auth auth = login("preferencias.reset@example.com");
        mockMvc.perform(put("/api/account/preferences")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content("{ \"atalhosSituacaoReprodutiva\": [\"descarte\"] }"))
                .andExpect(status().isOk());

        mockMvc.perform(put("/api/account/preferences")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content("{ \"atalhosSituacaoReprodutiva\": null }"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.atalhosSituacaoReprodutiva.length()").value(4))
                .andExpect(jsonPath("$.atalhosPadrao").value(true));
    }

    private Auth login(String email) throws Exception {
        return login(email, true);
    }

    private Auth login(String email, boolean create) throws Exception {
        if (create) {
            testAccounts.createAdmin("Admin " + email, email, "123456");
        }
        JsonNode response = objectMapper.readTree(mockMvc.perform(post("/api/auth/login")
                        .contentType(APPLICATION_JSON)
                        .content("""
                                { "email": "%s", "password": "123456" }
                                """.formatted(email)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
        return new Auth("Bearer " + response.path("accessToken").asText(), response.path("empresaAtivaId").asLong());
    }

    private record Auth(String authorization, Long tenantId) {
    }
}
