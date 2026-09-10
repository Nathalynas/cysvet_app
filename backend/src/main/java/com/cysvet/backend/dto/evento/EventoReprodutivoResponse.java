package com.cysvet.backend.dto.evento;

import com.cysvet.backend.entity.TipoEventoReprodutivo;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Map;

@Schema(description = "Dados retornados para um evento reprodutivo.")
public record EventoReprodutivoResponse(
        @Schema(description = "Identificador interno do evento.", example = "100")
        Long id,
        @Schema(description = "Identificador externo do evento.", example = "evt-001")
        String idExterno,
        @Schema(description = "Identificador interno da propriedade.", example = "10")
        Long idPropriedade,
        @Schema(description = "Identificador externo da propriedade.", example = "prop-001")
        String idExternoPropriedade,
        @Schema(description = "Identificador interno do animal.", example = "1")
        Long idAnimal,
        @Schema(description = "Identificador externo do animal.", example = "animal-001")
        String idExternoAnimal,
        @Schema(description = "Tipo do evento reprodutivo.")
        TipoEventoReprodutivo tipo,
        @Schema(description = "Data do evento.", example = "2026-05-10")
        LocalDate dataEvento,
        @Schema(description = "Data prevista do parto quando aplicavel.", example = "2027-02-15")
        LocalDate dataPrevistaParto,
        @Schema(description = "Indica se houve confirmacao de prenhez.", example = "true")
        Boolean prenhezConfirmada,
        @Schema(description = "Observacoes adicionais do evento.")
        String observacoes,
        @Schema(description = "Detalhes estruturados especificos do evento.")
        Map<String, Object> detalhes,
        @Schema(description = "Data de criacao do registro.", example = "2026-05-01T12:00:00Z")
        Instant dataCriacao,
        @Schema(description = "Data da ultima atualizacao.", example = "2026-05-12T18:30:00Z")
        Instant dataAtualizacao,
        @Schema(description = "Versao do registro.", example = "2")
        Long versao
) {
}
