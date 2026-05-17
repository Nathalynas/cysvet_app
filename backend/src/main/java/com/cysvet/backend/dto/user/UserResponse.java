package com.cysvet.backend.dto.user;

import com.cysvet.backend.entity.Perfil;
import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Membro da equipe vinculado a empresa ativa.")
public record UserResponse(
        @Schema(description = "Identificador do usuario.", example = "12")
        Long id,
        @Schema(description = "Nome do usuario.", example = "Maria Veterinaria")
        String name,
        @Schema(description = "E-mail do usuario.", example = "maria.vet@cysvet.com")
        String email,
        @Schema(description = "Perfil do usuario.")
        Perfil perfil,
        @Schema(description = "Identificador da empresa ativa.", example = "1")
        Long companyId,
        @Schema(description = "Nome da empresa ativa.", example = "Cysvet Matriz")
        String companyName,
        @Schema(description = "Status do vinculo do usuario com a empresa ativa.")
        UserMembershipStatus status
) {
}
