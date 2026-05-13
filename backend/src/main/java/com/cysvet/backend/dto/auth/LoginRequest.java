package com.cysvet.backend.dto.auth;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

@Schema(description = "Payload para autenticacao de usuario.")
public record LoginRequest(
        @Schema(description = "E-mail do usuario.", example = "joao@cysvet.com")
        @Email @NotBlank String email,
        @Schema(description = "Senha do usuario.", example = "senha123")
        @NotBlank String password
) {
}
