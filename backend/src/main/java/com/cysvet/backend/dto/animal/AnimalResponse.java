package com.cysvet.backend.dto.animal;

import com.cysvet.backend.entity.StatusAnimal;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.time.LocalDate;

@Schema(description = "Dados retornados para um animal.")
public record AnimalResponse(
        @Schema(description = "Identificador interno do animal.", example = "1")
        Long id,
        @Schema(description = "Identificador externo do animal.", example = "animal-001")
        String idExterno,
        @Schema(description = "Identificador da propriedade vinculada.", example = "10")
        Long idPropriedade,
        @Schema(description = "Identificador externo da propriedade vinculada.", example = "prop-001")
        String idExternoPropriedade,
        @Schema(description = "Codigo do animal.", example = "BR-001")
        String codigo,
        @Schema(description = "Categoria zootecnica do animal.", example = "VACA")
        String categoria,
        @Schema(description = "Sexo do animal.", example = "FEMEA")
        String sexo,
        @Schema(description = "Data de nascimento.", example = "2024-01-15")
        LocalDate dataNascimento,
        @Schema(description = "Numero de lactacoes.", example = "2")
        Integer numeroLactacao,
        @Schema(description = "Data do ultimo parto.", example = "2025-03-10")
        LocalDate dataUltimoParto,
        @Schema(description = "Dias em lactacao calculados.", example = "63")
        Long diasEmLactacao,
        @Schema(description = "Historico reprodutivo resumido.")
        String historicoReprodutivo,
        @Schema(description = "Status atual do animal.")
        StatusAnimal status,
        @Schema(description = "Data de criacao do registro.", example = "2026-05-01T12:00:00Z")
        Instant dataCriacao,
        @Schema(description = "Data da ultima atualizacao.", example = "2026-05-12T18:30:00Z")
        Instant dataAtualizacao,
        @Schema(description = "Versao do registro para controle de concorrencia.", example = "3")
        Long versao
) {
}
