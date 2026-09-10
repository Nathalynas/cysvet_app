package com.cysvet.backend.service;

import com.cysvet.backend.dto.visita.VisitaAnimalItemDto;
import com.cysvet.backend.entity.Animal;
import com.cysvet.backend.entity.EventoReprodutivo;
import com.cysvet.backend.entity.Propriedade;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.entity.Visita;
import com.cysvet.backend.repository.AnimalRepository;
import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ReportService {

    private static final DateTimeFormatter SHORT_DATE_FORMAT = DateTimeFormatter.ofPattern("dd/MM/yy");
    private static final DateTimeFormatter FULL_DATE_FORMAT = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    private final PropriedadeService propriedadeService;
    private final AnimalRepository animalRepository;
    private final EventoReprodutivoService eventoReprodutivoService;
    private final DashboardService dashboardService;
    private final UsuarioAutenticadoProvider authenticatedUserProvider;
    private final VisitaService visitService;

    @Transactional(readOnly = true)
    public byte[] generatePdf(Long idPropriedade, LocalDate dataInicio, LocalDate dataFim) {
        Propriedade property = propriedadeService.getEntity(idPropriedade);
        List<Animal> animals = animalRepository.findAllByPropriedadeIdOrderByCodigoAsc(idPropriedade);
        List<EventoReprodutivo> events = eventoReprodutivoService.findForProperty(idPropriedade, dataInicio, dataFim);
        var dashboard = dashboardService.getMetrics(idPropriedade, dataInicio, dataFim);

        try (ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            Document document = new Document();
            PdfWriter.getInstance(document, output);
            document.open();

            document.add(new Paragraph("Relatorio Tecnico - Cysvet", FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16)));
            document.add(new Paragraph("Propriedade: " + property.getNome()));
            document.add(new Paragraph("Periodo: " + formatPeriod(dataInicio, dataFim)));
            document.add(new Paragraph(" "));

            document.add(new Paragraph("Animais atendidos", FontFactory.getFont(FontFactory.HELVETICA_BOLD, 12)));
            PdfPTable animalTable = new PdfPTable(3);
            animalTable.setWidthPercentage(100);
            addCell(animalTable, "Codigo");
            addCell(animalTable, "Touro IA");
            addCell(animalTable, "Lactacao");
            for (Animal animal : animals) {
                addCell(animalTable, animal.getCodigo());
                addCell(animalTable, animal.getTouroIa() == null ? "" : animal.getTouroIa());
                addCell(animalTable, String.valueOf(animal.getNumeroLactacao()));
            }
            document.add(animalTable);
            document.add(new Paragraph(" "));

            document.add(new Paragraph("Eventos registrados", FontFactory.getFont(FontFactory.HELVETICA_BOLD, 12)));
            PdfPTable eventTable = new PdfPTable(4);
            eventTable.setWidthPercentage(100);
            addCell(eventTable, "Animal");
            addCell(eventTable, "Tipo");
            addCell(eventTable, "Data");
            addCell(eventTable, "Observacoes");
            for (EventoReprodutivo event : events) {
                addCell(eventTable, event.getAnimal().getCodigo());
                addCell(eventTable, event.getTipo().name());
                addCell(eventTable, String.valueOf(event.getDataEvento()));
                addCell(eventTable, event.getObservacoes() == null ? "" : event.getObservacoes());
            }
            document.add(eventTable);
            document.add(new Paragraph(" "));

            document.add(new Paragraph("Indicadores", FontFactory.getFont(FontFactory.HELVETICA_BOLD, 12)));
            document.add(new Paragraph("Taxa de prenhez: %.2f%%".formatted(dashboard.taxaPrenhez() * 100)));
            document.add(new Paragraph("Taxa de servico: %.2f%%".formatted(dashboard.taxaServico() * 100)));
            document.add(new Paragraph("Media de inseminacoes: %.2f".formatted(dashboard.mediaInseminacoes())));
            document.add(new Paragraph("Intervalo medio entre partos: %.2f dias".formatted(dashboard.intervaloMedioPartos())));

            document.close();
            return output.toByteArray();
        } catch (DocumentException | IOException exception) {
            throw new IllegalStateException("Falha ao gerar PDF: " + exception.getMessage());
        }
    }

    @Transactional(readOnly = true)
    public byte[] generateExcel(Long idPropriedade, LocalDate dataInicio, LocalDate dataFim) {
        Propriedade property = propriedadeService.getEntity(idPropriedade);
        List<Animal> animals = animalRepository.findAllByPropriedadeIdOrderByCodigoAsc(idPropriedade);
        List<EventoReprodutivo> events = eventoReprodutivoService.findForProperty(idPropriedade, dataInicio, dataFim);
        var dashboard = dashboardService.getMetrics(idPropriedade, dataInicio, dataFim);

        try (XSSFWorkbook workbook = new XSSFWorkbook(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            XSSFSheet animalsSheet = workbook.createSheet("Animais");
            createRow(animalsSheet, 0, "Codigo", "Touro IA", "Nascimento", "Lactacao", "Ultimo Parto", "Data Inseminacao");
            for (int index = 0; index < animals.size(); index++) {
                Animal animal = animals.get(index);
                createRow(
                        animalsSheet,
                        index + 1,
                        animal.getCodigo(),
                        animal.getTouroIa() == null ? "" : animal.getTouroIa(),
                        animal.getDataNascimento() == null ? "" : animal.getDataNascimento().toString(),
                        String.valueOf(animal.getNumeroLactacao()),
                        animal.getDataUltimoParto() == null ? "" : animal.getDataUltimoParto().toString(),
                        animal.getDataInseminacao() == null ? "" : animal.getDataInseminacao().toString()
                );
            }

            XSSFSheet eventsSheet = workbook.createSheet("Eventos");
            createRow(eventsSheet, 0, "Propriedade", "Animal", "Tipo", "Data", "Observacoes");
            for (int index = 0; index < events.size(); index++) {
                EventoReprodutivo event = events.get(index);
                createRow(
                        eventsSheet,
                        index + 1,
                        property.getNome(),
                        event.getAnimal().getCodigo(),
                        event.getTipo().name(),
                        event.getDataEvento().toString(),
                        event.getObservacoes() == null ? "" : event.getObservacoes()
                );
            }

            XSSFSheet dashboardSheet = workbook.createSheet("Indicadores");
            createRow(dashboardSheet, 0, "Indicador", "Valor");
            createRow(dashboardSheet, 1, "Taxa de prenhez", String.valueOf(dashboard.taxaPrenhez()));
            createRow(dashboardSheet, 2, "Taxa de servico", String.valueOf(dashboard.taxaServico()));
            createRow(dashboardSheet, 3, "Media de inseminacoes", String.valueOf(dashboard.mediaInseminacoes()));
            createRow(dashboardSheet, 4, "Intervalo medio entre partos", String.valueOf(dashboard.intervaloMedioPartos()));

            workbook.write(output);
            return output.toByteArray();
        } catch (IOException exception) {
            throw new IllegalStateException("Falha ao gerar planilha: " + exception.getMessage());
        }
    }

    @Transactional(readOnly = true)
    public byte[] generateVisitPdf(Long visitId) {
        Visita visit = visitService.getEntity(visitId);
        List<VisitaAnimalItemDto> items = enrichVisitAnimalItems(visit, visitService.toResponse(visit).animais());

        if (items == null || items.isEmpty()) {
            return generatePdf(visit.getPropriedade().getId(), visit.getDataVisita(), visit.getDataVisita());
        }

        Propriedade property = visit.getPropriedade();
        Usuario currentUser = authenticatedUserProvider.getCurrentUser();
        String veterinarianName = visit.getUsuario() != null && visit.getUsuario().getNome() != null
                ? visit.getUsuario().getNome()
                : currentUser.getNome();

        try (ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            Rectangle pageSize = PageSize.A4.rotate();
            Document document = new Document(pageSize, 18, 18, 18, 18);
            PdfWriter.getInstance(document, output);
            document.open();

            addVisitHeader(document, property, visit, veterinarianName);
            document.add(new Paragraph(" "));
            document.add(sectionTitle("Resumo da visita"));
            document.add(buildVisitSummaryTable(items));
            document.add(new Paragraph(" "));
            document.add(sectionTitle("Proximos passos"));
            document.add(buildVisitNextStepsTable(items));
            document.add(new Paragraph(" "));
            document.add(sectionTitle("Procedimentos e condutas"));
            document.add(buildVisitProcedureTable(items));
            document.add(new Paragraph(" "));
            document.add(sectionTitle("Animais com retorno clinico"));
            document.add(buildVisitOutcomeTable(items));

            if (visit.getObservacoes() != null && !visit.getObservacoes().isBlank()) {
                document.add(new Paragraph(" "));
                document.add(sectionTitle("Observacoes gerais"));
                document.add(buildObservationBlock(visit.getObservacoes()));
            }

            document.close();
            return output.toByteArray();
        } catch (DocumentException | IOException exception) {
            throw new IllegalStateException("Falha ao gerar PDF da visita: " + exception.getMessage(), exception);
        }
    }

    @Transactional(readOnly = true)
    public byte[] generateVisitExcel(Long visitId) {
        Visita visit = visitService.getEntity(visitId);
        return generateExcel(visit.getPropriedade().getId(), visit.getDataVisita(), visit.getDataVisita());
    }

    private List<VisitaAnimalItemDto> enrichVisitAnimalItems(Visita visit, List<VisitaAnimalItemDto> items) {
        if (items == null || items.isEmpty()) {
            return items;
        }

        List<Animal> animals = animalRepository.findAllByPropriedadeIdOrderByCodigoAsc(visit.getPropriedade().getId());
        Map<Long, Animal> animalsById = new HashMap<>();
        Map<String, Animal> animalsByExternalId = new HashMap<>();
        Map<String, Animal> animalsByCode = new HashMap<>();

        for (Animal animal : animals) {
            animalsById.put(animal.getId(), animal);
            if (animal.getIdExterno() != null && !animal.getIdExterno().isBlank()) {
                animalsByExternalId.put(animal.getIdExterno().trim(), animal);
            }
            if (animal.getCodigo() != null && !animal.getCodigo().isBlank()) {
                animalsByCode.put(animal.getCodigo().trim(), animal);
            }
        }

        return items.stream()
                .map(item -> {
                    if (item.dataUltimaIa() != null) {
                        return item;
                    }

                    Animal animal = resolveAnimalSnapshot(item, animalsById, animalsByExternalId, animalsByCode);
                    if (animal == null || animal.getDataInseminacao() == null) {
                        return item;
                    }

                    return new VisitaAnimalItemDto(
                            item.animalId(),
                            item.animalIdExterno(),
                            item.animalCodigo(),
                            item.animalCategoria(),
                            item.idadeMeses(),
                            item.dataNascimento(),
                            item.situacaoProdutiva(),
                            item.situacaoReprodutiva(),
                            item.decisao(),
                            item.dataPrimeiroParto(),
                            item.dataUltimoParto(),
                            item.dataPartoAnterior(),
                            item.numeroPartos(),
                            item.dataPrimeiraIa(),
                            item.dataSegundaIa(),
                            item.dataTerceiraIa(),
                            item.dataQuartaIa(),
                            item.dataQuintaIa(),
                            animal.getDataInseminacao(),
                            item.numeroIaRecebida(),
                            item.dataSecagemEfetiva(),
                            item.entradaPreParto(),
                            item.controleLeiteiro(),
                            item.diasPrenhez(),
                            item.diagnostico(),
                            item.del(),
                            item.idadePrimeiroPartoMeses(),
                            item.idadePrimeiraIa(),
                            item.mesParto(),
                            item.anoUltimoParto(),
                            item.iepAtual(),
                            item.classificacaoPartos(),
                            item.vacaApta(),
                            item.intervalo1e2Ia(),
                            item.intervalo2e3Ia(),
                            item.intervalo3e4Ia(),
                            item.intervalo4e5Ia(),
                            item.mediaIntervaloIa(),
                            item.previsaoRetornoCio(),
                            item.delPrimeiraIa(),
                            item.periodoServico(),
                            item.diasParaSecar(),
                            item.previsaoSecagem(),
                            item.mesSecagem(),
                            item.diferencaSecagem(),
                            item.periodoLactacao(),
                            item.dataPreParto(),
                            item.mesPreParto(),
                            item.duracaoPreParto(),
                            item.previsaoParto(),
                            item.mesPrevistoParto(),
                            item.iepProjetado(),
                            item.controleLeiteiroComDesconto()
                    );
                })
                .toList();
    }

    private Animal resolveAnimalSnapshot(
            VisitaAnimalItemDto item,
            Map<Long, Animal> animalsById,
            Map<String, Animal> animalsByExternalId,
            Map<String, Animal> animalsByCode
    ) {
        if (item.animalId() != null && animalsById.containsKey(item.animalId())) {
            return animalsById.get(item.animalId());
        }
        if (item.animalIdExterno() != null && !item.animalIdExterno().isBlank()) {
            Animal animal = animalsByExternalId.get(item.animalIdExterno().trim());
            if (animal != null) {
                return animal;
            }
        }
        if (item.animalCodigo() != null && !item.animalCodigo().isBlank()) {
            return animalsByCode.get(item.animalCodigo().trim());
        }
        return null;
    }

    private void addCell(PdfPTable table, String value) {
        PdfPCell cell = new PdfPCell();
        cell.setPhrase(new Paragraph(value));
        table.addCell(cell);
    }

    private void addVisitHeader(Document document, Propriedade property, Visita visit, String veterinarianName) throws DocumentException {
        Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 15);
        Font subtitleFont = FontFactory.getFont(FontFactory.HELVETICA, 9, new Color(75, 85, 99));
        Font infoLabelFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 9);
        Font infoValueFont = FontFactory.getFont(FontFactory.HELVETICA, 9);

        document.add(new Paragraph("Relatorio de Visita Tecnica", titleFont));
        document.add(new Paragraph("Resumo operacional da visita e das condutas registradas", subtitleFont));

        PdfPTable infoTable = new PdfPTable(new float[]{1.25f, 2.1f, 1.05f, 1.5f, 1.1f, 1.9f});
        infoTable.setWidthPercentage(100);
        infoTable.setSpacingBefore(6);

        addInfoCell(infoTable, "Fazenda", infoLabelFont, true);
        addInfoCell(infoTable, safe(property.getNome()), infoValueFont, false);
        addInfoCell(infoTable, "Data", infoLabelFont, true);
        addInfoCell(infoTable, formatDateShort(visit.getDataVisita()), infoValueFont, false);
        addInfoCell(infoTable, "Med.Vet", infoLabelFont, true);
        addInfoCell(infoTable, safe(veterinarianName), infoValueFont, false);

        addInfoCell(infoTable, "Proprietario", infoLabelFont, true);
        addInfoCell(infoTable, safe(property.getNomeProprietario()), infoValueFont, false);
        addInfoCell(infoTable, "Cidade", infoLabelFont, true);
        addInfoCell(infoTable, safe(property.getCidade()), infoValueFont, false);
        addInfoCell(infoTable, "Contato", infoLabelFont, true);
        addInfoCell(infoTable, safe(property.getContato()), infoValueFont, false);

        document.add(infoTable);
    }

    private Paragraph sectionTitle(String value) {
        Paragraph title = new Paragraph(value, FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10));
        title.setSpacingAfter(6);
        return title;
    }

    private PdfPTable buildVisitSummaryTable(List<VisitaAnimalItemDto> items) {
        List<VisitMetric> metrics = List.of(
                new VisitMetric("Animais avaliados", String.valueOf(items.size())),
                new VisitMetric("Prenhez confirmada", String.valueOf(countPregnant(items))),
                new VisitMetric("Em protocolo/IA", String.valueOf(countUnderProtocol(items))),
                new VisitMetric("Com previsao de parto", String.valueOf(countWithCalvingForecast(items)))
        );
        PdfPTable table = new PdfPTable(new float[]{1f, 1f, 1f, 1f});
        table.setWidthPercentage(100);
        table.setSpacingBefore(4);

        Font labelFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 8, new Color(53, 92, 125));
        Font valueFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 12);

        for (VisitMetric metric : metrics) {
            PdfPCell cell = new PdfPCell();
            cell.setPadding(8);
            cell.setBorderColor(new Color(196, 201, 208));
            cell.setBackgroundColor(new Color(246, 249, 252));
            cell.addElement(new Paragraph(metric.label(), labelFont));
            cell.addElement(new Paragraph(metric.value(), valueFont));
            table.addCell(cell);
        }

        return table;
    }

    private PdfPTable buildVisitNextStepsTable(List<VisitaAnimalItemDto> items) {
        PdfPTable table = createSectionTable(new float[]{1.2f, 1f, 3.1f});
        Font headerFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 7, Color.WHITE);
        Font cellFont = FontFactory.getFont(FontFactory.HELVETICA, 8);
        Color headerColor = new Color(53, 92, 125);

        addHeaderCell(table, "Data", headerFont, headerColor);
        addHeaderCell(table, "Animal", headerFont, headerColor);
        addHeaderCell(table, "Acao", headerFont, headerColor);

        List<VisitStep> steps = buildVisitSteps(items);
        if (steps.isEmpty()) {
            addEmptyRow(table, 3, "Nenhum proximo passo calculado para esta visita.");
            return table;
        }

        for (VisitStep step : steps) {
            addBodyCell(table, formatDateFull(step.date()), cellFont);
            addBodyCell(table, safe(step.animalCode()), cellFont);
            addBodyCell(table, safe(step.action()), cellFont);
        }

        return table;
    }

    private PdfPTable buildVisitProcedureTable(List<VisitaAnimalItemDto> items) {
        PdfPTable table = createSectionTable(new float[]{1.1f, 1.1f, 1.35f, 2.1f, 1.2f});
        Font headerFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 7, Color.WHITE);
        Font cellFont = FontFactory.getFont(FontFactory.HELVETICA, 7);
        Color headerColor = new Color(53, 92, 125);

        addHeaderCell(table, "Animal", headerFont, headerColor);
        addHeaderCell(table, "Produtiva", headerFont, headerColor);
        addHeaderCell(table, "Reprodutiva", headerFont, headerColor);
        addHeaderCell(table, "Decisao", headerFont, headerColor);
        addHeaderCell(table, "Diagnostico", headerFont, headerColor);

        items.stream()
                .sorted(Comparator
                        .comparing((VisitaAnimalItemDto item) -> productiveStatusOrder(item.situacaoProdutiva()))
                        .thenComparing(item -> safe(item.animalCodigo())))
                .forEach(item -> {
                    addBodyCell(table, safe(item.animalCodigo()), cellFont);
                    addBodyCell(table, safe(item.situacaoProdutiva()), cellFont);
                    addBodyCell(table, safe(item.situacaoReprodutiva()), cellFont);
                    addBodyCell(table, safe(item.decisao()), cellFont);
                    addBodyCell(table, safe(item.diagnostico()), cellFont);
                });

        return table;
    }

    private PdfPTable buildVisitOutcomeTable(List<VisitaAnimalItemDto> items) {
        PdfPTable table = createSectionTable(new float[]{1.1f, 1.05f, 1.1f, 0.9f, 1.15f, 1.15f});
        Font headerFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 7, Color.WHITE);
        Font cellFont = FontFactory.getFont(FontFactory.HELVETICA, 7);
        Color headerColor = new Color(53, 92, 125);

        addHeaderCell(table, "Animal", headerFont, headerColor);
        addHeaderCell(table, "Categoria", headerFont, headerColor);
        addHeaderCell(table, "Ultima IA", headerFont, headerColor);
        addHeaderCell(table, "Prenhez", headerFont, headerColor);
        addHeaderCell(table, "Prev. secagem", headerFont, headerColor);
        addHeaderCell(table, "Prev. parto", headerFont, headerColor);

        List<VisitaAnimalItemDto> filtered = items.stream()
                .filter(this::hasOutcomeData)
                .sorted(Comparator.comparing(item -> safe(item.animalCodigo())))
                .toList();

        if (filtered.isEmpty()) {
            addEmptyRow(table, 6, "Nenhum retorno clinico relevante registrado.");
            return table;
        }

        for (VisitaAnimalItemDto item : filtered) {
            addBodyCell(table, safe(item.animalCodigo()), cellFont);
            addBodyCell(table, safe(item.animalCategoria()), cellFont);
            addBodyCell(table, formatDateFull(item.dataUltimaIa()), cellFont);
            addBodyCell(table, item.diasPrenhez() == null ? safe(item.diagnostico()) : formatInteger(item.diasPrenhez()) + " dias", cellFont);
            addBodyCell(table, formatDateFull(item.previsaoSecagem()), cellFont);
            addBodyCell(table, formatDateFull(item.previsaoParto()), cellFont);
        }

        return table;
    }

    private PdfPTable buildObservationBlock(String value) {
        Font font = FontFactory.getFont(FontFactory.HELVETICA, 9);
        PdfPCell cell = new PdfPCell(new Phrase(value, font));
        cell.setPadding(8);
        cell.setBorderColor(new Color(196, 201, 208));
        cell.setBackgroundColor(new Color(250, 251, 253));
        PdfPTable table = new PdfPTable(1);
        table.setWidthPercentage(100);
        table.addCell(cell);
        return table;
    }

    private PdfPTable createSectionTable(float[] widths) {
        PdfPTable table = new PdfPTable(widths);
        table.setWidthPercentage(100);
        table.setHeaderRows(1);
        table.setSpacingBefore(4);
        return table;
    }

    private void addInfoCell(PdfPTable table, String value, Font font, boolean shaded) {
        PdfPCell cell = new PdfPCell(new Phrase(value, font));
        cell.setPadding(6);
        cell.setBorderColor(new Color(180, 187, 194));
        if (shaded) {
            cell.setBackgroundColor(new Color(236, 240, 244));
        }
        table.addCell(cell);
    }

    private void addHeaderCell(PdfPTable table, String value, Font font, Color background) {
        PdfPCell cell = new PdfPCell(new Phrase(value, font));
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        cell.setPadding(5);
        cell.setBackgroundColor(background);
        cell.setBorderColor(new Color(53, 92, 125));
        table.addCell(cell);
    }

    private void addBodyCell(PdfPTable table, String value, Font font) {
        PdfPCell cell = new PdfPCell(new Phrase(value, font));
        cell.setPadding(4);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        cell.setBorderColor(new Color(196, 201, 208));
        table.addCell(cell);
    }

    private void addEmptyRow(PdfPTable table, int colspan, String message) {
        Font font = FontFactory.getFont(FontFactory.HELVETICA_OBLIQUE, 8);
        PdfPCell cell = new PdfPCell(new Phrase(message, font));
        cell.setColspan(colspan);
        cell.setPadding(8);
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        cell.setBorderColor(new Color(196, 201, 208));
        table.addCell(cell);
    }

    private List<VisitStep> buildVisitSteps(List<VisitaAnimalItemDto> items) {
        List<VisitStep> steps = new ArrayList<>();
        for (VisitaAnimalItemDto item : items) {
            if (item.previsaoSecagem() != null) {
                steps.add(new VisitStep(item.previsaoSecagem(), safe(item.animalCodigo()), "Secagem prevista"));
            }
            if (item.dataPreParto() != null) {
                steps.add(new VisitStep(item.dataPreParto(), safe(item.animalCodigo()), "Entrada em pre-parto"));
            }
            if (item.previsaoParto() != null) {
                steps.add(new VisitStep(item.previsaoParto(), safe(item.animalCodigo()), "Parto previsto"));
            }
            if (item.previsaoRetornoCio() != null) {
                steps.add(new VisitStep(item.previsaoRetornoCio(), safe(item.animalCodigo()), "Retorno de cio previsto"));
            }
        }
        return steps.stream()
                .sorted(Comparator.comparing(VisitStep::date).thenComparing(VisitStep::animalCode))
                .toList();
    }

    private int countPregnant(List<VisitaAnimalItemDto> items) {
        return (int) items.stream()
                .filter(item -> item.diasPrenhez() != null || containsKeyword(item.diagnostico(), "pg"))
                .count();
    }

    private int countUnderProtocol(List<VisitaAnimalItemDto> items) {
        return (int) items.stream()
                .filter(item -> containsKeyword(item.situacaoReprodutiva(), "insemin")
                        || containsKeyword(item.decisao(), "st")
                        || containsKeyword(item.decisao(), "iatf"))
                .count();
    }

    private int countWithCalvingForecast(List<VisitaAnimalItemDto> items) {
        return (int) items.stream().filter(item -> item.previsaoParto() != null).count();
    }

    private boolean hasOutcomeData(VisitaAnimalItemDto item) {
        return item.dataUltimaIa() != null
                || item.diasPrenhez() != null
                || item.previsaoSecagem() != null
                || item.previsaoParto() != null
                || (item.diagnostico() != null && !item.diagnostico().isBlank());
    }

    private boolean containsKeyword(String value, String token) {
        return value != null && value.toLowerCase(Locale.ROOT).contains(token);
    }

    private void createRow(XSSFSheet sheet, int rowIndex, String... values) {
        Row row = sheet.createRow(rowIndex);
        for (int index = 0; index < values.length; index++) {
            row.createCell(index).setCellValue(values[index]);
        }
    }

    private String formatPeriod(LocalDate dataInicio, LocalDate dataFim) {
        if (dataInicio == null || dataFim == null) {
            return "Todo o historico";
        }
        return dataInicio + " a " + dataFim;
    }

    private String formatDateShort(LocalDate date) {
        return date == null ? "" : SHORT_DATE_FORMAT.format(date);
    }

    private String formatDateFull(LocalDate date) {
        return date == null ? "" : FULL_DATE_FORMAT.format(date);
    }

    private String formatInteger(Integer value) {
        return value == null ? "" : String.valueOf(value);
    }

    private String safe(String value) {
        return value == null ? "" : value;
    }

    private int productiveStatusOrder(String value) {
        if (value == null) {
            return 99;
        }

        return switch (value.trim().toLowerCase(Locale.ROOT)) {
            case "lactante" -> 0;
            case "novilha" -> 1;
            case "seca" -> 2;
            default -> 3;
        };
    }

    private record VisitMetric(String label, String value) {
    }

    private record VisitStep(LocalDate date, String animalCode, String action) {
    }
}
