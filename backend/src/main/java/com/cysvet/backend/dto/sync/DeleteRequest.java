package com.cysvet.backend.dto.sync;

import com.fasterxml.jackson.annotation.JsonAlias;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

@Schema(description = "Payload para identificacao de um registro excluido.")
public record DeleteRequest(
        @Schema(description = "Identificador externo do registro excluido.", example = "animal-001")
        @JsonAlias("id_externo")
        @NotBlank String idExterno
) {
}
