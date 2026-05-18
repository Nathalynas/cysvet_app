package com.cysvet.backend.dto.visita;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDate;

@Schema(description = "Dados coletados para um animal durante a visita.")
public record VisitaAnimalItemDto(
        @Schema(description = "Identificador interno do animal.", example = "25")
        Long animalId,
        @Schema(description = "Identificador externo do animal.", example = "animal-001")
        String animalIdExterno,
        @Schema(description = "Codigo ou brinco do animal.", example = "46344")
        String animalCodigo,
        @Schema(description = "Categoria do animal.", example = "VACA")
        String animalCategoria,
        @Schema(description = "Idade do animal em meses.", example = "83")
        Integer idadeMeses,
        @Schema(description = "Situacao produtiva observada.", example = "lactante")
        String situacaoProdutiva,
        @Schema(description = "Situacao reprodutiva observada.", example = "inseminada")
        String situacaoReprodutiva,
        @Schema(description = "Decisao ou conduta definida.", example = "ST cef+pg")
        String decisao,
        @Schema(description = "Data da ultima IA.", example = "2025-11-10")
        LocalDate dataUltimaIa,
        @Schema(description = "Numero de IAs recebidas.", example = "1")
        Integer numeroIaRecebida,
        @Schema(description = "Dias de prenhez.", example = "22")
        Integer diasPrenhez,
        @Schema(description = "Diagnostico complementar.", example = "pg")
        String diagnostico,
        @Schema(description = "Dias em lactacao.", example = "76")
        Integer del,
        @Schema(description = "Dias restantes para secagem.", example = "168")
        Integer diasParaSecar,
        @Schema(description = "Data prevista para secagem.", example = "2026-05-19")
        LocalDate previsaoSecagem,
        @Schema(description = "Data pre-parto.", example = "2026-06-20")
        LocalDate dataPreParto,
        @Schema(description = "Data prevista para parto.", example = "2026-07-20")
        LocalDate previsaoParto
) {
}
