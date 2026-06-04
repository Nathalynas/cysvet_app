package com.cysvet.backend.dto.lote;

import com.cysvet.backend.entity.StatusLote;
import com.fasterxml.jackson.annotation.JsonAlias;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;
import java.time.Instant;

@Schema(description = "Payload para cadastro ou atualizacao de um lote.")
public record LoteRequest(
        @Schema(description = "Identificador externo do lote no sistema cliente.", example = "lote-001")
        @JsonAlias("id_externo")
        @NotBlank String idExterno,
        @Schema(description = "Identificador interno da propriedade vinculada.", example = "10")
        @JsonAlias("id_propriedade")
        Long idPropriedade,
        @Schema(description = "Identificador externo da propriedade vinculada.", example = "prop-001")
        @JsonAlias("id_externo_propriedade")
        String idExternoPropriedade,
        @Schema(description = "Nome do lote.", example = "Lote Pre-Parto")
        @NotBlank String nome,
        @Schema(description = "Descricao resumida do lote.")
        String descricao,
        @Schema(description = "Status atual do lote.")
        StatusLote status,
        @Schema(description = "Data da ultima atualizacao enviada pelo cliente.", example = "2026-05-12T18:30:00Z")
        @JsonAlias("data_atualizacao_cliente")
        Instant dataAtualizacaoCliente
) {
    @AssertTrue(message = "Lote deve informar idPropriedade ou idExternoPropriedade")
    public boolean hasPropertyReference() {
        return idPropriedade != null || (idExternoPropriedade != null && !idExternoPropriedade.isBlank());
    }
}
