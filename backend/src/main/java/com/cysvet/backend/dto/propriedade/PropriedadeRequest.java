package com.cysvet.backend.dto.propriedade;

import com.cysvet.backend.entity.StatusPropriedade;
import com.fasterxml.jackson.annotation.JsonAlias;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import java.time.Instant;

@Schema(description = "Payload para cadastro ou atualizacao de uma propriedade.")
public record PropriedadeRequest(
        @Schema(description = "Identificador externo da propriedade no sistema cliente.", example = "prop-001")
        @JsonAlias("id_externo")
        @NotBlank String idExterno,
        @Schema(description = "Nome da propriedade.", example = "Fazenda Boa Vista")
        @NotBlank String nome,
        @Schema(description = "Nome do proprietario.", example = "Maria Souza")
        @JsonAlias("nome_proprietario")
        @NotBlank String nomeProprietario,
        @Schema(description = "Contato principal da propriedade.", example = "+55 11 99999-9999")
        String contato,
        @Schema(description = "Cidade da propriedade.", example = "Ribeirao Preto")
        String cidade,
        @Schema(description = "Estado da propriedade.", example = "SP")
        String estado,
        @Schema(description = "Observacoes adicionais sobre a propriedade.")
        String observacoes,
        @Schema(description = "Status atual da propriedade.")
        StatusPropriedade status,
        @Schema(description = "Data da ultima atualizacao enviada pelo cliente.", example = "2026-05-12T18:30:00Z")
        @JsonAlias("data_atualizacao_cliente")
        Instant dataAtualizacaoCliente
) {
}
