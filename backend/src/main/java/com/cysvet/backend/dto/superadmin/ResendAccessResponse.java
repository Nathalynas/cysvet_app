package com.cysvet.backend.dto.superadmin;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Resultado do reenvio de acesso ao responsavel.")
public record ResendAccessResponse(
        @Schema(description = "Indica se o e-mail com a nova senha provisoria foi enviado.")
        boolean emailSent
) {
}
