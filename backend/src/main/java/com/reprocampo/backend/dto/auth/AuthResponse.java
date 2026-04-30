package com.reprocampo.backend.dto.auth;

public record AuthResponse(
        String accessToken,
        String refreshToken,
        UsuarioAutenticadoResponse user
) {
}
