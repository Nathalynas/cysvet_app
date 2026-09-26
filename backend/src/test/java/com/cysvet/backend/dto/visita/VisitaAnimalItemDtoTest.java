package com.cysvet.backend.dto.visita;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import java.time.LocalDate;
import java.util.Map;
import org.junit.jupiter.api.Test;

class VisitaAnimalItemDtoTest {

    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

    @Test
    void withDataUltimaIaTrocaSoADataDaUltimaIa() {
        VisitaAnimalItemDto item = objectMapper.convertValue(Map.of(
                "animalCodigo", "46344",
                "situacaoReprodutiva", "inseminada",
                "decisao", "ST cef+pg",
                "dataUltimoParto", "2026-03-01",
                "numeroIaRecebida", 2,
                "previsaoParto", "2026-12-10",
                "controleLeiteiroComDesconto", 27.4
        ), VisitaAnimalItemDto.class);

        VisitaAnimalItemDto enriched = item.withDataUltimaIa(LocalDate.of(2026, 3, 3));

        assertEquals(LocalDate.of(2026, 3, 3), enriched.dataUltimaIa());
        assertEquals(item, enriched.withDataUltimaIa(null));
    }
}
