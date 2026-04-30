package com.reprocampo.backend.dto.evento;

import com.reprocampo.backend.entity.TipoEventoReprodutivo;
import java.time.Instant;
import java.time.LocalDate;

public record EventoReprodutivoResponse(
        Long id,
        String idExterno,
        Long idPropriedade,
        String idExternoPropriedade,
        Long idAnimal,
        String idExternoAnimal,
        TipoEventoReprodutivo tipo,
        LocalDate dataEvento,
        LocalDate dataPrevistaParto,
        Boolean prenhezConfirmada,
        String observacoes,
        Instant dataCriacao,
        Instant dataAtualizacao,
        Long versao
) {
}
