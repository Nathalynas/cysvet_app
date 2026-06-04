package com.cysvet.backend.dto.animal;

import com.cysvet.backend.entity.StatusAnimal;
import com.cysvet.backend.entity.StatusReprodutivoAnimal;
import com.fasterxml.jackson.annotation.JsonAlias;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.time.LocalDate;

@Schema(description = "Payload para cadastro ou atualizacao de um animal.")
public record AnimalRequest(
        @Schema(description = "Identificador externo do animal no sistema cliente.", example = "animal-001")
        @JsonAlias("id_externo")
        @NotBlank String idExterno,
        @Schema(description = "Identificador interno da propriedade vinculada.", example = "10")
        @JsonAlias("id_propriedade")
        Long idPropriedade,
        @Schema(description = "Identificador externo da propriedade vinculada.", example = "prop-001")
        @JsonAlias("id_externo_propriedade")
        String idExternoPropriedade,
        @Schema(description = "Identificador interno do lote vinculado.", example = "15")
        @JsonAlias("id_lote")
        Long idLote,
        @Schema(description = "Identificador externo do lote vinculado.", example = "lote-001")
        @JsonAlias("id_externo_lote")
        String idExternoLote,
        @Schema(description = "Codigo do animal.", example = "BR-001")
        @NotBlank String codigo,
        @Schema(description = "Categoria zootecnica do animal.", example = "VACA")
        @NotBlank String categoria,
        @Schema(description = "Sexo do animal.", example = "FEMEA")
        String sexo,
        @Schema(description = "Data de nascimento do animal.", example = "2024-01-15")
        @JsonAlias("data_nascimento")
        LocalDate dataNascimento,
        @Schema(description = "Numero de lactacoes registradas.", example = "2")
        @JsonAlias("numero_lactacao")
        @NotNull Integer numeroLactacao,
        @Schema(description = "Data do ultimo parto.", example = "2025-03-10")
        @JsonAlias("data_ultimo_parto")
        LocalDate dataUltimoParto,
        @Schema(description = "Historico reprodutivo resumido do animal.")
        @JsonAlias("historico_reprodutivo")
        String historicoReprodutivo,
        @Schema(description = "Status reprodutivo atual do animal.")
        @JsonAlias("status_reprodutivo")
        StatusReprodutivoAnimal statusReprodutivo,
        @Schema(description = "Status atual do animal.")
        StatusAnimal status,
        @Schema(description = "Data da ultima atualizacao enviada pelo cliente.", example = "2026-05-12T18:30:00Z")
        @JsonAlias("data_atualizacao_cliente")
        Instant dataAtualizacaoCliente
) {
    @AssertTrue(message = "Animal deve informar idPropriedade ou idExternoPropriedade")
    public boolean hasPropertyReference() {
        return idPropriedade != null || (idExternoPropriedade != null && !idExternoPropriedade.isBlank());
    }
}
