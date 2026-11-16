package com.cysvet.backend.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.repository.UsuarioEmpresaRepository;
import com.cysvet.backend.repository.UsuarioRepository;
import com.cysvet.backend.support.TestAccounts;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.FormulaError;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Importacao com os padroes das planilhas de campo reais: datas em dd/mm/yy
 * com dia ate 12, zeros e "s/inf" no lugar de celula vazia e erros de formula.
 */
@SpringBootTest
@AutoConfigureMockMvc
class AnimalSpreadsheetImportIntegrationTest {

    private static final String[] CABECALHO = {
            "Matriz (N°)", "Data Nasci.", "Último Parto", "N° de Partos",
            "Sit. Produtiva", "Sit. Reprodutiva", "Data IA última", "TOURO IA"
    };

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

    @Test
    void importaDatasNoFormatoBrasileiroEIgnoraMarcadoresDeVazio() throws Exception {
        AuthContext auth = registerAndAuthenticate("importacao.planilha@example.com");
        long propertyId = createProperty(auth);
        MockMultipartFile file = new MockMultipartFile("file", "campo.xlsx",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", planilhaDeCampo());

        JsonNode preview = readResponse(mockMvc.perform(multipart("/api/animals/import/xlsx/preview")
                        .file(file)
                        .param("sheetName", "CAMPO")
                        .param("idPropriedade", Long.toString(propertyId))
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
        assertEquals(3, preview.path("validRows").asInt());
        assertEquals(1, preview.path("invalidRows").asInt());

        JsonNode result = readResponse(mockMvc.perform(multipart("/api/animals/import/xlsx")
                        .file(file)
                        .param("sheetName", "CAMPO")
                        .param("idPropriedade", Long.toString(propertyId))
                        .param("mappings", objectMapper.writeValueAsString(preview.path("mappings")))
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
        assertEquals(3, result.path("importedRows").asInt());

        // Data numerica formatada como dd/mm/yy: dia e mes nao podem ser invertidos.
        JsonNode lactante = animal(auth, "197781");
        assertEquals("2017-07-11", lactante.path("dataNascimento").asText());
        assertEquals("2026-02-05", lactante.path("dataUltimoParto").asText());
        assertEquals("2026-03-07", lactante.path("dataInseminacao").asText());
        assertEquals(2, lactante.path("numeroLactacao").asInt());
        assertEquals("PENKY MAN", lactante.path("touroIa").asText());
        assertEquals("prenha", lactante.path("statusReprodutivo").asText());

        // Zeros e "s/inf" sao celulas vazias, nao datas ou touros.
        JsonNode novilha = animal(auth, "499629");
        assertTrue(novilha.path("dataNascimento").isNull());
        assertTrue(novilha.path("dataUltimoParto").isNull());
        assertTrue(novilha.path("dataInseminacao").isNull());
        assertTrue(novilha.path("touroIa").isNull());
        assertEquals(0, novilha.path("numeroLactacao").asInt());
        assertEquals("liberada", novilha.path("statusReprodutivo").asText());

        // Data digitada como texto segue o padrao brasileiro dia/mes.
        JsonNode textual = animal(auth, "387949");
        assertEquals("2025-07-07", textual.path("dataNascimento").asText());
        assertEquals("2026-02-05", textual.path("dataUltimoParto").asText());
    }

    /**
     * Relatorio "Controle Reprodutivo" exportado de outro sistema de gestao: titulo antes do
     * cabecalho, brinco na coluna "Nome", "Penultimo Parto" antes de "Ultimo Parto", DEL (dias em
     * lactacao, nao numero de lactacoes) e uma linha de medias no fim.
     */
    @Test
    void importaRelatorioExportadoDeOutroSistema() throws Exception {
        AuthContext auth = registerAndAuthenticate("importacao.outro.sistema@example.com");
        long propertyId = createProperty(auth);
        MockMultipartFile file;
        try (XSSFWorkbook workbook = new XSSFWorkbook(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("Planilha");
            sheet.createRow(0).createCell(0).setCellValue("Controle Reprodutivo");
            sheet.createRow(1).createCell(0).setCellValue("Propriedade: Fazenda Teste");
            sheet.createRow(2).createCell(0).setCellValue("Data Emissão: 11/11/2026 16:21");
            String[] cabecalho = {"Nome", "Raça", "Peso", "Nascimento", "Número de lactações",
                    "Idade 1º parto (meses)", "Penúltimo Parto", "Último Parto", "IEPA", "IEPP", "DEL", "DEA",
                    "Nº de coberturas pós parto"};
            Row header = sheet.createRow(3);
            for (int i = 0; i < cabecalho.length; i++) {
                header.createCell(i).setCellValue(cabecalho[i]);
            }
            Object[][] linhas = {
                    {"01", "Holandês", null, "20/10/2021", 3, 28.9, "08/03/2025", "14/07/2026", 16.22, 12.6, 120, 101, 2},
                    {11, "Holandês", null, "20/06/2021", 3, 19.9, "19/01/2024", "21/06/2025", 17.07, 23.98, 508, 447, 6},
                    {"167 a", "Holandês", null, null, 2, "Sem nascimento", "20/09/2025", "27/08/2026", 11.22, 11.15, 76, 57, 1},
            };
            for (int r = 0; r < linhas.length; r++) {
                Row row = sheet.createRow(4 + r);
                for (int c = 0; c < linhas[r].length; c++) {
                    Object value = linhas[r][c];
                    if (value instanceof Number number) {
                        row.createCell(c).setCellValue(number.doubleValue());
                    } else if (value != null) {
                        row.createCell(c).setCellValue(value.toString());
                    }
                }
            }
            Row medias = sheet.createRow(4 + linhas.length);
            medias.createCell(4).setCellValue("Média");
            medias.createCell(5).setCellValue(29);
            medias.createCell(7).setCellValue("Média");
            workbook.write(output);
            file = new MockMultipartFile("file", "controle.xlsx",
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", output.toByteArray());
        }

        JsonNode preview = readResponse(mockMvc.perform(multipart("/api/animals/import/xlsx/preview")
                        .file(file)
                        .param("sheetName", "Planilha")
                        .param("idPropriedade", Long.toString(propertyId))
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
        JsonNode mappings = preview.path("mappings");
        assertEquals("codigo", mappings.path("0").asText());
        assertEquals("dataNascimento", mappings.path("3").asText());
        assertEquals("numeroLactacao", mappings.path("4").asText());
        assertTrue(mappings.path("6").isMissingNode(), "Penúltimo parto não é o último parto");
        assertEquals("dataUltimoParto", mappings.path("7").asText());
        assertTrue(mappings.path("10").isMissingNode(), "DEL não é número de lactações");
        assertEquals(3, preview.path("validRows").asInt());
        assertEquals(0, preview.path("invalidRows").asInt());

        JsonNode result = readResponse(mockMvc.perform(multipart("/api/animals/import/xlsx")
                        .file(file)
                        .param("sheetName", "Planilha")
                        .param("idPropriedade", Long.toString(propertyId))
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
        assertEquals(3, result.path("importedRows").asInt());

        JsonNode primeira = animal(auth, "01");
        assertEquals("2021-10-20", primeira.path("dataNascimento").asText());
        assertEquals("2026-07-14", primeira.path("dataUltimoParto").asText());
        assertEquals(3, primeira.path("numeroLactacao").asInt());

        JsonNode semNascimento = animal(auth, "167 a");
        assertTrue(semNascimento.path("dataNascimento").isNull());
        assertEquals("2026-08-27", semNascimento.path("dataUltimoParto").asText());
        assertEquals(2, semNascimento.path("numeroLactacao").asInt());
    }

    @Test
    void datasImpossiveisOuFuturasSaoRecusadasEAnoComDoisDigitosFicaNoPassado() throws Exception {
        AuthContext auth = registerAndAuthenticate("importacao.datas@example.com");
        long propertyId = createProperty(auth);
        String[][] linhas = {
                {"D-ABRIL", "31/04/2024"},
                {"D-BISSEXTO", "29/02/2025"},
                {"D-FUTURA", "10/05/2099"},
                {"D-ANO98", "10/05/98"},
                {"D-OK", "29/02/2024"},
        };
        MockMultipartFile file;
        try (XSSFWorkbook workbook = new XSSFWorkbook(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("CAMPO");
            Row header = sheet.createRow(0);
            header.createCell(0).setCellValue("Matriz (N°)");
            header.createCell(1).setCellValue("Data Nasci.");
            for (int i = 0; i < linhas.length; i++) {
                Row row = sheet.createRow(i + 1);
                row.createCell(0).setCellValue(linhas[i][0]);
                row.createCell(1).setCellValue(linhas[i][1]);
            }
            workbook.write(output);
            file = new MockMultipartFile("file", "datas.xlsx",
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", output.toByteArray());
        }

        JsonNode preview = readResponse(mockMvc.perform(multipart("/api/animals/import/xlsx/preview")
                        .file(file)
                        .param("sheetName", "CAMPO")
                        .param("idPropriedade", Long.toString(propertyId))
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
        assertEquals(2, preview.path("validRows").asInt());
        assertEquals(3, preview.path("invalidRows").asInt());

        mockMvc.perform(multipart("/api/animals/import/xlsx")
                        .file(file)
                        .param("sheetName", "CAMPO")
                        .param("idPropriedade", Long.toString(propertyId))
                        .param("mappings", objectMapper.writeValueAsString(preview.path("mappings")))
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isOk());
        assertEquals("1998-05-10", animal(auth, "D-ANO98").path("dataNascimento").asText());
        assertEquals("2024-02-29", animal(auth, "D-OK").path("dataNascimento").asText());
    }

    private byte[] planilhaDeCampo() throws Exception {
        try (XSSFWorkbook workbook = new XSSFWorkbook(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            CellStyle dataCurta = workbook.createCellStyle();
            dataCurta.setDataFormat(workbook.createDataFormat().getFormat("dd/mm/yy;@"));
            CellStyle hora = workbook.createCellStyle();
            hora.setDataFormat(workbook.createDataFormat().getFormat("h:mm:ss"));

            Sheet sheet = workbook.createSheet("CAMPO");
            Row header = sheet.createRow(0);
            for (int i = 0; i < CABECALHO.length; i++) {
                header.createCell(i).setCellValue(CABECALHO[i]);
            }

            Row lactante = sheet.createRow(1);
            lactante.createCell(0).setCellValue("197781");
            data(lactante, 1, LocalDate.of(2017, 7, 11), dataCurta);
            data(lactante, 2, LocalDate.of(2026, 2, 5), dataCurta);
            lactante.createCell(3).setCellValue(2);
            lactante.createCell(4).setCellValue("lactante");
            lactante.createCell(5).setCellValue("prenha");
            data(lactante, 6, LocalDate.of(2026, 3, 7), dataCurta);
            lactante.createCell(7).setCellValue("PENKY MAN");

            Row novilha = sheet.createRow(2);
            novilha.createCell(0).setCellValue("499629");
            novilha.createCell(1).setCellValue("s/inf");
            novilha.createCell(2).setCellValue(0);
            novilha.getCell(2).setCellStyle(hora);
            novilha.createCell(3).setCellValue(0);
            novilha.createCell(4).setCellValue("novilha");
            novilha.createCell(5).setCellValue("liberada");
            novilha.createCell(6).setCellValue(0);
            novilha.getCell(6).setCellStyle(dataCurta);
            novilha.createCell(7).setCellValue(0);

            Row textual = sheet.createRow(3);
            textual.createCell(0).setCellValue("387949");
            textual.createCell(1).setCellValue("07/07/25");
            textual.createCell(2).setCellValue("05/02/2026");
            textual.createCell(3).setCellValue(1);
            textual.createCell(4).setCellValue("lactante");
            textual.createCell(5).setCellValue("pev");

            Row erro = sheet.createRow(4);
            erro.createCell(0).setCellErrorValue(FormulaError.REF.getCode());
            erro.createCell(4).setCellValue("lactante");

            workbook.write(output);
            return output.toByteArray();
        }
    }

    private static void data(Row row, int column, LocalDate value, CellStyle style) {
        row.createCell(column).setCellValue(value);
        row.getCell(column).setCellStyle(style);
    }

    private long createProperty(AuthContext auth) throws Exception {
        return readResponse(mockMvc.perform(post("/api/properties")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId())
                        .contentType(APPLICATION_JSON)
                        .content("""
                                { "idExterno": "prop-importacao", "nome": "Fazenda Importacao", "nomeProprietario": "Produtor" }
                                """))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).path("id").asLong();
    }

    private JsonNode animal(AuthContext auth, String codigo) throws Exception {
        JsonNode animals = readResponse(mockMvc.perform(get("/api/animals")
                        .header("Authorization", auth.authorization())
                        .header("empresaid", auth.tenantId()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());
        for (JsonNode animal : animals) {
            if (codigo.equals(animal.path("codigo").asText())) {
                return animal;
            }
        }
        throw new AssertionError("Animal nao encontrado: " + codigo);
    }

    private AuthContext registerAndAuthenticate(String email) throws Exception {
        testAccounts.createAdmin("Admin " + email, email, "123456");
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
