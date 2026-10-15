package com.cysvet.backend.dto.user;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Resultado do reenvio de acesso a um membro da equipe.")
public record ResendUserAccessResponse(
        @Schema(description = "Indica se o e-mail com a nova senha provisoria foi enviado.")
        boolean emailSent
) {
}
