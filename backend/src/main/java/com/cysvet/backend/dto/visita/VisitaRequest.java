package com.cysvet.backend.dto.visita;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.time.LocalDate;

public record VisitaRequest(
        @JsonAlias("id_externo")
        @NotBlank String idExterno,
        @JsonAlias("id_propriedade")
        Long idPropriedade,
        @JsonAlias("id_externo_propriedade")
        String idExternoPropriedade,
        @JsonAlias("data_visita")
        @NotNull LocalDate dataVisita,
        String observacoes,
        @JsonAlias("data_atualizacao_cliente")
        Instant dataAtualizacaoCliente
) {
}
