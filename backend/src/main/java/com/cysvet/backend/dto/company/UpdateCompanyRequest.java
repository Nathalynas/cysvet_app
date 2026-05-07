package com.cysvet.backend.dto.company;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record UpdateCompanyRequest(
        @NotBlank(message = "name e obrigatorio")
        String name,

        @NotBlank(message = "email e obrigatorio")
        @Email(message = "email deve ser valido")
        String email
) {
}
