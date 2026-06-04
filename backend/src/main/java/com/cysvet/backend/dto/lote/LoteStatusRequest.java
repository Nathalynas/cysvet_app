package com.cysvet.backend.dto.lote;

import com.cysvet.backend.entity.StatusLote;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

@Schema(description = "Payload para atualizacao do status de um lote.")
public record LoteStatusRequest(
        @Schema(description = "Novo status do lote.")
        @NotNull StatusLote status
) {
}
