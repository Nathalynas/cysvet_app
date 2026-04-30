package com.cysvet.backend.dto.auth;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @JsonAlias("nome")
        @NotBlank String name,
        @Email @NotBlank String email,
        @Size(min = 6) String password
) {
}
