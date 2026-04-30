package com.cysvet.backend.dto.sync;

import java.time.Instant;
import java.util.List;

import com.cysvet.backend.dto.animal.AnimalResponse;
import com.cysvet.backend.dto.evento.EventoReprodutivoResponse;
import com.cysvet.backend.dto.propriedade.PropriedadeResponse;
import com.cysvet.backend.dto.visita.VisitaResponse;

public record PullSyncResponse(
        Instant serverTime,
        List<PropriedadeResponse> properties,
        List<AnimalResponse> animals,
        List<VisitaResponse> visits,
        List<EventoReprodutivoResponse> events,
        List<RegistroExcluidoResponse> deletedRecords
) {
}
