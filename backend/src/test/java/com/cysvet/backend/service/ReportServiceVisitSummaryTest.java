package com.cysvet.backend.service;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.cysvet.backend.dto.visita.VisitaAnimalItemDto;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/**
 * Contagens do resumo do PDF da visita, com casos tirados da visita real da
 * Fazenda Pigosso (03/12/2025).
 */
class ReportServiceVisitSummaryTest {

    private final ReportService reportService = new ReportService(null, null, null, null, null, null);
    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

    private final List<VisitaAnimalItemDto> items = List.of(
            // Inseminada: o app calcula dias de prenhez, mas ainda nao e prenhez confirmada.
            item("46344", "inseminada ST", "cef+pg", 22),
            item("74249", "aguardando dg", "pg", 31),
            item("46346", "prenha", null, 52),
            // "mastite" contem "st", mas nao e protocolo.
            item("133362", "prenha", "mastite 10/09", 192),
            item("173532", "pev", "hipocalcemia+cetose", null),
            item("977940", "vazia", "pg+pg, manca", null),
            item("121665", "em protocolo", null, null)
    );

    @Test
    void pregnancyCountUsesTheRecordedReproductiveStatus() {
        assertEquals(2, reportService.countPregnant(items));
    }

    @Test
    void protocolCountUsesTheRecordedReproductiveStatus() {
        assertEquals(3, reportService.countUnderProtocol(items));
    }

    private VisitaAnimalItemDto item(String codigo, String situacao, String decisao, Integer diasPrenhez) {
        return objectMapper.convertValue(
                Map.of(
                        "animalCodigo", codigo,
                        "situacaoReprodutiva", situacao,
                        "decisao", decisao == null ? "" : decisao,
                        "diasPrenhez", diasPrenhez == null ? "" : diasPrenhez,
                        "diagnostico", decisao == null ? "" : decisao),
                VisitaAnimalItemDto.class);
    }
}
