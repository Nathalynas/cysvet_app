package com.cysvet.backend.dto.sync;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;

@Schema(description = "Resultado do processamento dos itens sincronizados.")
public record SyncResponse(
        @Schema(description = "Resultado individual de cada item enviado.")
        List<SyncItemResponse> items
) {
}
