package com.cysvet.backend.service;

import com.cysvet.backend.dto.evento.EventoReprodutivoRequest;
import com.cysvet.backend.dto.evento.EventoReprodutivoResponse;
import com.cysvet.backend.dto.sync.SyncEntityNames;
import com.cysvet.backend.entity.Animal;
import com.cysvet.backend.entity.Propriedade;
import com.cysvet.backend.entity.EventoReprodutivo;
import com.cysvet.backend.entity.StatusReprodutivoAnimal;
import com.cysvet.backend.entity.TipoEventoReprodutivo;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.exception.ResourceNotFoundException;
import com.cysvet.backend.repository.EventoReprodutivoRepository;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class EventoReprodutivoService {

    private final EventoReprodutivoRepository eventoReprodutivoRepository;
    private final AnimalService animalService;
    private final PropriedadeService propriedadeService;
    private final UsuarioAutenticadoProvider authenticatedUserProvider;
    private final RegistroExcluidoService deletedRecordService;

    @Transactional(readOnly = true)
    public List<EventoReprodutivoResponse> list(Long idPropriedade, Long idAnimal) {
        List<EventoReprodutivo> events;
        if (idAnimal != null) {
            events = eventoReprodutivoRepository.findAllByAnimalIdOrderByDataEventoDesc(idAnimal);
        } else if (idPropriedade != null) {
            events = eventoReprodutivoRepository.findAllByPropriedadeIdOrderByDataEventoDesc(idPropriedade);
        } else {
            events = eventoReprodutivoRepository.findAllByOrderByDataEventoDesc();
        }
        return events.stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<EventoReprodutivoResponse> listUpdatedSince(Instant dataAtualizacao) {
        return eventoReprodutivoRepository.findAllByDataAtualizacaoAfterOrderByDataAtualizacaoAsc(dataAtualizacao).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public EventoReprodutivo getEntity(Long id) {
        return eventoReprodutivoRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Evento reprodutivo nao encontrado"));
    }

    @Transactional(readOnly = true)
    public EventoReprodutivo getByExternalId(String idExterno) {
        return eventoReprodutivoRepository.findByIdExterno(idExterno)
                .orElseThrow(() -> new ResourceNotFoundException("Evento reprodutivo nao encontrado"));
    }

    @Transactional
    public EventoReprodutivoResponse create(EventoReprodutivoRequest request) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        EventoReprodutivo event = new EventoReprodutivo();
        apply(event, request, user);
        EventoReprodutivo saved = eventoReprodutivoRepository.save(event);
        deletedRecordService.clearDeletionMarker(SyncEntityNames.EVENT, saved.getIdExterno());
        return toResponse(saved);
    }

    @Transactional
    public EventoReprodutivoResponse update(Long id, EventoReprodutivoRequest request) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        EventoReprodutivo event = getEntity(id);
        apply(event, request, user);
        EventoReprodutivo saved = eventoReprodutivoRepository.save(event);
        deletedRecordService.clearDeletionMarker(SyncEntityNames.EVENT, saved.getIdExterno());
        return toResponse(saved);
    }

    @Transactional
    public void delete(Long id) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        EventoReprodutivo event = getEntity(id);
        eventoReprodutivoRepository.delete(event);
        deletedRecordService.registerDeletion(SyncEntityNames.EVENT, event.getIdExterno(), user.getId());
    }

    @Transactional
    public SyncUpsertResult<EventoReprodutivo> upsertForSync(EventoReprodutivoRequest request, Instant dataAtualizacaoCliente, Usuario user) {
        EventoReprodutivo event = eventoReprodutivoRepository.findByIdExterno(request.idExterno())
                .orElseGet(EventoReprodutivo::new);

        if (event.getId() != null && dataAtualizacaoCliente != null && event.getDataAtualizacao().isAfter(dataAtualizacaoCliente)) {
            return SyncUpsertResult.conflicted(event);
        }

        apply(event, request, user);
        EventoReprodutivo saved = eventoReprodutivoRepository.save(event);
        deletedRecordService.clearDeletionMarker(SyncEntityNames.EVENT, saved.getIdExterno());
        return SyncUpsertResult.applied(saved);
    }

    @Transactional
    public void deleteByExternalId(String idExterno, Usuario user) {
        EventoReprodutivo event = getByExternalId(idExterno);
        eventoReprodutivoRepository.delete(event);
        deletedRecordService.registerDeletion(SyncEntityNames.EVENT, event.getIdExterno(), user.getId());
    }

    @Transactional(readOnly = true)
    public List<EventoReprodutivo> findForProperty(Long idPropriedade, LocalDate dataInicio, LocalDate dataFim) {
        if (dataInicio != null && dataFim != null) {
            return eventoReprodutivoRepository.findAllByPropriedadeIdAndDataEventoBetweenOrderByDataEventoDesc(
                    idPropriedade,
                    dataInicio,
                    dataFim
            );
        }
        return eventoReprodutivoRepository.findAllByPropriedadeIdOrderByDataEventoDesc(idPropriedade);
    }

    private void apply(EventoReprodutivo event, EventoReprodutivoRequest request, Usuario user) {
        boolean isNewEvent = event.getId() == null;
        Propriedade property = resolveProperty(request.idPropriedade(), request.idExternoPropriedade());
        Animal animal = resolveAnimal(request.idAnimal(), request.idExternoAnimal());

        if (!animal.getPropriedade().getId().equals(property.getId())) {
            throw new IllegalArgumentException("Animal informado nao pertence a propriedade do evento");
        }

        event.setIdExterno(request.idExterno());
        event.setPropriedade(property);
        event.setAnimal(animal);
        event.setUsuario(user);
        event.setTipo(request.tipo());
        event.setDataEvento(request.dataEvento());
        event.setPrenhezConfirmada(request.prenhezConfirmada());
        event.setObservacoes(request.observacoes());
        event.setDataPrevistaParto(
                request.tipo() == TipoEventoReprodutivo.INSEMINATION ? request.dataEvento().plusDays(283) : null
        );

        syncAnimalReproductiveSnapshot(animal, request, isNewEvent);
    }

    private void syncAnimalReproductiveSnapshot(Animal animal, EventoReprodutivoRequest request, boolean isNewEvent) {
        switch (request.tipo()) {
            case INSEMINATION -> {
                animal.setDataInseminacao(request.dataEvento());
                animal.setStatusReprodutivo(StatusReprodutivoAnimal.INSEMINATED);
            }
            case PREGNANCY_DIAGNOSIS -> {
                if (request.prenhezConfirmada() != null) {
                    animal.setStatusReprodutivo(request.prenhezConfirmada()
                            ? StatusReprodutivoAnimal.PREGNANT
                            : StatusReprodutivoAnimal.EMPTY);
                }
            }
            case CALVING -> {
                animal.setDataInseminacao(null);
                animal.setStatusReprodutivo(StatusReprodutivoAnimal.PENDING);
                if (isNewEvent) {
                    animal.setDataUltimoParto(request.dataEvento());
                    animal.setNumeroLactacao(animal.getNumeroLactacao() + 1);
                }
            }
            case DRY_OFF -> animal.setStatusReprodutivo(StatusReprodutivoAnimal.DRY);
            case GESTATIONAL_LOSS -> animal.setStatusReprodutivo(StatusReprodutivoAnimal.EMPTY);
        }
    }

    private Propriedade resolveProperty(Long idPropriedade, String idExternoPropriedade) {
        if (idPropriedade != null) {
            return propriedadeService.getEntity(idPropriedade);
        }
        if (idExternoPropriedade != null && !idExternoPropriedade.isBlank()) {
            return propriedadeService.getByExternalId(idExternoPropriedade);
        }
        throw new IllegalArgumentException("Evento deve informar idPropriedade ou idExternoPropriedade");
    }

    private Animal resolveAnimal(Long idAnimal, String idExternoAnimal) {
        if (idAnimal != null) {
            return animalService.getEntity(idAnimal);
        }
        if (idExternoAnimal != null && !idExternoAnimal.isBlank()) {
            return animalService.getByExternalId(idExternoAnimal);
        }
        throw new IllegalArgumentException("Evento deve informar idAnimal ou idExternoAnimal");
    }

    public EventoReprodutivoResponse toResponse(EventoReprodutivo event) {
        return new EventoReprodutivoResponse(
                event.getId(),
                event.getIdExterno(),
                event.getPropriedade().getId(),
                event.getPropriedade().getIdExterno(),
                event.getAnimal().getId(),
                event.getAnimal().getIdExterno(),
                event.getTipo(),
                event.getDataEvento(),
                event.getDataPrevistaParto(),
                event.getPrenhezConfirmada(),
                event.getObservacoes(),
                event.getDataCriacao(),
                event.getDataAtualizacao(),
                event.getVersao()
        );
    }
}
