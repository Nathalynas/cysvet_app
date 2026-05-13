package com.cysvet.backend.dto.animal;

import com.cysvet.backend.entity.StatusAnimal;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

@Schema(description = "Payload para atualizacao do status de um animal.")
public record AnimalStatusRequest(
        @Schema(description = "Novo status do animal.")
        @NotNull StatusAnimal status
) {
}
