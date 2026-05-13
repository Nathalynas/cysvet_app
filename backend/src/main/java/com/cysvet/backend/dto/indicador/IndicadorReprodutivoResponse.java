package com.cysvet.backend.dto.indicador;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.time.LocalDate;

@Schema(description = "Indicadores reprodutivos consolidados para uma propriedade ou periodo.")
public record IndicadorReprodutivoResponse(
        @Schema(description = "Identificador do snapshot.", example = "5")
        Long id,
        @Schema(description = "Identificador da propriedade.", example = "10")
        Long idPropriedade,
        @Schema(description = "Data de referencia do snapshot.", example = "2026-05-12")
        LocalDate dataReferencia,
        @Schema(description = "Data inicial considerada no calculo.", example = "2026-05-01")
        LocalDate dataInicio,
        @Schema(description = "Data final considerada no calculo.", example = "2026-05-12")
        LocalDate dataFim,
        @Schema(description = "Quantidade total de propriedades avaliadas.", example = "12")
        long totalPropriedades,
        @Schema(description = "Quantidade total de animais avaliados.", example = "240")
        long totalAnimais,
        @Schema(description = "Quantidade total de eventos avaliados.", example = "87")
        long totalEventos,
        @Schema(description = "Taxa de prenhez calculada.", example = "58.3")
        double taxaPrenhez,
        @Schema(description = "Taxa de servico calculada.", example = "66.7")
        double taxaServico,
        @Schema(description = "Media de inseminacoes.", example = "1.8")
        double mediaInseminacoes,
        @Schema(description = "Intervalo medio entre partos.", example = "13.2")
        double intervaloMedioPartos,
        @Schema(description = "Data de criacao do snapshot.", example = "2026-05-12T18:30:00Z")
        Instant dataCriacao
) {
}
