package com.cysvet.backend.dto.dashboard;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Metricas consolidadas exibidas no dashboard.")
public record DashboardResponse(
        @Schema(description = "Quantidade total de propriedades.", example = "12")
        long totalPropriedades,
        @Schema(description = "Quantidade total de animais.", example = "240")
        long totalAnimais,
        @Schema(description = "Quantidade total de eventos.", example = "87")
        long totalEventos,
        @Schema(description = "Taxa de prenhez.", example = "58.3")
        double taxaPrenhez,
        @Schema(description = "Taxa de servico.", example = "66.7")
        double taxaServico,
        @Schema(description = "Media de inseminacoes.", example = "1.8")
        double mediaInseminacoes,
        @Schema(description = "Intervalo medio entre partos.", example = "13.2")
        double intervaloMedioPartos
) {
}
