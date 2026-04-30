package com.cysvet.backend.dto.sync;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.databind.JsonNode;
import com.cysvet.backend.entity.TipoOperacaoSincronizacao;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;

public record SyncItemRequest(
        @JsonAlias("chave_mutacao")
        @NotBlank String chaveMutacao,
        @JsonAlias("operation_type")
        @NotNull TipoOperacaoSincronizacao operationType,
        @NotBlank String entity,
        @JsonAlias("data_atualizacao_cliente")
        Instant dataAtualizacaoCliente,
        JsonNode payload
) {
}
