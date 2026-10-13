package com.cysvet.backend.dto.account;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Schema(description = "Payload para troca obrigatoria de senha.")
public record ChangePasswordRequest(
        @Schema(description = "Nova senha (minimo 6 caracteres).", example = "novaSenha1")
        @NotBlank @Size(min = 6) String newPassword
) {
}
