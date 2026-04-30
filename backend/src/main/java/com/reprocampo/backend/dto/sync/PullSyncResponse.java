package com.reprocampo.backend.dto.sync;

import java.time.Instant;
import java.util.List;

import com.reprocampo.backend.dto.animal.AnimalResponse;
import com.reprocampo.backend.dto.evento.EventoReprodutivoResponse;
import com.reprocampo.backend.dto.propriedade.PropriedadeResponse;
import com.reprocampo.backend.dto.visita.VisitaResponse;

public record PullSyncResponse(
        Instant serverTime,
        List<PropriedadeResponse> properties,
        List<AnimalResponse> animals,
        List<VisitaResponse> visits,
        List<EventoReprodutivoResponse> events,
        List<RegistroExcluidoResponse> deletedRecords
) {
}
