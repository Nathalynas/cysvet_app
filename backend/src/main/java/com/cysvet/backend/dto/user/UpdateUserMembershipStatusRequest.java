package com.cysvet.backend.dto.user;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

@Schema(description = "Payload para ativar ou inativar o vinculo do usuario com a empresa ativa.")
public record UpdateUserMembershipStatusRequest(
        @Schema(description = "Novo status do vinculo.", example = "INATIVO")
        @NotNull UserMembershipStatus status
) {
}
