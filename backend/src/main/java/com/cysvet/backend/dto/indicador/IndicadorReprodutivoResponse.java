package com.cysvet.backend.dto.indicador;

import java.time.Instant;
import java.time.LocalDate;

public record IndicadorReprodutivoResponse(
        Long id,
        Long idPropriedade,
        LocalDate dataReferencia,
        LocalDate dataInicio,
        LocalDate dataFim,
        long totalPropriedades,
        long totalAnimais,
        long totalEventos,
        double taxaPrenhez,
        double taxaServico,
        double mediaInseminacoes,
        double intervaloMedioPartos,
        Instant dataCriacao
) {
}
