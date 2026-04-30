package com.reprocampo.backend.dto.animal;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.time.LocalDate;

public record AnimalRequest(
        @NotBlank String idExterno,
        Long idPropriedade,
        String idExternoPropriedade,
        @NotBlank String codigo,
        @NotBlank String categoria,
        LocalDate dataNascimento,
        @NotNull Integer numeroLactacao,
        LocalDate dataUltimoParto,
        String historicoReprodutivo,
        Instant dataAtualizacaoCliente
) {
}
