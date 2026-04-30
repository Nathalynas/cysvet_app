package com.cysvet.backend.dto.dashboard;

public record DashboardResponse(
        long totalPropriedades,
        long totalAnimais,
        long totalEventos,
        double taxaPrenhez,
        double taxaServico,
        double mediaInseminacoes,
        double intervaloMedioPartos
) {
}
