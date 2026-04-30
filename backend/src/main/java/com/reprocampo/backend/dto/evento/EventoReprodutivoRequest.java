package com.reprocampo.backend.dto.evento;

import com.reprocampo.backend.entity.TipoEventoReprodutivo;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.time.LocalDate;

public record EventoReprodutivoRequest(
        @NotBlank String idExterno,
        Long idPropriedade,
        String idExternoPropriedade,
        Long idAnimal,
        String idExternoAnimal,
        @NotNull TipoEventoReprodutivo tipo,
        @NotNull LocalDate dataEvento,
        Boolean prenhezConfirmada,
        String observacoes,
        Instant dataAtualizacaoCliente
) {
}
