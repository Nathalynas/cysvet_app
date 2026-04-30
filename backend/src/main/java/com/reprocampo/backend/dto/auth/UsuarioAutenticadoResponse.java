package com.reprocampo.backend.dto.auth;

public record UsuarioAutenticadoResponse(
        Long id,
        String name,
        String email
) {
}
