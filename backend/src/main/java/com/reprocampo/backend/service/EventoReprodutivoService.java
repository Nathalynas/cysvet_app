package com.reprocampo.backend.service;

import com.reprocampo.backend.dto.evento.EventoReprodutivoRequest;
import com.reprocampo.backend.dto.evento.EventoReprodutivoResponse;
import com.reprocampo.backend.entity.Animal;
import com.reprocampo.backend.entity.Propriedade;
import com.reprocampo.backend.entity.EventoReprodutivo;
import com.reprocampo.backend.entity.TipoEventoReprodutivo;
import com.reprocampo.backend.entity.Usuario;
import com.reprocampo.backend.exception.ResourceNotFoundException;
import com.reprocampo.backend.repository.EventoReprodutivoRepository;
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
        Usuario user = authenticatedUserProvider.getCurrentUser();
        List<EventoReprodutivo> events;
        if (idAnimal != null) {
            events = eventoReprodutivoRepository.findAllByUsuarioIdAndAnimalIdOrderByDataEventoDesc(user.getId(), idAnimal);
        } else if (idPropriedade != null) {
            events = eventoReprodutivoRepository.findAllByUsuarioIdAndPropriedadeIdOrderByDataEventoDesc(user.getId(), idPropriedade);
        } else {
            events = eventoReprodutivoRepository.findAllByUsuarioIdOrderByDataEventoDesc(user.getId());
        }
        return events.stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<EventoReprodutivoResponse> listUpdatedSince(Long idUsuario, Instant dataAtualizacao) {
        return eventoReprodutivoRepository.findAllByUsuarioIdAndDataAtualizacaoAfterOrderByDataAtualizacaoAsc(idUsuario, dataAtualizacao).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public EventoReprodutivo getEntity(Long id, Long idUsuario) {
        return eventoReprodutivoRepository.findByIdAndUsuarioId(id, idUsuario)
                .orElseThrow(() -> new ResourceNotFoundException("Evento reprodutivo nao encontrado"));
    }

    @Transactional(readOnly = true)
    public EventoReprodutivo getByExternalId(String idExterno, Long idUsuario) {
        return eventoReprodutivoRepository.findByIdExternoAndUsuarioId(idExterno, idUsuario)
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
        EventoReprodutivo event = getEntity(id, user.getId());
        apply(event, request, user);
        EventoReprodutivo saved = eventoReprodutivoRepository.save(event);
        deletedRecordService.clearDeletionMarker("event", saved.getIdExterno(), user.getId());
        return toResponse(saved);
    }

    @Transactional
    public void delete(Long id) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        EventoReprodutivo event = getEntity(id, user.getId());
        eventoReprodutivoRepository.delete(event);
        deletedRecordService.registerDeletion("event", event.getIdExterno(), user.getId());
    }

    @Transactional
    public EventoReprodutivo upsertForSync(EventoReprodutivoRequest request, Instant dataAtualizacaoCliente, Usuario user) {
        EventoReprodutivo event = eventoReprodutivoRepository.findByIdExternoAndUsuarioId(request.idExterno(), user.getId())
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
        EventoReprodutivo event = getByExternalId(idExterno, user.getId());
        eventoReprodutivoRepository.delete(event);
        deletedRecordService.registerDeletion("event", event.getIdExterno(), user.getId());
    }

    @Transactional(readOnly = true)
    public List<EventoReprodutivo> findForProperty(Long idPropriedade, LocalDate dataInicio, LocalDate dataFim) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        if (dataInicio != null && dataFim != null) {
            return eventoReprodutivoRepository.findAllByUsuarioIdAndPropriedadeIdAndDataEventoBetweenOrderByDataEventoDesc(
                    user.getId(),
                    idPropriedade,
                    dataInicio,
                    dataFim
            );
        }
        return eventoReprodutivoRepository.findAllByUsuarioIdAndPropriedadeIdOrderByDataEventoDesc(user.getId(), idPropriedade);
    }

    private void apply(EventoReprodutivo event, EventoReprodutivoRequest request, Usuario user) {
        Propriedade property = request.idPropriedade() != null
                ? propriedadeService.getEntity(request.idPropriedade(), user.getId())
                : propriedadeService.getByExternalId(request.idExternoPropriedade(), user.getId());
        Animal animal = request.idAnimal() != null
                ? animalService.getEntity(request.idAnimal(), user.getId())
                : animalService.getByExternalId(request.idExternoAnimal(), user.getId());

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
