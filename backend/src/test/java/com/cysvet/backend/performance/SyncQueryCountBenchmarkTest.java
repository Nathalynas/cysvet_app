package com.cysvet.backend.performance;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
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
import jakarta.persistence.EntityManagerFactory;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.RequestBuilder;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * Conta as queries SQL e o tempo das operacoes do servidor com um rebanho do
 * tamanho da fazenda real (~300 animais). Serve de comparacao antes/depois de
 * otimizacoes; o resultado vai para o console e para
 * {@code target/performance/sync-queries.json}.
 *
 * <p>O numero de queries nao depende do banco. Os tempos sao do H2 em memoria
 * no PC, sem rede: servem para comparar versoes, nao para prever producao.
 */
@SpringBootTest(properties = "spring.jpa.properties.hibernate.generate_statistics=true")
@AutoConfigureMockMvc
class SyncQueryCountBenchmarkTest {

    private static final int ANIMAIS = 300;
    private static final int RODADAS = 3;
    private static final LocalDate HOJE = LocalDate.now();

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

    @Autowired
    private EntityManagerFactory entityManagerFactory;

    @Test
    void mede() throws Exception {
        Map<String, List<Medicao>> medicoes = new LinkedHashMap<>();
        for (int rodada = 1; rodada <= RODADAS; rodada++) {
            rodada(rodada, medicoes);
        }
        relatar(medicoes);
    }

    private void rodada(int rodada, Map<String, List<Medicao>> medicoes) throws Exception {
        Auth auth = registrar("bench" + rodada + "@example.com");
        String propriedade = "prop-bench-" + rodada;
        long idPropriedade = criarPropriedade(auth, propriedade);
        for (int i = 0; i < ANIMAIS; i++) {
            criarAnimal(auth, idPropriedade, animal(rodada, i), "B%d-%03d".formatted(rodada, i));
        }

        String v1 = "visit-bench-" + rodada + "-1";
        String v2 = "visit-bench-" + rodada + "-2";
        LocalDate parto = HOJE.minusDays(100);
        LocalDate ia = HOJE.minusDays(40);

        medir(medicoes, "1. sync visita nova (300 animais, 3 eventos cada)",
                sync(auth, "m" + rodada + "a", "CREATE", visita(v1, propriedade, HOJE.minusDays(1), rodada, parto, ia, "pg")));
        medir(medicoes, "2. sync da mesma visita editada",
                sync(auth, "m" + rodada + "b", "UPDATE", visita(v1, propriedade, HOJE.minusDays(1), rodada, parto, ia, "reavaliar")));
        medir(medicoes, "3. sync 2a visita com os mesmos parto/IA",
                sync(auth, "m" + rodada + "c", "CREATE", visita(v2, propriedade, HOJE, rodada, parto, ia, "pg")));
        medir(medicoes, "4. sync visita 1 sem animais (eventos passam p/ visita 2)",
                sync(auth, "m" + rodada + "d", "UPDATE", visitaVazia(v1, propriedade, HOJE.minusDays(1))));
        conferirEstadoFinal(auth, rodada, v2, parto, ia);

        medir(medicoes, "5. GET /api/animals (lista)", autenticado(get("/api/animals"), auth));
        medir(medicoes, "6. GET /api/visits (lista)", autenticado(get("/api/visits"), auth));
        medir(medicoes, "7. GET /api/sync/pull (primeira carga)", autenticado(get("/api/sync/pull"), auth));
    }

    private void medir(Map<String, List<Medicao>> medicoes, String nome, RequestBuilder request) throws Exception {
        Statistics stats = entityManagerFactory.unwrap(SessionFactory.class).getStatistics();
        stats.clear();
        long inicio = System.nanoTime();
        ResultActions resultado = mockMvc.perform(request).andExpect(status().is2xxSuccessful());
        double ms = (System.nanoTime() - inicio) / 1_000_000.0;
        medicoes.computeIfAbsent(nome, chave -> new ArrayList<>())
                .add(new Medicao(stats.getPrepareStatementCount(), ms));
        // O sync responde 200 mesmo quando o item falha; o status vem no corpo.
        if (nome.contains(". sync ")) {
            resultado.andExpect(jsonPath("$.items[0].status").value("SYNCED"));
        }
    }

    // A visita 1 ficou sem animais: parto, IA e situacao de cada animal passam a
    // ser da visita 2, e o resumo reflete esses eventos.
    private void conferirEstadoFinal(Auth auth, int rodada, String v2, LocalDate parto, LocalDate ia) throws Exception {
        JsonNode animais = objectMapper.readTree(mockMvc.perform(autenticado(get("/api/animals"), auth))
                .andReturn().getResponse().getContentAsString());
        assertEquals(ANIMAIS, animais.size());
        for (JsonNode animal : animais) {
            assertEquals(2, animal.path("numeroLactacao").asInt());
            assertEquals(parto.toString(), animal.path("dataUltimoParto").asText());
            assertEquals(ia.toString(), animal.path("dataInseminacao").asText());
            assertEquals("inseminada st", animal.path("statusReprodutivo").asText());
        }
        long idAnimal = animais.get(rodada).path("id").asLong();
        JsonNode eventos = objectMapper.readTree(mockMvc.perform(autenticado(get("/api/events"), auth)
                        .queryParam("idAnimal", Long.toString(idAnimal)))
                .andReturn().getResponse().getContentAsString());
        assertEquals(3, eventos.size());
        eventos.forEach(evento -> assertEquals(v2, evento.path("idExternoVisita").asText()));
    }

