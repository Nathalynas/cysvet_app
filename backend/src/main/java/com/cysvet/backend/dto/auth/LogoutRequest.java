package com.cysvet.backend.dto.auth;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotBlank;

public record LogoutRequest(@JsonAlias("refresh_token") @NotBlank String refreshToken) {
}
