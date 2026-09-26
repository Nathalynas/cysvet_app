package com.cysvet.backend.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
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
import java.io.ByteArrayOutputStream;
import java.io.File;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * Etapa 3 da auditoria: dado invalido nao pode virar 500 nem travar o sync,
 * codigo de animal e unico por propriedade e a importacao nao deixa arquivos
 * temporarios para tras.
 */
@SpringBootTest
@AutoConfigureMockMvc
class DataReliabilityIntegrationTest {

    private static final String TEMP_PREFIX = "cysvet-animal-import-";

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
    private JdbcTemplate jdbcTemplate;

    @Test
    void tooLongTextIsRejectedWithClearMessageInsteadOfServerError() throws Exception {
        AuthContext auth = registerAndAuthenticate("dados.tamanho@example.com");

        mockMvc.perform(authenticated(post("/api/properties"), auth)
                        .contentType(APPLICATION_JSON)
                        .content("""
                                { "idExterno": "prop-longa", "nome": "Fazenda", "nomeProprietario": "Produtor", "observacoes": "%s" }
                                """.formatted("x".repeat(2500))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("observacoes deve ter no maximo 2000 caracteres"));
    }

    @Test
    void syncRejectsInvalidItemWithoutBlockingTheOthers() throws Exception {
        AuthContext auth = registerAndAuthenticate("dados.sync@example.com");

        mockMvc.perform(authenticated(post("/api/sync"), auth)
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "items": [
                                    {
                                      "chaveMutacao": "mut-prop-longa",
                                      "operationType": "CREATE",
                                      "entity": "property",
                                      "payload": { "idExterno": "prop-sync-longa", "nome": "Fazenda", "nomeProprietario": "Produtor", "observacoes": "%s" }
                                    },
                                    {
                                      "chaveMutacao": "mut-prop-ok",
                                      "operationType": "CREATE",
                                      "entity": "property",
                                      "payload": { "idExterno": "prop-sync-ok", "nome": "Fazenda", "nomeProprietario": "Produtor" }
                                    },
                                    {
                                      "chaveMutacao": "mut-animal-negativo",
                                      "operationType": "CREATE",
                                      "entity": "animal",
                                      "payload": { "idExterno": "animal-negativo", "idExternoPropriedade": "prop-sync-ok", "codigo": "NEG", "numeroLactacao": -1 }
                                    }
                                  ]
                                }
                                """.formatted("x".repeat(2500))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].status").value("REJECTED"))
                .andExpect(jsonPath("$.items[0].message").value("observacoes deve ter no maximo 2000 caracteres"))
                .andExpect(jsonPath("$.items[1].status").value("SYNCED"))
                .andExpect(jsonPath("$.items[2].status").value("REJECTED"))
                .andExpect(jsonPath("$.items[2].message").value("numeroLactacao nao pode ser negativo"));
    }

    @Test
    void animalCodeIsUniquePerPropertyIgnoringCase() throws Exception {
        AuthContext auth = registerAndAuthenticate("dados.codigo@example.com");
        long propertyId = createProperty(auth, "prop-codigo");
        long otherPropertyId = createProperty(auth, "prop-codigo-2");

        createAnimal(auth, propertyId, "animal-dup-1", "DUP").andExpect(status().isCreated());
        createAnimal(auth, propertyId, "animal-dup-2", "dup")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Ja existe um animal com o codigo dup nesta propriedade"));
        // Em outra propriedade o mesmo brinco e permitido.
        createAnimal(auth, otherPropertyId, "animal-dup-3", "DUP").andExpect(status().isCreated());

        long otherId = readResponse(createAnimal(auth, propertyId, "animal-dup-4", "OUTRO")
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).path("id").asLong();
        mockMvc.perform(authenticated(put("/api/animals/{id}", otherId), auth)
                        .contentType(APPLICATION_JSON)
                        .content(animalJson(propertyId, "animal-dup-4", "DUP")))
                .andExpect(status().isBadRequest());
        // Salvar o proprio animal sem trocar o codigo continua funcionando.
        mockMvc.perform(authenticated(put("/api/animals/{id}", otherId), auth)
                        .contentType(APPLICATION_JSON)
                        .content(animalJson(propertyId, "animal-dup-4", "OUTRO")))
                .andExpect(status().isOk());

        mockMvc.perform(authenticated(post("/api/sync"), auth)
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "items": [
                                    {
                                      "chaveMutacao": "mut-animal-dup",
                                      "operationType": "CREATE",
                                      "entity": "animal",
                                      "payload": { "idExterno": "animal-dup-offline", "idExternoPropriedade": "prop-codigo", "codigo": "Dup", "numeroLactacao": 0 }
                                    }
                                  ]
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].status").value("REJECTED"));
    }

    @Test
    void importRejectsOnlyTheRowsThatCannotBeSaved() throws Exception {
        AuthContext auth = registerAndAuthenticate("dados.importacao@example.com");
        long propertyId = createProperty(auth, "prop-importacao-dados");
        createAnimal(auth, propertyId, "animal-rep-1", "REP").andExpect(status().isCreated());
        long repeatedId = readResponse(createAnimal(auth, propertyId, "animal-rep-2", "REP-2")
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).path("id").asLong();
        // Cadastro antigo, anterior a validacao, com o codigo repetido.
        jdbcTemplate.update("update animal set codigo = 'REP' where id = ?", repeatedId);

        MockMultipartFile file = new MockMultipartFile("file", "campo.xlsx",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                spreadsheet(new String[][] {
                        {"NOVO", "ok"},
                        {"REP", "ok"},
                        {"LONGO", "x".repeat(2500)}
                }));
        int tempFilesBefore = countTempFiles();

        JsonNode preview = readResponse(mockMvc.perform(authenticated(multipart("/api/animals/import/xlsx/preview")
                        .file(file)
                        .param("sheetName", "CAMPO")
                        .param("idPropriedade", Long.toString(propertyId)), auth))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
        assertEquals(1, preview.path("validRows").asInt());
        assertEquals(2, preview.path("invalidRows").asInt());
        assertTrue(preview.path("rows").path(1).path("issues").path(0).path("message").asText().contains("Mais de um animal"));
        assertEquals("historicoReprodutivo deve ter no maximo 2000 caracteres",
                preview.path("rows").path(2).path("issues").path(0).path("message").asText());

        JsonNode result = readResponse(mockMvc.perform(authenticated(multipart("/api/animals/import/xlsx")
                        .file(file)
                        .param("sheetName", "CAMPO")
                        .param("idPropriedade", Long.toString(propertyId))
                        .param("mappings", objectMapper.writeValueAsString(preview.path("mappings"))), auth))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
        assertEquals(1, result.path("importedRows").asInt());

        mockMvc.perform(authenticated(multipart("/api/animals/import/xlsx/inspect").file(file), auth))
                .andExpect(status().isOk());
        assertEquals(tempFilesBefore, countTempFiles(), "a importacao deixou arquivos temporarios");
    }

    private byte[] spreadsheet(String[][] rows) throws Exception {
        try (XSSFWorkbook workbook = new XSSFWorkbook(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("CAMPO");
            Row header = sheet.createRow(0);
            header.createCell(0).setCellValue("Matriz (N°)");
            header.createCell(1).setCellValue("Observação");
            for (int i = 0; i < rows.length; i++) {
                Row row = sheet.createRow(i + 1);
                row.createCell(0).setCellValue(rows[i][0]);
                row.createCell(1).setCellValue(rows[i][1]);
            }
            workbook.write(output);
            return output.toByteArray();
        }
    }

    private static int countTempFiles() {
        File[] files = new File(System.getProperty("java.io.tmpdir"))
                .listFiles((dir, name) -> name.startsWith(TEMP_PREFIX));
        return files == null ? 0 : files.length;
    }

    private ResultActions createAnimal(
            AuthContext auth, long propertyId, String idExterno, String codigo) throws Exception {
        return mockMvc.perform(authenticated(post("/api/animals"), auth)
                .contentType(APPLICATION_JSON)
                .content(animalJson(propertyId, idExterno, codigo)));
    }

    private static String animalJson(long propertyId, String idExterno, String codigo) {
        return """
                { "idExterno": "%s", "idPropriedade": %d, "codigo": "%s", "numeroLactacao": 0 }
                """.formatted(idExterno, propertyId, codigo);
    }

    private long createProperty(AuthContext auth, String idExterno) throws Exception {
        return readResponse(mockMvc.perform(authenticated(post("/api/properties"), auth)
                        .contentType(APPLICATION_JSON)
                        .content("""
                                { "idExterno": "%s", "nome": "Fazenda %s", "nomeProprietario": "Produtor" }
                                """.formatted(idExterno, idExterno)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).path("id").asLong();
    }

    private static <T extends MockHttpServletRequestBuilder> T authenticated(T request, AuthContext auth) {
        request.header("Authorization", auth.authorization()).header("empresaid", auth.tenantId());
        return request;
    }

    private AuthContext registerAndAuthenticate(String email) throws Exception {
        authService.register(new RegisterRequest("Admin " + email, email, "123456"));
        JsonNode response = readResponse(mockMvc.perform(post("/api/auth/login")
                        .contentType(APPLICATION_JSON)
                        .content("""
                                { "email": "%s", "password": "123456" }
                                """.formatted(email)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());

        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new AssertionError("Usuario nao encontrado"));
        Long tenantId = usuarioEmpresaRepository.findAllByUsuarioIdAndAtivoTrueOrderByEmpresaNomeAsc(usuario.getId())
                .stream()
                .findFirst()
                .orElseThrow(() -> new AssertionError("Empresa nao encontrada"))
                .getEmpresa()
                .getId();
        return new AuthContext("Bearer " + response.path("accessToken").asText(), tenantId);
    }

    private JsonNode readResponse(String content) throws Exception {
        return objectMapper.readTree(content);
    }

    private record AuthContext(String authorization, Long tenantId) {
    }
}
