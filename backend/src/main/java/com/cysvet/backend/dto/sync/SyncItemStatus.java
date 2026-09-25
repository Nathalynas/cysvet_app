package com.cysvet.backend.dto.sync;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Status oficial do processamento de um item de sincronizacao.")
public enum SyncItemStatus {
    SYNCED,
    REPLAYED,
    CONFLICT_SERVER_WINS,
    @Schema(description = "Item recusado por dados invalidos ou referencia inexistente; nada foi aplicado e a chave de mutacao pode ser reenviada.")
    REJECTED
}
