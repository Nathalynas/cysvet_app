package com.cysvet.backend.dto.auth;

import com.fasterxml.jackson.annotation.JsonAlias;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

@Schema(description = "Payload para invalidacao de refresh token no logout.")
public record LogoutRequest(
        @Schema(description = "Refresh token a ser invalidado.", example = "eyJhbGciOiJIUzI1NiJ9.refresh")
        @JsonAlias("refresh_token")
        @NotBlank String refreshToken
) {
}
