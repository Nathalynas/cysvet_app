package com.cysvet.backend.dto.sync;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;

@Schema(description = "Representa um registro excluido disponivel para sincronizacao.")
public record RegistroExcluidoResponse(
        @Schema(description = "Nome da entidade excluida.", example = "animal")
        String nomeEntidade,
        @Schema(description = "Identificador externo do registro excluido.", example = "animal-001")
        String idExterno,
        @Schema(description = "Data da exclusao registrada.", example = "2026-05-12T18:30:00Z")
        Instant dataExclusao
) {
}
