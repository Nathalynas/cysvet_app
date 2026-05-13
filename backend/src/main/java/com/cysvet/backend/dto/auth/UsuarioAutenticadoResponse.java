package com.cysvet.backend.dto.auth;

import com.cysvet.backend.entity.Perfil;
import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Dados do usuario autenticado.")
public record UsuarioAutenticadoResponse(
        @Schema(description = "Identificador do usuario.", example = "1")
        Long id,
        @Schema(description = "Nome do usuario.", example = "Joao Silva")
        String name,
        @Schema(description = "E-mail do usuario.", example = "joao@cysvet.com")
        String email,
        @Schema(description = "Perfil do usuario.")
        Perfil perfil
) {
}
