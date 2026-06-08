package com.cysvet.backend.dto.sync;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;
import java.util.Map;

@Schema(description = "Metadados oficiais do contrato offline-first expostos pelo backend.")
public record SyncContractResponse(
        @Schema(description = "Versao do contrato de sincronizacao.", example = "offline-sync-v1")
        String schemaVersion,
        @Schema(description = "Ordem oficial de envio para criacao e atualizacao das entidades.")
        List<String> createUpdateOrder,
        @Schema(description = "Ordem oficial de envio para exclusao das entidades.")
        List<String> deleteOrder,
        @Schema(description = "Colecoes minimas retornadas no pull para reidratacao local.")
        List<String> snapshotCollections,
        @Schema(description = "Politica oficial de conflito no servidor.")
        String conflictPolicy,
        @Schema(description = "Acao esperada do cliente quando houver conflito.")
        String reconciliationPolicy,
        @Schema(description = "Modo de exclusao aplicado por entidade durante a sincronizacao.")
        Map<String, String> deletionModes,
        @Schema(description = "Disponibilidade oficial do dashboard no modo offline.")
        String dashboardMode,
        @Schema(description = "Disponibilidade oficial dos relatorios no modo offline.")
        String reportsMode
) {
}
