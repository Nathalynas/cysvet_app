package com.reprocampo.backend.dto.animal;

import java.time.Instant;
import java.time.LocalDate;

public record AnimalResponse(
        Long id,
        String idExterno,
        Long idPropriedade,
        String idExternoPropriedade,
        String codigo,
        String categoria,
        LocalDate dataNascimento,
        Integer numeroLactacao,
        LocalDate dataUltimoParto,
        Long diasEmLactacao,
        String historicoReprodutivo,
        Instant dataCriacao,
        Instant dataAtualizacao,
        Long versao
) {
}
