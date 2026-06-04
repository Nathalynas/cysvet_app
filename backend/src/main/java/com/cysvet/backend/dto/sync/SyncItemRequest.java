package com.cysvet.backend.dto.sync;

import com.cysvet.backend.entity.TipoOperacaoSincronizacao;
import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.databind.JsonNode;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;

@Schema(description = "Item individual enviado no processo de sincronizacao.")
public record SyncItemRequest(
        @Schema(description = "Chave unica da mutacao no cliente.", example = "mut-001")
        @JsonAlias("chave_mutacao")
        @NotBlank String chaveMutacao,
        @Schema(description = "Tipo de operacao realizada pelo cliente.")
        @JsonAlias("operation_type")
        @NotNull TipoOperacaoSincronizacao operationType,
        @Schema(description = "Nome logico da entidade sincronizada.", example = "animal")
        @NotBlank String entity,
        @Schema(description = "Data de atualizacao do item no cliente.", example = "2026-05-12T18:30:00Z")
        @JsonAlias("data_atualizacao_cliente")
        Instant dataAtualizacaoCliente,
        @Schema(description = "Payload bruto da entidade sincronizada.")
        @NotNull JsonNode payload
) {
}
