package com.cysvet.backend.service;

import com.cysvet.backend.dto.evento.EventoReprodutivoRequest;
import com.cysvet.backend.dto.evento.EventoReprodutivoResponse;
import com.cysvet.backend.entity.Animal;
import com.cysvet.backend.entity.Propriedade;
import com.cysvet.backend.entity.EventoReprodutivo;
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
        deletedRecordService.clearDeletionMarker("event", saved.getIdExterno(), user.getId());
        return toResponse(saved);
    }

    @Transactional
    public EventoReprodutivoResponse update(Long id, EventoReprodutivoRequest request) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        EventoReprodutivo event = getEntity(id);
        apply(event, request, user);
        EventoReprodutivo saved = eventoReprodutivoRepository.save(event);
        deletedRecordService.clearDeletionMarker("event", saved.getIdExterno(), user.getId());
        return toResponse(saved);
    }

    @Transactional
    public void delete(Long id) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        EventoReprodutivo event = getEntity(id);
        eventoReprodutivoRepository.delete(event);
        deletedRecordService.registerDeletion("event", event.getIdExterno(), user.getId());
    }

    @Transactional
    public EventoReprodutivo upsertForSync(EventoReprodutivoRequest request, Instant dataAtualizacaoCliente, Usuario user) {
        EventoReprodutivo event = eventoReprodutivoRepository.findByIdExterno(request.idExterno())
                .orElseGet(EventoReprodutivo::new);

        if (event.getId() != null && dataAtualizacaoCliente != null && event.getDataAtualizacao().isAfter(dataAtualizacaoCliente)) {
            return event;
        }

        apply(event, request, user);
        EventoReprodutivo saved = eventoReprodutivoRepository.save(event);
        deletedRecordService.clearDeletionMarker("event", saved.getIdExterno(), user.getId());
        return saved;
    }

    @Transactional
    public void deleteByExternalId(String idExterno, Usuario user) {
        EventoReprodutivo event = getByExternalId(idExterno);
        eventoReprodutivoRepository.delete(event);
        deletedRecordService.registerDeletion("event", event.getIdExterno(), user.getId());
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
        Propriedade property = request.idPropriedade() != null
                ? propriedadeService.getEntity(request.idPropriedade())
                : propriedadeService.getByExternalId(request.idExternoPropriedade());
        Animal animal = request.idAnimal() != null
                ? animalService.getEntity(request.idAnimal())
                : animalService.getByExternalId(request.idExternoAnimal());

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

        if (request.tipo() == TipoEventoReprodutivo.CALVING) {
            animal.setDataUltimoParto(request.dataEvento());
            animal.setNumeroLactacao(animal.getNumeroLactacao() + 1);
        }
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
