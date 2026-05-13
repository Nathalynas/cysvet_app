package com.cysvet.backend.dto.company;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

@Schema(description = "Payload para atualizacao da empresa ativa do usuario.")
public record UpdateCompanyRequest(
        @Schema(description = "Nome da empresa a ser ativada.", example = "Cysvet Matriz")
        @NotBlank(message = "name e obrigatorio")
        String name,

        @Schema(description = "E-mail da empresa a ser ativada.", example = "contato@cysvet.com")
        @NotBlank(message = "email e obrigatorio")
        @Email(message = "email deve ser valido")
        String email
) {
}
