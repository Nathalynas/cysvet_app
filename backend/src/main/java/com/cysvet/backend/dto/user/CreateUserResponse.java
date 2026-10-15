package com.cysvet.backend.dto.user;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Resultado do cadastro de um membro da equipe.")
public record CreateUserResponse(
        UserResponse user,
        @Schema(description = "Indica se o e-mail com a senha provisoria foi enviado.")
        boolean emailSent,
        @Schema(description = "O e-mail ja tinha conta: ela foi vinculada e continua com a senha atual, sem envio de e-mail.")
        boolean existingAccount
) {
}
