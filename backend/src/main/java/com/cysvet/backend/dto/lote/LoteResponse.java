package com.cysvet.backend.dto.lote;

import com.cysvet.backend.entity.StatusLote;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;

@Schema(description = "Dados retornados para um lote.")
public record LoteResponse(
        @Schema(description = "Identificador interno do lote.", example = "1")
        Long id,
        @Schema(description = "Identificador externo do lote.", example = "lote-001")
        String idExterno,
        @Schema(description = "Identificador interno da propriedade vinculada.", example = "10")
        Long idPropriedade,
        @Schema(description = "Identificador externo da propriedade vinculada.", example = "prop-001")
        String idExternoPropriedade,
        @Schema(description = "Nome do lote.", example = "Lote Pre-Parto")
        String nome,
        @Schema(description = "Descricao resumida do lote.")
        String descricao,
        @Schema(description = "Status atual do lote.")
        StatusLote status,
        @Schema(description = "Data de criacao do registro.", example = "2026-05-01T12:00:00Z")
        Instant dataCriacao,
        @Schema(description = "Data da ultima atualizacao.", example = "2026-05-12T18:30:00Z")
        Instant dataAtualizacao,
        @Schema(description = "Versao do registro.", example = "1")
        Long versao
) {
}
