package com.cysvet.backend.dto.propriedade;

import com.cysvet.backend.entity.StatusPropriedade;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

@Schema(description = "Payload para atualizacao do status de uma propriedade.")
public record PropriedadeStatusRequest(
        @Schema(description = "Novo status da propriedade.")
        @NotNull StatusPropriedade status
) {
}
