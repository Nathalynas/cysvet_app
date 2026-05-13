package com.cysvet.backend.dto.visita;

import com.fasterxml.jackson.annotation.JsonAlias;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.time.LocalDate;

@Schema(description = "Payload para cadastro ou atualizacao de uma visita tecnica.")
public record VisitaRequest(
        @Schema(description = "Identificador externo da visita.", example = "visit-001")
        @JsonAlias("id_externo")
        @NotBlank String idExterno,
        @Schema(description = "Identificador interno da propriedade.", example = "10")
        @JsonAlias("id_propriedade")
        Long idPropriedade,
        @Schema(description = "Identificador externo da propriedade.", example = "prop-001")
        @JsonAlias("id_externo_propriedade")
        String idExternoPropriedade,
        @Schema(description = "Data da visita.", example = "2026-05-12")
        @JsonAlias("data_visita")
        @NotNull LocalDate dataVisita,
        @Schema(description = "Observacoes da visita.")
        String observacoes,
        @Schema(description = "Data da ultima atualizacao enviada pelo cliente.", example = "2026-05-12T18:30:00Z")
        @JsonAlias("data_atualizacao_cliente")
        Instant dataAtualizacaoCliente
) {
}
