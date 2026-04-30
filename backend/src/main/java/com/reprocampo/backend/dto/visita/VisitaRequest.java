package com.reprocampo.backend.dto.visita;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.time.LocalDate;

public record VisitaRequest(
        @NotBlank String idExterno,
        Long idPropriedade,
        String idExternoPropriedade,
        @NotNull LocalDate dataVisita,
        String observacoes,
        Instant dataAtualizacaoCliente
) {
}
