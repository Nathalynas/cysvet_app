package com.cysvet.backend.dto.sync;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;

@Schema(description = "Resultado do processamento de um item de sincronizacao.")
public record SyncItemResponse(
        @Schema(description = "Chave da mutacao processada.", example = "mut-001")
        String chaveMutacao,
        @Schema(description = "Status do processamento.", example = "SYNCED")
        SyncItemStatus status,
        @Schema(description = "Identificador interno gerado ou encontrado.", example = "10")
        Long idEntidade,
        @Schema(description = "Identificador externo associado ao registro.", example = "animal-001")
        String idExterno,
        @Schema(description = "Data da versao do servidor associada ao resultado, quando aplicavel.", example = "2026-06-08T18:30:00Z")
        Instant serverUpdatedAt,
        @Schema(description = "Mensagem complementar do processamento.")
        String message
) {
}
