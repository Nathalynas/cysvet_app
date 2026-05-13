package com.cysvet.backend.dto.auth;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;

@Schema(description = "Resposta de autenticacao contendo tokens e contexto do usuario.")
public record AuthResponse(
        @Schema(description = "Token JWT de acesso.")
        String accessToken,
        @Schema(description = "Token para renovacao de sessao.")
        String refreshToken,
        @Schema(description = "Usuario autenticado.")
        UsuarioAutenticadoResponse user,
        @Schema(description = "Identificador da empresa ativa.", example = "1")
        Long empresaAtivaId,
        @Schema(description = "Empresas permitidas para o usuario autenticado.")
        List<EmpresaPermitidaResponse> empresas
) {
}
