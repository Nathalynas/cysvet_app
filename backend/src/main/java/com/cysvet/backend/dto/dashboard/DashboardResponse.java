package com.cysvet.backend.dto.dashboard;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDate;
import java.util.List;

@Schema(description = "Metricas consolidadas exibidas no dashboard.")
public record DashboardResponse(
        @Schema(description = "Quantidade total de propriedades.", example = "12")
        long totalPropriedades,
        @Schema(description = "Quantidade total de animais.", example = "240")
        long totalAnimais,
        @Schema(description = "Quantidade de eventos no periodo.", example = "87")
        long totalEventos,
        @Schema(description = "Taxa de prenhez (ciclos de 21 dias): concebidas / aptas. 0 sem dados.",
                example = "0.21")
        double taxaPrenhez,
        @Schema(description = "Taxa de servico (ciclos de 21 dias): servidas / aptas. 0 sem dados.",
                example = "0.55")
        double taxaServico,
        @Schema(description = "Media de inseminacoes por animal inseminado no periodo.", example = "1.8")
        double mediaInseminacoes,
        @Schema(description = "Intervalo medio entre partos, em dias.", example = "400")
        double intervaloMedioPartos,
        @Schema(description = "Taxa de concepcao (ciclos de 21 dias): concebidas / servidas. Nulo sem dados.",
                example = "0.38")
        Double taxaConcepcao,
        @Schema(description = "Concepcao por IA: IAs seguidas de prenhez / IAs do periodo. Nulo sem IAs.",
                example = "0.42")
        Double taxaConcepcaoIa,
        @Schema(description = "Ciclos de 21 dias avaliados no periodo.", example = "17")
        int ciclos,
        @Schema(description = "Soma das vacas aptas em cada ciclo.", example = "1530")
        long aptas,
        @Schema(description = "Soma das vacas servidas em cada ciclo.", example = "840")
        long servidas,
        @Schema(description = "Soma das vacas que conceberam em cada ciclo.", example = "320")
        long concebidas,
        @Schema(description = "Primeiro dia do periodo avaliado.", example = "2025-11-03")
        LocalDate periodoInicio,
        @Schema(description = "Ultimo dia do periodo avaliado.", example = "2026-11-02")
        LocalDate periodoFim,
        @Schema(description = "Taxas por mes dos ultimos 6 meses do periodo.")
        List<PontoMensal> serieMensal
) {

    @Schema(description = "Taxas dos ciclos que comecam no mes. Nulas quando ainda nao ha dados.")
    public record PontoMensal(
            @Schema(example = "2026-10") String mes,
            Double taxaServico,
            Double taxaConcepcao,
            Double taxaPrenhez
    ) {
    }
}
