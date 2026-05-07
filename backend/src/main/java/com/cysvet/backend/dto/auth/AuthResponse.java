package com.cysvet.backend.dto.auth;

public record AuthResponse(
        String accessToken,
        String refreshToken,
        UsuarioAutenticadoResponse user,
        Long empresaAtivaId,
        java.util.List<EmpresaPermitidaResponse> empresas
) {
}
