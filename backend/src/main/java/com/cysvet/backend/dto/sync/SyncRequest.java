package com.cysvet.backend.dto.sync;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;

@Schema(description = "Payload com itens a serem sincronizados pelo cliente.")
public record SyncRequest(
        @Schema(description = "Itens enviados para sincronizacao.")
        @Valid @NotEmpty List<SyncItemRequest> items
) {
}
