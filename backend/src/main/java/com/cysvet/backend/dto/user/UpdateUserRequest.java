package com.cysvet.backend.dto.user;

import com.fasterxml.jackson.annotation.JsonAlias;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

@Schema(description = "Payload para atualizar dados de um membro da equipe.")
public record UpdateUserRequest(
        @Schema(description = "Nome do usuario.", example = "Maria Veterinaria")
        @JsonAlias("nome")
        @Size(max = 255, message = "name deve ter no maximo 255 caracteres") @NotBlank String name,
        @Schema(description = "E-mail do usuario.", example = "maria.vet@cysvet.com")
        @Size(max = 255, message = "email deve ter no maximo 255 caracteres") @Email @NotBlank String email
) {
}
