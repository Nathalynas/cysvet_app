package com.cysvet.backend.dto.propriedade;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotBlank;
import java.time.Instant;

public record PropriedadeRequest(
        @JsonAlias("id_externo")
        @NotBlank String idExterno,
        @NotBlank String nome,
        @JsonAlias("nome_proprietario")
        @NotBlank String nomeProprietario,
        String cidade,
        String estado,
        String observacoes,
        @JsonAlias("data_atualizacao_cliente")
        Instant dataAtualizacaoCliente
) {
}
