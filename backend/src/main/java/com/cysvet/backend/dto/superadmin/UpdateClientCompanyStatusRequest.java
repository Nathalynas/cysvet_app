package com.cysvet.backend.dto.superadmin;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

@Schema(description = "Payload para ativar ou desativar uma empresa cliente.")
public record UpdateClientCompanyStatusRequest(
        @Schema(description = "true para reativar, false para desativar.")
        @NotNull(message = "active e obrigatorio")
        Boolean active
) {
}
