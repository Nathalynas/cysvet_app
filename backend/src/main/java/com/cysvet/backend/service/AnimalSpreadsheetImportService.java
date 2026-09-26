package com.cysvet.backend.service;

import com.cysvet.backend.dto.animal.AnimalRequest;
import com.cysvet.backend.dto.animal.AnimalSpreadsheetCellResponse;
import com.cysvet.backend.dto.animal.AnimalSpreadsheetImportResponse;
import com.cysvet.backend.dto.animal.AnimalSpreadsheetIssueResponse;
import com.cysvet.backend.dto.animal.AnimalSpreadsheetPreviewResponse;
import com.cysvet.backend.dto.animal.AnimalSpreadsheetRowResponse;
import com.cysvet.backend.entity.Propriedade;
import com.cysvet.backend.entity.StatusAnimal;
import com.cysvet.backend.entity.StatusReprodutivoAnimal;
import com.cysvet.backend.repository.PropriedadeRepository;
import com.cysvet.backend.util.Textos;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validator;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Stream;
import lombok.RequiredArgsConstructor;
import org.apache.poi.ooxml.util.SAXHelper;
import org.apache.poi.openxml4j.opc.OPCPackage;
import org.apache.poi.openxml4j.opc.PackageAccess;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.DateUtil;
import org.apache.poi.xssf.eventusermodel.ReadOnlySharedStringsTable;
import org.apache.poi.xssf.eventusermodel.XSSFReader;
import org.apache.poi.xssf.eventusermodel.XSSFSheetXMLHandler;
import org.apache.poi.xssf.model.StylesTable;
import org.apache.poi.xssf.usermodel.XSSFComment;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.xml.sax.InputSource;

/** Reads XLSX files as SAX events: only the preview rows are retained in memory. */
@Service
@RequiredArgsConstructor
public class AnimalSpreadsheetImportService {

    private static final int PREVIEW_LIMIT = 100;
    private static final int HEADER_SEARCH_ROWS = 30;
    private static final List<String> REQUIRED = List.of("codigo");

    private static final List<DateTimeFormatter> FORMATOS_DE_DATA = List.of(
            DateTimeFormatter.ISO_LOCAL_DATE,
            DateTimeFormatter.ofPattern("d/M/uuuu"),
            DateTimeFormatter.ofPattern("d/M/uu"),
            DateTimeFormatter.ofPattern("M/d/uuuu"),
            DateTimeFormatter.ofPattern("M/d/uu"),
            DateTimeFormatter.ofPattern("d-M-uuuu"),
            DateTimeFormatter.ofPattern("d-M-uu"));

    // Planilhas de campo usam 0, FALSO, "s/inf" e erros de formula no lugar de celula vazia.
    private static final Set<String> MARCADORES_DE_VAZIO = Set.of(
            "0", "0,0", "0.0", "false", "falso", "s/inf", "s/ inf", "s inf", "sem inf", "sem informacao", "-", "--", "n/a");

    private static final Map<String, List<String>> ALIASES = Map.ofEntries(
            Map.entry("codigo", tokens(
                    "brinco", "id", "codigo", "cod animal", "animal", "matriz", "matriz n", "matriz numero", "numero",
                    "n animal")),
            Map.entry("dataNascimento", tokens(
                    "data de nascimento", "data nascimento", "data nasci", "nascimento", "dt nascimento", "data nasc")),
            Map.entry("situacaoProdutiva", tokens("situacao produtiva", "sit produtiva")),
            Map.entry("statusReprodutivo", tokens("status reprodutivo", "situacao reprodutiva", "sit reprodutiva")),
            Map.entry("numeroLactacao", tokens(
                    "numero de lactacao", "n lactacao", "lactacao", "numero lactacao", "numero de partos", "n de partos",
                    "partos", "del")),
            Map.entry("dataUltimoParto", tokens(
                    "data do parto", "data ultimo parto", "ultimo parto", "data up", "up", "parto anterior")),
            Map.entry("dataInseminacao", tokens(
                    "data da inseminacao", "data inseminacao", "data ia", "data ia ultima", "ultima ia", "inseminacao")),
            Map.entry("touroIa", tokens("touro ia", "touro de ia", "touro inseminacao", "reprodutor", "touro")),
            Map.entry("historicoReprodutivo", tokens(
                    "historico", "historico reprodutivo", "observacao", "observacoes", "obs", "motivo")));

    private final PropriedadeRepository propriedadeRepository;
    private final AnimalService animalService;
    private final Validator validator;

