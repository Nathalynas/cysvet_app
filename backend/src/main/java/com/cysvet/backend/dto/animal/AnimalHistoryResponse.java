package com.cysvet.backend.dto.animal;

import com.cysvet.backend.dto.evento.EventoReprodutivoResponse;
import com.cysvet.backend.dto.visita.VisitaResponse;
import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;

@Schema(description = "Historico consolidado do animal, incluindo eventos e visitas relacionadas.")
public record AnimalHistoryResponse(
        @Schema(description = "Snapshot atual do animal.")
        AnimalResponse animal,
        @Schema(description = "Eventos reprodutivos relacionados ao animal.")
        List<EventoReprodutivoResponse> eventos,
        @Schema(description = "Visitas da propriedade filtradas para o animal informado.")
        List<VisitaResponse> visitas,
        @Schema(description = "Alteracoes e movimentacoes registradas para o animal.")
        List<AnimalHistoricoResponse> alteracoes
) {
}
