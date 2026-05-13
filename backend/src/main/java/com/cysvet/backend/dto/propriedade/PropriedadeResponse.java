package com.cysvet.backend.dto.propriedade;

import com.cysvet.backend.entity.StatusPropriedade;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;

@Schema(description = "Dados retornados para uma propriedade.")
public record PropriedadeResponse(
        @Schema(description = "Identificador interno da propriedade.", example = "10")
        Long id,
        @Schema(description = "Identificador externo da propriedade.", example = "prop-001")
        String idExterno,
        @Schema(description = "Nome da propriedade.", example = "Fazenda Boa Vista")
        String nome,
        @Schema(description = "Nome do proprietario.", example = "Maria Souza")
        String nomeProprietario,
        @Schema(description = "Contato principal.", example = "+55 11 99999-9999")
        String contato,
        @Schema(description = "Cidade da propriedade.", example = "Ribeirao Preto")
        String cidade,
        @Schema(description = "Estado da propriedade.", example = "SP")
        String estado,
        @Schema(description = "Observacoes adicionais.")
        String observacoes,
        @Schema(description = "Status atual da propriedade.")
        StatusPropriedade status,
        @Schema(description = "Data de criacao do registro.", example = "2026-05-01T12:00:00Z")
        Instant dataCriacao,
        @Schema(description = "Data da ultima atualizacao.", example = "2026-05-12T18:30:00Z")
        Instant dataAtualizacao,
        @Schema(description = "Versao do registro.", example = "4")
        Long versao
) {
}