    private void relatar(Map<String, List<Medicao>> medicoes) throws Exception {
        StringBuilder tabela = new StringBuilder("\n| Operacao | Queries SQL | Tempo mediano (ms) |\n|---|---:|---:|\n");
        Map<String, Map<String, Object>> json = new LinkedHashMap<>();
        medicoes.forEach((nome, lista) -> {
            // A primeira rodada aquece a JVM; a mediana descarta o extremo.
            List<Double> tempos = lista.stream().map(Medicao::ms).sorted().toList();
            double mediana = tempos.get(tempos.size() / 2);
            long queries = lista.get(lista.size() - 1).queries();
            tabela.append("| %s | %d | %.0f |\n".formatted(nome, queries, mediana));
            json.put(nome, Map.of("queries", queries, "medianaMs", Math.round(mediana), "temposMs",
                    lista.stream().map(m -> Math.round(m.ms())).toList()));
        });
        System.out.println(tabela);
        Path saida = Path.of("target", "performance", "sync-queries.json");
        Files.createDirectories(saida.getParent());
        objectMapper.writerWithDefaultPrettyPrinter().writeValue(saida.toFile(), json);
    }

    private String visita(String idExterno, String propriedade, LocalDate data, int rodada,
                          LocalDate parto, LocalDate ia, String decisao) {
        List<String> itens = new ArrayList<>();
        for (int i = 0; i < ANIMAIS; i++) {
            itens.add("""
                    {
                      "animalIdExterno": "%s",
                      "situacaoReprodutiva": "inseminada st",
                      "decisao": "%s",
                      "dataUltimoParto": "%s",
                      "dataUltimaIa": "%s",
                      "numeroIaRecebida": 1
                    }
                    """.formatted(animal(rodada, i), decisao, parto, ia));
        }
        return """
                { "idExterno": "%s", "idExternoPropriedade": "%s", "dataVisita": "%s", "animais": [%s] }
                """.formatted(idExterno, propriedade, data, String.join(",", itens));
    }

    private String visitaVazia(String idExterno, String propriedade, LocalDate data) {
        return """
                { "idExterno": "%s", "idExternoPropriedade": "%s", "dataVisita": "%s", "animais": [] }
                """.formatted(idExterno, propriedade, data);
    }

    private static String animal(int rodada, int i) {
        return "animal-bench-%d-%03d".formatted(rodada, i);
    }

    private RequestBuilder sync(Auth auth, String chave, String operacao, String payload) {
        return autenticado(post("/api/sync"), auth)
                .contentType(APPLICATION_JSON)
                .content("""
                        { "items": [ { "chaveMutacao": "%s", "operationType": "%s", "entity": "visit", "payload": %s } ] }
                        """.formatted(chave, operacao, payload));
    }

    private MockHttpServletRequestBuilder autenticado(MockHttpServletRequestBuilder request, Auth auth) {
        return request.header("Authorization", auth.authorization()).header("empresaid", auth.tenantId());
    }

    private long criarPropriedade(Auth auth, String idExterno) throws Exception {
        String body = mockMvc.perform(autenticado(post("/api/properties"), auth)
                        .contentType(APPLICATION_JSON)
                        .content("""
                                { "idExterno": "%s", "nome": "Fazenda %s", "nomeProprietario": "Produtor" }
                                """.formatted(idExterno, idExterno)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return objectMapper.readTree(body).path("id").asLong();
    }

    private void criarAnimal(Auth auth, long idPropriedade, String idExterno, String codigo) throws Exception {
        mockMvc.perform(autenticado(post("/api/animals"), auth)
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "idExterno": "%s",
                                  "idPropriedade": %d,
                                  "codigo": "%s",
                                  "numeroLactacao": 1,
                                  "dataUltimoParto": "2025-01-10",
                                  "statusReprodutivo": "pev"
                                }
                                """.formatted(idExterno, idPropriedade, codigo)))
                .andExpect(status().isCreated());
    }

    private Auth registrar(String email) throws Exception {
        authService.register(new RegisterRequest("Admin " + email, email, "123456"));
        String body = mockMvc.perform(post("/api/auth/login")
                        .contentType(APPLICATION_JSON)
                        .content("""
                                { "email": "%s", "password": "123456" }
                                """.formatted(email)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        JsonNode response = objectMapper.readTree(body);
        Usuario usuario = usuarioRepository.findByEmail(email).orElseThrow();
        Long tenantId = usuarioEmpresaRepository.findAllByUsuarioIdAndAtivoTrueOrderByEmpresaNomeAsc(usuario.getId())
                .stream().findFirst().orElseThrow().getEmpresa().getId();
        return new Auth("Bearer " + response.path("accessToken").asText(), tenantId);
    }

    private record Auth(String authorization, Long tenantId) {
    }

    private record Medicao(long queries, double ms) {
    }
}
