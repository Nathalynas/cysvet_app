package com.reprocampo.backend.dto.visita;

import java.time.Instant;
import java.time.LocalDate;

public record VisitaResponse(
        Long id,
        String idExterno,
        Long idPropriedade,
        String idExternoPropriedade,
        LocalDate dataVisita,
        String observacoes,
        Instant dataCriacao,
        Instant dataAtualizacao,
        Long versao
) {
}