    public List<String> inspect(MultipartFile file) {
        try {
            return withPackage(file, pkg -> {
                XSSFReader.SheetIterator sheets = (XSSFReader.SheetIterator) new XSSFReader(pkg).getSheetsData();
                List<String> names = new ArrayList<>();
                while (sheets.hasNext()) {
                    try (InputStream ignored = sheets.next()) {
                        names.add(sheets.getSheetName());
                    }
                }
                return names;
            });
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalArgumentException("Não foi possível ler o arquivo .xlsx", e);
        }
    }

    public AnimalSpreadsheetPreviewResponse preview(MultipartFile file, String sheetName, Long propertyId,
                                                    Map<Integer, String> requestedMappings) {
        List<Propriedade> properties = propriedadeRepository.findAllByOrderByNomeAsc();
        SheetResult result = read(file, sheetName, requestedMappings, property(properties, propertyId), false);
        return new AnimalSpreadsheetPreviewResponse(result.sheetName, result.headerRowIndex, result.columns,
                result.previewRows, result.mappings, result.missingRequired, result.valid, result.pending,
                result.invalid, result.total);
    }

    @Transactional
    public AnimalSpreadsheetImportResponse importValid(MultipartFile file, String sheetName, Long propertyId,
                                                       Map<Integer, String> mappings) {
        List<Propriedade> properties = propriedadeRepository.findAllByOrderByNomeAsc();
        SheetResult result = read(file, sheetName, mappings, property(properties, propertyId), true);
        return new AnimalSpreadsheetImportResponse(result.imported, result.invalid, result.pending);
    }

    private SheetResult read(MultipartFile file, String selectedSheet, Map<Integer, String> requestedMappings,
                             Propriedade property, boolean save) {
        try {
            return withPackage(file, pkg -> readSheet(pkg, selectedSheet, requestedMappings, property, save));
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalArgumentException("Não foi possível processar a aba selecionada", e);
        }
    }

    private SheetResult readSheet(OPCPackage pkg, String selectedSheet, Map<Integer, String> requestedMappings,
                                  Propriedade property, boolean save) throws Exception {
        XSSFReader reader = new XSSFReader(pkg);
        StylesTable styles = reader.getStylesTable();
        ReadOnlySharedStringsTable strings = new ReadOnlySharedStringsTable(pkg);
        XSSFReader.SheetIterator sheets = (XSSFReader.SheetIterator) reader.getSheetsData();
        SheetResult combined = null;
        while (sheets.hasNext()) {
            try (InputStream stream = sheets.next()) {
                String sheetName = sheets.getSheetName();
                if (!sheetName.equals(selectedSheet)) {
                    continue;
                }
                SheetResult result = new SheetResult(sheetName, requestedMappings, property, save);
                var parser = SAXHelper.newXMLReader();
                parser.setContentHandler(new XSSFSheetXMLHandler(
                        styles, null, strings, result, new FormatadorDeCelulas(), false));
                parser.parse(new InputSource(stream));
                result.finish();
                if (combined == null) {
                    combined = result;
                } else {
                    combined.merge(result);
                }
            }
        }
        if (combined == null) {
            throw new IllegalArgumentException("Aba selecionada nao encontrada na planilha");
        }
        return combined;
    }

