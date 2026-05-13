package com.cysvet.backend.dto.auth;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Empresa disponivel para o usuario autenticado.")
public record EmpresaPermitidaResponse(
        @Schema(description = "Identificador da empresa.", example = "1")
        Long id,
        @Schema(description = "Nome da empresa.", example = "Cysvet Matriz")
        String name,
        @Schema(description = "E-mail da empresa.", example = "contato@cysvet.com")
        String email
) {
}
