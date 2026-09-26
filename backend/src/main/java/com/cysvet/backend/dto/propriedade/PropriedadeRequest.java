package com.cysvet.backend.dto.propriedade;

import com.cysvet.backend.entity.StatusPropriedade;
import com.fasterxml.jackson.annotation.JsonAlias;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.NotBlank;
import java.time.Instant;

@Schema(description = "Payload para cadastro ou atualizacao de uma propriedade.")
public record PropriedadeRequest(
        @Schema(description = "Identificador externo da propriedade no sistema cliente.", example = "prop-001")
        @JsonAlias("id_externo")
        @Size(max = 64, message = "idExterno deve ter no maximo 64 caracteres") @NotBlank String idExterno,
        @Schema(description = "Nome da propriedade.", example = "Fazenda Boa Vista")
        @Size(max = 255, message = "nome deve ter no maximo 255 caracteres") @NotBlank String nome,
        @Schema(description = "Nome do proprietario.", example = "Maria Souza")
        @JsonAlias("nome_proprietario")
        @Size(max = 255, message = "nomeProprietario deve ter no maximo 255 caracteres") @NotBlank String nomeProprietario,
        @Schema(description = "Contato principal da propriedade.", example = "+55 11 99999-9999")
        @Size(max = 255, message = "contato deve ter no maximo 255 caracteres") String contato,
        @Schema(description = "Cidade da propriedade.", example = "Ribeirao Preto")
        @Size(max = 255, message = "cidade deve ter no maximo 255 caracteres") String cidade,
        @Schema(description = "Estado da propriedade.", example = "SP")
        @Size(max = 255, message = "estado deve ter no maximo 255 caracteres") String estado,
        @Schema(description = "Observacoes adicionais sobre a propriedade.")
        @Size(max = 2000, message = "observacoes deve ter no maximo 2000 caracteres") String observacoes,
        @Schema(description = "Status atual da propriedade.")
        StatusPropriedade status,
        @Schema(description = "Data da ultima atualizacao enviada pelo cliente.", example = "2026-05-12T18:30:00Z")
        @JsonAlias("data_atualizacao_cliente")
        Instant dataAtualizacaoCliente
) {
}
