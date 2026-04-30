package com.reprocampo.backend.dto.sync;

import com.fasterxml.jackson.databind.JsonNode;
import com.reprocampo.backend.entity.TipoOperacaoSincronizacao;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;

public record SyncItemRequest(
        @NotBlank String chaveMutacao,
        @NotNull TipoOperacaoSincronizacao operationType,
        @NotBlank String entity,
        Instant dataAtualizacaoCliente,
        JsonNode payload
) {
}
