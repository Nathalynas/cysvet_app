package com.cysvet.backend.dto.auth;

import com.fasterxml.jackson.annotation.JsonAlias;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

@Schema(description = "Payload para renovacao de token de acesso.")
public record TokenRefreshRequest(
        @Schema(description = "Refresh token valido.", example = "eyJhbGciOiJIUzI1NiJ9.refresh")
        @JsonAlias("refresh_token")
        @NotBlank String refreshToken
) {
}
