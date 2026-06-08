package com.cysvet.backend.dto.auth;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;

@Schema(description = "Politica de restauracao e revalidacao da sessao para uso offline.")
public record SessionPolicyResponse(
        @Schema(description = "Momento exato de expiracao do access token.", example = "2026-06-08T18:30:00Z")
        Instant accessTokenExpiresAt,
        @Schema(description = "Momento exato de expiracao do refresh token.", example = "2026-06-15T18:30:00Z")
        Instant refreshTokenExpiresAt,
        @Schema(description = "Regra oficial para restaurar sessao localmente.")
        String sessionRestorePolicy,
        @Schema(description = "Regra oficial para revalidar a sessao apos expirar o access token.")
        String tokenRefreshPolicy
) {
}
