package com.cysvet.backend.dto.visita;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

@Schema(description = "Dados retornados para uma visita tecnica.")
public record VisitaResponse(
        @Schema(description = "Identificador interno da visita.", example = "15")
        Long id,
        @Schema(description = "Identificador externo da visita.", example = "visit-001")
        String idExterno,
        @Schema(description = "Identificador interno da propriedade.", example = "10")
        Long idPropriedade,
        @Schema(description = "Identificador externo da propriedade.", example = "prop-001")
        String idExternoPropriedade,
        @Schema(description = "Identificador interno do usuario responsavel pela visita.", example = "8")
        Long idUsuario,
        @Schema(description = "Nome do usuario responsavel pela visita.", example = "Dr. Rafael")
        String nomeUsuario,
        @Schema(description = "Data da visita.", example = "2026-05-12")
        LocalDate dataVisita,
        @Schema(description = "Observacoes da visita.")
        String observacoes,
        @Schema(description = "Lista de animais avaliados na visita.")
        List<VisitaAnimalItemDto> animais,
        @Schema(description = "Data de criacao do registro.", example = "2026-05-01T12:00:00Z")
        Instant dataCriacao,
        @Schema(description = "Data da ultima atualizacao.", example = "2026-05-12T18:30:00Z")
        Instant dataAtualizacao,
        @Schema(description = "Versao do registro.", example = "1")
        Long versao
) {
}
