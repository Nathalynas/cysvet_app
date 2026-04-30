package com.reprocampo.backend.dto.propriedade;

import jakarta.validation.constraints.NotBlank;
import java.time.Instant;

public record PropriedadeRequest(
        @NotBlank String idExterno,
        @NotBlank String nome,
        @NotBlank String nomeProprietario,
        String cidade,
        String estado,
        String observacoes,
        Instant dataAtualizacaoCliente
) {
}
