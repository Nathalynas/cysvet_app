package com.cysvet.backend.dto.auth;

import com.cysvet.backend.entity.Perfil;

public record UsuarioAutenticadoResponse(
        Long id,
        String name,
        String email,
        Perfil perfil
) {
}
