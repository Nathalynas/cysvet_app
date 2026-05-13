package com.cysvet.backend.dto.auth;

import com.fasterxml.jackson.annotation.JsonAlias;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Schema(description = "Payload para cadastro de usuario.")
public record RegisterRequest(
        @Schema(description = "Nome do usuario.", example = "Joao Silva")
        @JsonAlias("nome")
        @NotBlank String name,
        @Schema(description = "E-mail do usuario.", example = "joao@cysvet.com")
        @Email @NotBlank String email,
        @Schema(description = "Senha do usuario.", example = "senha123")
        @Size(min = 6) String password
) {
}
