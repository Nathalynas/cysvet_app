package com.cysvet.backend.dto.propriedade;

import java.time.Instant;

public record PropriedadeResponse(
        Long id,
        String idExterno,
        String nome,
        String nomeProprietario,
        String cidade,
        String estado,
        String observacoes,
        Instant dataCriacao,
        Instant dataAtualizacao,
        Long versao
) {
}
