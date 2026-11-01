package com.cysvet.backend.dto.account;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;

@Schema(description = "Preferencias do usuario autenticado.")
public record AccountPreferences(
        @Schema(description = "Situacoes reprodutivas mostradas como atalho na visita, na ordem. "
                + "Nulo no envio volta ao padrao.", example = "[\"prenha\", \"vazia\"]")
        List<String> atalhosSituacaoReprodutiva,

        @Schema(description = "Na resposta: true quando os atalhos sao os padrao (nada escolhido).")
        Boolean atalhosPadrao
) {
}
