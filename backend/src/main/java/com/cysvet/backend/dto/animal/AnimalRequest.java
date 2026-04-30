package com.cysvet.backend.dto.animal;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.time.LocalDate;

public record AnimalRequest(
        @JsonAlias("id_externo")
        @NotBlank String idExterno,
        @JsonAlias("id_propriedade")
        Long idPropriedade,
        @JsonAlias("id_externo_propriedade")
        String idExternoPropriedade,
        @NotBlank String codigo,
        @NotBlank String categoria,
        @JsonAlias("data_nascimento")
        LocalDate dataNascimento,
        @JsonAlias("numero_lactacao")
        @NotNull Integer numeroLactacao,
        @JsonAlias("data_ultimo_parto")
        LocalDate dataUltimoParto,
        @JsonAlias("historico_reprodutivo")
        String historicoReprodutivo,
        @JsonAlias("data_atualizacao_cliente")
        Instant dataAtualizacaoCliente
) {
}
