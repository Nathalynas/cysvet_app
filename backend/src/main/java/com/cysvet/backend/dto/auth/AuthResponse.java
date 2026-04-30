package com.cysvet.backend.dto.auth;

public record AuthResponse(
        String accessToken,
        String refreshToken,
        UsuarioAutenticadoResponse user
) {
}
