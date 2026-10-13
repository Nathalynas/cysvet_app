package com.cysvet.backend.dto.superadmin;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Resultado do cadastro da empresa cliente.")
public record CreateClientCompanyResponse(
        ClientCompanyResponse company,
        @Schema(description = "Indica se o e-mail com a senha provisoria foi enviado.")
        boolean emailSent
) {
}
