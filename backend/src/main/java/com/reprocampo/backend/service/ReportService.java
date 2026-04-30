package com.reprocampo.backend.service;

import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.FontFactory;
import com.lowagie.text.Paragraph;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import com.reprocampo.backend.entity.Animal;
import com.reprocampo.backend.entity.Propriedade;
import com.reprocampo.backend.entity.EventoReprodutivo;
import com.reprocampo.backend.entity.Visita;
import com.reprocampo.backend.repository.AnimalRepository;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDate;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ReportService {

    private final PropriedadeService propriedadeService;
    private final AnimalRepository animalRepository;
    private final EventoReprodutivoService eventoReprodutivoService;
    private final DashboardService dashboardService;
    private final UsuarioAutenticadoProvider authenticatedUserProvider;
    private final VisitaService visitService;

    @Transactional(readOnly = true)
    public byte[] generatePdf(Long idPropriedade, LocalDate dataInicio, LocalDate dataFim) {
        Long idUsuario = authenticatedUserProvider.getCurrentUser().getId();
        Propriedade property = propriedadeService.getEntity(idPropriedade, idUsuario);
        List<Animal> animals = animalRepository.findAllByUsuarioIdAndPropriedadeIdOrderByCodigoAsc(idUsuario, idPropriedade);
        List<EventoReprodutivo> events = eventoReprodutivoService.findForProperty(idPropriedade, dataInicio, dataFim);
        var dashboard = dashboardService.getMetrics(idPropriedade, dataInicio, dataFim);

        try (ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            Document document = new Document();
            PdfWriter.getInstance(document, output);
            document.open();

            document.add(new Paragraph("Relatorio Tecnico - ReproCampo", FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16)));
            document.add(new Paragraph("Propriedade: " + property.getNome()));
            document.add(new Paragraph("Periodo: " + formatPeriod(dataInicio, dataFim)));
            document.add(new Paragraph(" "));

            document.add(new Paragraph("Animais atendidos", FontFactory.getFont(FontFactory.HELVETICA_BOLD, 12)));
            PdfPTable animalTable = new PdfPTable(3);
            animalTable.setWidthPercentage(100);
            addCell(animalTable, "Codigo");
            addCell(animalTable, "Categoria");
            addCell(animalTable, "Lactacao");
            for (Animal animal : animals) {
                addCell(animalTable, animal.getCodigo());
                addCell(animalTable, animal.getCategoria());
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
        Long idUsuario = authenticatedUserProvider.getCurrentUser().getId();
        Propriedade property = propriedadeService.getEntity(idPropriedade, idUsuario);
        List<Animal> animals = animalRepository.findAllByUsuarioIdAndPropriedadeIdOrderByCodigoAsc(idUsuario, idPropriedade);
        List<EventoReprodutivo> events = eventoReprodutivoService.findForProperty(idPropriedade, dataInicio, dataFim);
        var dashboard = dashboardService.getMetrics(idPropriedade, dataInicio, dataFim);

        try (XSSFWorkbook workbook = new XSSFWorkbook(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            XSSFSheet animalsSheet = workbook.createSheet("Animais");
            createRow(animalsSheet, 0, "Codigo", "Categoria", "Nascimento", "Lactacao", "Ultimo Parto");
            for (int index = 0; index < animals.size(); index++) {
                Animal animal = animals.get(index);
                createRow(
                        animalsSheet,
                        index + 1,
                        animal.getCodigo(),
                        animal.getCategoria(),
                        animal.getDataNascimento() == null ? "" : animal.getDataNascimento().toString(),
                        String.valueOf(animal.getNumeroLactacao()),
                        animal.getDataUltimoParto() == null ? "" : animal.getDataUltimoParto().toString()
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
        Long idUsuario = authenticatedUserProvider.getCurrentUser().getId();
        Visita visit = visitService.getEntity(visitId, idUsuario);
        return generatePdf(visit.getPropriedade().getId(), visit.getDataVisita(), visit.getDataVisita());
    }

    @Transactional(readOnly = true)
    public byte[] generateVisitExcel(Long visitId) {
        Long idUsuario = authenticatedUserProvider.getCurrentUser().getId();
        Visita visit = visitService.getEntity(visitId, idUsuario);
        return generateExcel(visit.getPropriedade().getId(), visit.getDataVisita(), visit.getDataVisita());
    }

    private void addCell(PdfPTable table, String value) {
        PdfPCell cell = new PdfPCell();
        cell.setPhrase(new Paragraph(value));
        table.addCell(cell);
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
}
