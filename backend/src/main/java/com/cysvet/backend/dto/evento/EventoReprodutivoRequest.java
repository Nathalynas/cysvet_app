package com.cysvet.backend.dto.evento;

import com.cysvet.backend.entity.TipoEventoReprodutivo;
import com.fasterxml.jackson.annotation.JsonAlias;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.time.LocalDate;

@Schema(description = "Payload para cadastro ou atualizacao de um evento reprodutivo.")
public record EventoReprodutivoRequest(
        @Schema(description = "Identificador externo do evento.", example = "evt-001")
        @JsonAlias("id_externo")
        @NotBlank String idExterno,
        @Schema(description = "Identificador interno da propriedade.", example = "10")
        @JsonAlias("id_propriedade")
        Long idPropriedade,
        @Schema(description = "Identificador externo da propriedade.", example = "prop-001")
        @JsonAlias("id_externo_propriedade")
        String idExternoPropriedade,
        @Schema(description = "Identificador interno do animal.", example = "1")
        @JsonAlias("id_animal")
        Long idAnimal,
        @Schema(description = "Identificador externo do animal.", example = "animal-001")
        @JsonAlias("id_externo_animal")
        String idExternoAnimal,
        @Schema(description = "Tipo do evento reprodutivo.")
        @NotNull TipoEventoReprodutivo tipo,
        @Schema(description = "Data do evento.", example = "2026-05-10")
        @JsonAlias("data_evento")
        @NotNull LocalDate dataEvento,
        @Schema(description = "Indica se houve confirmacao de prenhez.", example = "true")
        @JsonAlias("prenhez_confirmada")
        Boolean prenhezConfirmada,
        @Schema(description = "Observacoes adicionais do evento.")
        String observacoes,
        @Schema(description = "Data da ultima atualizacao enviada pelo cliente.", example = "2026-05-12T18:30:00Z")
        @JsonAlias("data_atualizacao_cliente")
        Instant dataAtualizacaoCliente
) {
}
