package com.cysvet.backend.service;

import com.cysvet.backend.dto.animal.AnimalHistoryResponse;
import com.cysvet.backend.dto.animal.AnimalHistoricoResponse;
import com.cysvet.backend.dto.animal.AnimalResponse;
import com.cysvet.backend.dto.evento.EventoReprodutivoResponse;
import com.cysvet.backend.dto.visita.VisitaAnimalItemDto;
import com.cysvet.backend.dto.visita.VisitaResponse;
import com.cysvet.backend.entity.Animal;
import com.cysvet.backend.entity.Visita;
import com.cysvet.backend.repository.VisitaRepository;
import com.cysvet.backend.repository.AnimalHistoricoRepository;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AnimalHistoryService {

    private final AnimalService animalService;
    private final EventoReprodutivoService eventoReprodutivoService;
    private final VisitaRepository visitaRepository;
    private final VisitaService visitaService;
    private final AnimalHistoricoRepository animalHistoricoRepository;

    @Transactional(readOnly = true)
    public AnimalHistoryResponse getHistory(Long animalId) {
        Animal animal = animalService.getEntity(animalId);
        AnimalResponse animalResponse = animalService.toResponse(animal);
        List<EventoReprodutivoResponse> eventos = eventoReprodutivoService.list(null, animalId);
        List<VisitaResponse> visitas = visitaRepository.findAllByPropriedadeIdOrderByDataVisitaDesc(animal.getPropriedade().getId())
                .stream()
                .map(visita -> filterVisitForAnimal(visita, animal))
                .filter(item -> item != null)
                .toList();
        List<AnimalHistoricoResponse> alteracoes = animalHistoricoRepository
                .findAllByAnimalIdOrderByDataCriacaoDesc(animalId)
                .stream()
                .map(item -> new AnimalHistoricoResponse(
                        item.getTipo(),
                        item.getDescricao(),
                        item.getUsuario().getNome(),
                        item.getDataCriacao()))
                .toList();

        return new AnimalHistoryResponse(animalResponse, eventos, visitas, alteracoes);
    }

    private VisitaResponse filterVisitForAnimal(Visita visita, Animal animal) {
        VisitaResponse response = visitaService.toResponse(visita);
        List<VisitaAnimalItemDto> itens = response.animais().stream()
                .filter(item -> itemBelongsToAnimal(item, animal))
                .toList();

        if (itens.isEmpty()) {
            return null;
        }

        return new VisitaResponse(
                response.id(),
                response.idExterno(),
                response.idPropriedade(),
                response.idExternoPropriedade(),
                response.idUsuario(),
                response.nomeUsuario(),
                response.dataVisita(),
                response.observacoes(),
                itens,
                response.dataCriacao(),
                response.dataAtualizacao(),
                response.versao()
        );
    }

    private boolean itemBelongsToAnimal(VisitaAnimalItemDto item, Animal animal) {
        if (item.animalId() != null && item.animalId().equals(animal.getId())) {
            return true;
        }
        if (item.animalIdExterno() != null && !item.animalIdExterno().isBlank()
                && item.animalIdExterno().trim().equals(animal.getIdExterno())) {
            return true;
        }
        return item.animalCodigo() != null
                && !item.animalCodigo().isBlank()
                && item.animalCodigo().trim().equals(animal.getCodigo());
    }
}
