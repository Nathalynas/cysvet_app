package com.cysvet.backend.dto.evento;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.cysvet.backend.entity.TipoEventoReprodutivo;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.time.LocalDate;

public record EventoReprodutivoRequest(
        @JsonAlias("id_externo")
        @NotBlank String idExterno,
        @JsonAlias("id_propriedade")
        Long idPropriedade,
        @JsonAlias("id_externo_propriedade")
        String idExternoPropriedade,
        @JsonAlias("id_animal")
        Long idAnimal,
        @JsonAlias("id_externo_animal")
        String idExternoAnimal,
        @NotNull TipoEventoReprodutivo tipo,
        @JsonAlias("data_evento")
        @NotNull LocalDate dataEvento,
        @JsonAlias("prenhez_confirmada")
        Boolean prenhezConfirmada,
        String observacoes,
        @JsonAlias("data_atualizacao_cliente")
        Instant dataAtualizacaoCliente
) {
}
