package com.cysvet.backend.dto.sync;

import com.cysvet.backend.dto.animal.AnimalResponse;
import com.cysvet.backend.dto.evento.EventoReprodutivoResponse;
import com.cysvet.backend.dto.propriedade.PropriedadeResponse;
import com.cysvet.backend.dto.visita.VisitaResponse;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.List;

@Schema(description = "Dados disponibilizados pelo servidor para sincronizacao do cliente.")
public record PullSyncResponse(
        @Schema(description = "Horario atual do servidor.", example = "2026-05-12T18:30:00Z")
        Instant serverTime,
        @Schema(description = "Propriedades atualizadas.")
        List<PropriedadeResponse> properties,
        @Schema(description = "Animais atualizados.")
        List<AnimalResponse> animals,
        @Schema(description = "Visitas atualizadas.")
        List<VisitaResponse> visits,
        @Schema(description = "Eventos reprodutivos atualizados.")
        List<EventoReprodutivoResponse> events,
        @Schema(description = "Registros removidos desde a ultima sincronizacao.")
        List<RegistroExcluidoResponse> deletedRecords
) {
}
