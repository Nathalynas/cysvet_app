package com.cysvet.backend.dto.user;

import com.fasterxml.jackson.annotation.JsonAlias;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Schema(description = "Payload para criar um veterinario e vincula-lo a empresa ativa.")
public record CreateUserRequest(
        @Schema(description = "Nome do usuario.", example = "Maria Veterinaria")
        @JsonAlias("nome")
        @NotBlank String name,
        @Schema(description = "E-mail do usuario.", example = "maria.vet@cysvet.com")
        @Email @NotBlank String email,
        @Schema(description = "Senha de acesso do usuario.", example = "senha123")
        @NotBlank @Size(min = 6) String password
) {
}