    // A planilha e copiada para um arquivo temporario (o POI le por acesso
    // aleatorio) e apagada ao fim de cada leitura; deleteOnExit so apagava
    // quando a JVM encerrava e cada importacao deixava 3 copias no disco.
    private <T> T withPackage(MultipartFile file, PackageReader<T> action) throws Exception {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Envie uma planilha .xlsx");
        }
        Path temp = Files.createTempFile("cysvet-animal-import-", ".xlsx");
        try {
            file.transferTo(temp);
            try (OPCPackage pkg = OPCPackage.open(temp.toFile(), PackageAccess.READ)) {
                return action.read(pkg);
            }
        } finally {
            try {
                Files.deleteIfExists(temp);
            } catch (IOException e) {
                temp.toFile().deleteOnExit();
            }
        }
    }

    @FunctionalInterface
    private interface PackageReader<T> {
        T read(OPCPackage pkg) throws Exception;
    }

    /** Acumula o resultado de uma aba; recebe as linhas do parser SAX uma a uma. */
    private final class SheetResult implements XSSFSheetXMLHandler.SheetContentsHandler {

        final String sheetName;
        final Map<Integer, String> requested;
        final boolean autoMap;
        final Propriedade property;
        final boolean save;

        final List<List<String>> firstRows = new ArrayList<>();
        final List<AnimalSpreadsheetRowResponse> previewRows = new ArrayList<>();
        final Set<String> importedCodes = new HashSet<>();

        List<String> columns = List.of();
        Map<Integer, String> mappings = new LinkedHashMap<>();
        List<String> missingRequired = List.of();
        List<String> row;
        int headerRowIndex = 0;
        int valid;
        int pending;
        int invalid;
        int total;
        int imported;

        SheetResult(String sheetName, Map<Integer, String> requested, Propriedade property, boolean save) {
            this.sheetName = sheetName;
            this.autoMap = requested == null;
            this.requested = requested == null ? Map.of() : requested;
            this.property = property;
            this.save = save;
        }

        void merge(SheetResult other) {
            valid += other.valid;
            pending += other.pending;
            invalid += other.invalid;
            total += other.total;
            imported += other.imported;
            missingRequired = Stream.concat(missingRequired.stream(), other.missingRequired.stream())
                    .distinct()
                    .toList();
        }

        @Override
        public void startRow(int rowNum) {
            row = new ArrayList<>();
        }

        @Override
        public void endRow(int rowNum) {
            if (firstRows.size() < HEADER_SEARCH_ROWS) {
                firstRows.add(List.copyOf(row));
            }
            boolean initializedNow = false;
            if (columns.isEmpty() && firstRows.size() == HEADER_SEARCH_ROWS) {
                initialize();
                initializedNow = true;
            }
            if (!initializedNow && !columns.isEmpty() && rowNum > headerRowIndex
                    && row.stream().anyMatch(value -> !value.isBlank())) {
                process(rowNum, row);
            }
        }

        @Override
        public void cell(String ref, String value, XSSFComment comment) {
            int col = column(ref);
            while (row.size() <= col) {
                row.add("");
            }
            row.set(col, value == null ? "" : value);
        }

        @Override
        public void headerFooter(String text, boolean isHeader, String tagName) {
        }

        void finish() {
            if (columns.isEmpty()) {
                initialize();
            }
        }

        void initialize() {
            if (firstRows.isEmpty()) {
                columns = List.of();
                return;
            }
            headerRowIndex = detectHeader(firstRows);
            List<String> header = firstRows.get(headerRowIndex);
            columns = new ArrayList<>();
            for (int i = 0; i < header.size(); i++) {
                columns.add(header.get(i).isBlank() ? "Coluna " + (i + 1) : header.get(i).trim());
            }
            if (autoMap) {
                for (int i = 0; i < columns.size(); i++) {
                    String field = fieldForHeader(columns.get(i));
                    if (field != null && !mappings.containsValue(field)) {
                        mappings.put(i, field);
                    }
                }
            } else {
                mappings = new LinkedHashMap<>(requested);
            }
            missingRequired = REQUIRED.stream().filter(field -> !mappings.containsValue(field)).toList();
            // Rows read before the 30th row are replayed after headers are known.
            for (int i = headerRowIndex + 1; i < firstRows.size(); i++) {
                process(i, firstRows.get(i));
            }
        }

        void process(int rowNumber, List<String> cells) {
            if (columns.isEmpty() || rowNumber <= headerRowIndex) {
                return;
            }
            total++;
            List<AnimalSpreadsheetIssueResponse> issues = new ArrayList<>();
            Map<String, String> values = new LinkedHashMap<>();
            for (var entry : mappings.entrySet()) {
                int col = entry.getKey();
                String field = entry.getValue();
                String value = col < cells.size() ? semMarcadorDeVazio(cells.get(col)) : "";
                values.put(field, value);
                if (REQUIRED.contains(field) && value.isBlank()) {
                    issues.add(new AnimalSpreadsheetIssueResponse(col, "Campo obrigatório vazio"));
                }
            }

            String code = normalize(values.get("codigo"));
            if (!code.isEmpty() && !importedCodes.add(code)) {
                issues.add(new AnimalSpreadsheetIssueResponse(columnFor("codigo"), "Animal duplicado na planilha"));
            }

            AnimalRequest request = null;
            if (issues.isEmpty() && missingRequired.isEmpty()) {
                try {
                    request = toRequest(values);
                } catch (IllegalArgumentException ex) {
                    String[] error = ex.getMessage().split("\\|", 2);
                    issues.add(new AnimalSpreadsheetIssueResponse(
                            columnFor(error[0]), error.length > 1 ? error[1] : ex.getMessage()));
                }
            }
            if (request != null) {
                // Mesmas regras da API (tamanho dos campos): um valor longo demais derrubaria a importacao inteira no banco.
                for (ConstraintViolation<AnimalRequest> violation : validator.validate(request)) {
                    issues.add(new AnimalSpreadsheetIssueResponse(
                            columnFor(violation.getPropertyPath().toString()), violation.getMessage()));
                }
                if (issues.isEmpty() && animalService.hasRepeatedCode(property.getId(), request.codigo())) {
                    issues.add(new AnimalSpreadsheetIssueResponse(columnFor("codigo"),
                            "Mais de um animal com este código na propriedade; corrija o cadastro antes de importar"));
                }
                if (!issues.isEmpty()) {
                    request = null;
                }
            }

            String status;
            if (!issues.isEmpty()) {
                invalid++;
                status = "invalid";
            } else if (!missingRequired.isEmpty()) {
                pending++;
                status = "pending";
            } else {
                valid++;
                status = "valid";
                if (save) {
                    animalService.createOrUpdateFromImport(request);
                    imported++;
                }
            }

            if (previewRows.size() < PREVIEW_LIMIT) {
                List<AnimalSpreadsheetCellResponse> responseCells = new ArrayList<>();
                for (int i = 0; i < columns.size(); i++) {
                    responseCells.add(new AnimalSpreadsheetCellResponse(i < cells.size() ? cells.get(i) : "", false));
                }
                previewRows.add(new AnimalSpreadsheetRowResponse(rowNumber + 1, responseCells, status, issues));
            }
        }

        AnimalRequest toRequest(Map<String, String> v) {
            boolean isHeifer = isHeifer(v.get("situacaoProdutiva"));
            Integer numeroLactacao = integer(v, "numeroLactacao");
            LocalDate dataInseminacao = date(v, "dataInseminacao");
            StatusReprodutivoAnimal statusReprodutivo = status(v.get("statusReprodutivo"));
            if (isHeifer && (statusReprodutivo == StatusReprodutivoAnimal.NO_AGE
                    || statusReprodutivo == StatusReprodutivoAnimal.PENDING
                    || statusReprodutivo == StatusReprodutivoAnimal.CALF)) {
                statusReprodutivo = dataInseminacao == null
                        ? StatusReprodutivoAnimal.CALF
                        : StatusReprodutivoAnimal.INSEMINATED;
            }
            return new AnimalRequest(
                    UUID.randomUUID().toString(),
                    property.getId(),
                    property.getIdExterno(),
                    null,
                    null,
                    requiredText(v, "codigo"),
                    date(v, "dataNascimento"),
                    isHeifer ? 0 : numeroLactacao == null ? 0 : numeroLactacao,
                    isHeifer ? null : date(v, "dataUltimoParto"),
                    dataInseminacao,
                    blankToNull(v.get("touroIa")),
                    blankToNull(v.get("historicoReprodutivo")),
                    statusReprodutivo,
                    StatusAnimal.ATIVO,
                    null);
        }

        boolean isHeifer(String productiveSituation) {
            String value = normalize(productiveSituation);
            return value.contains("novilha") || value.contains("bezerra");
        }

        String requiredText(Map<String, String> v, String field) {
            String value = v.get(field);
            if (value == null || value.isBlank()) {
                throw invalid(field, "Campo obrigatório vazio");
            }
            return value;
        }

        Integer integer(Map<String, String> v, String field) {
            String text = blankToNull(v.get(field));
            if (text == null) {
                return null;
            }
            try {
                double number = Double.parseDouble(text.replace(',', '.'));
                if (number != Math.rint(number)) {
                    throw new NumberFormatException();
                }
                return (int) number;
            } catch (NumberFormatException e) {
                throw invalid(field, "Informe um número inteiro");
            }
        }

        LocalDate date(Map<String, String> v, String field) {
            String text = blankToNull(v.get(field));
            if (text == null) {
                return null;
            }
            try {
                if (text.matches("\\d+(?:[.,]\\d+)?")) {
                    return DateUtil.getJavaDate(Double.parseDouble(text.replace(',', '.')))
                            .toInstant()
                            .atZone(ZoneId.systemDefault())
                            .toLocalDate();
                }
                for (DateTimeFormatter formatter : FORMATOS_DE_DATA) {
                    try {
                        return LocalDate.parse(text, formatter);
                    } catch (DateTimeParseException ignored) {
                        // tenta o proximo formato
                    }
                }
            } catch (Exception ignored) {
                // cai na mensagem de data invalida abaixo
            }
            throw invalid(field, "Informe uma data válida");
        }

        StatusReprodutivoAnimal status(String value) {
            if (blankToNull(value) == null) {
                return StatusReprodutivoAnimal.PENDING;
            }
            try {
                return StatusReprodutivoAnimal.fromValue(value);
            } catch (Exception e) {
                throw invalid("statusReprodutivo", "Status reprodutivo inválido");
            }
        }

        // O campo vai junto da mensagem para a linha apontar a coluna certa.
        IllegalArgumentException invalid(String field, String message) {
            return new IllegalArgumentException(field + "|" + message);
        }

        int columnFor(String field) {
            return mappings.entrySet().stream()
                    .filter(entry -> entry.getValue().equals(field))
                    .map(Map.Entry::getKey)
                    .findFirst()
                    .orElse(0);
        }
    }

    private static String semMarcadorDeVazio(String value) {
        String text = value == null ? "" : value.trim();
        String lower = text.toLowerCase(Locale.ROOT);
        if (MARCADORES_DE_VAZIO.contains(lower) || lower.startsWith("error:") || lower.startsWith("#")) {
            return "";
        }
        return text;
    }

    /**
     * Celulas com formato de data saem como dd/MM/yyyy a partir do valor numerico do Excel,
     * independente do formato visual (dd/mm/yy, m/d/yy...). Assim o dia e o mes nunca sao
     * reinterpretados. O valor 0 (ou so hora) e tratado como celula vazia.
     */
    private static final class FormatadorDeCelulas extends DataFormatter {
        private static final DateTimeFormatter DATA_BRASILEIRA = DateTimeFormatter.ofPattern("dd/MM/uuuu");

        private FormatadorDeCelulas() {
            super(Locale.forLanguageTag("pt-BR"));
        }

        @Override
        public String formatRawCellContents(double value, int formatIndex, String formatString, boolean use1904Windowing) {
            if (DateUtil.isADateFormat(formatIndex, formatString)) {
                if (value < 1 || !DateUtil.isValidExcelDate(value)) {
                    return "";
                }
                return DateUtil.getLocalDateTime(value, use1904Windowing).toLocalDate().format(DATA_BRASILEIRA);
            }
            return super.formatRawCellContents(value, formatIndex, formatString, use1904Windowing);
        }
    }

    /** Referencia da celula ("AB12") para indice de coluna (base 0). */
    private static int column(String ref) {
        int n = 0;
        for (char c : ref.toCharArray()) {
            if (Character.isLetter(c)) {
                n = n * 26 + (Character.toUpperCase(c) - 'A' + 1);
            } else {
                break;
            }
        }
        return n - 1;
    }

    /** Linha com mais cabecalhos reconhecidos; no empate, a com mais celulas preenchidas. */
    private static int detectHeader(List<List<String>> rows) {
        int best = 0;
        int bestScore = -1;
        int bestCount = -1;
        for (int i = 0; i < rows.size(); i++) {
            int count = (int) rows.get(i).stream().filter(value -> !value.isBlank()).count();
            int score = (int) rows.get(i).stream()
                    .map(AnimalSpreadsheetImportService::fieldForHeader)
                    .filter(Objects::nonNull)
                    .distinct()
                    .count();
            if (score > bestScore || (score == bestScore && count > bestCount)) {
                best = i;
                bestScore = score;
                bestCount = count;
            }
        }
        return best;
    }

    private static String fieldForHeader(String header) {
        String normalized = normalize(header);
        for (var entry : ALIASES.entrySet()) {
            if (entry.getValue().stream().anyMatch(alias -> normalized.equals(alias)
                    || (alias.length() >= 6 && normalized.contains(alias)))) {
                return entry.getKey();
            }
        }
        return null;
    }

    private static Propriedade property(List<Propriedade> properties, Long propertyId) {
        return properties.stream()
                .filter(property -> property.getId().equals(propertyId))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Propriedade não encontrada"));
    }

    private static List<String> tokens(String... values) {
        return Arrays.stream(values).map(AnimalSpreadsheetImportService::normalize).toList();
    }

    private static String normalize(String value) {
        return Textos.semAcentos(value == null ? "" : value)
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9]+", " ")
                .trim()
                .replaceAll("\\s+", " ");
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
