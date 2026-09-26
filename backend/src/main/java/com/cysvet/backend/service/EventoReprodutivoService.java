package com.cysvet.backend.service;

import com.cysvet.backend.dto.evento.EventoReprodutivoRequest;
import com.cysvet.backend.dto.evento.EventoReprodutivoResponse;
import com.cysvet.backend.dto.sync.SyncEntityNames;
import com.cysvet.backend.entity.Animal;
import com.cysvet.backend.entity.Propriedade;
import com.cysvet.backend.entity.EventoReprodutivo;
import com.cysvet.backend.entity.StatusAnimal;
import com.cysvet.backend.entity.TipoEventoReprodutivo;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.exception.ResourceNotFoundException;
import com.cysvet.backend.repository.EventoReprodutivoRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class EventoReprodutivoService {

    // Mesmo prazo usado pelo app e pelas planilhas de campo (IA + 282 dias).
    static final int DIAS_DA_IA_ATE_O_PARTO = 282;

    private final ResumoReprodutivoAnimalService resumoReprodutivoAnimalService;
    private final EventoReprodutivoRepository eventoReprodutivoRepository;
    private final AnimalService animalService;
    private final PropriedadeService propriedadeService;
    private final UsuarioAutenticadoProvider authenticatedUserProvider;
    private final RegistroExcluidoService deletedRecordService;
    private final ObjectMapper objectMapper;

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
        return toResponse(save(new EventoReprodutivo(), request, user));
    }

    @Transactional
    public EventoReprodutivoResponse update(Long id, EventoReprodutivoRequest request) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        return toResponse(save(getEntity(id), request, user));
    }

    @Transactional
    public void delete(Long id) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        remove(getEntity(id), user);
    }

    @Transactional
    public SyncUpsertResult<EventoReprodutivo> upsertForSync(EventoReprodutivoRequest request, Instant dataAtualizacaoCliente, Usuario user) {
        EventoReprodutivo event = eventoReprodutivoRepository.findByIdExterno(request.idExterno())
                .orElseGet(EventoReprodutivo::new);

        if (event.getId() != null && dataAtualizacaoCliente != null && event.getDataAtualizacao().isAfter(dataAtualizacaoCliente)) {
            return SyncUpsertResult.conflicted(event);
        }

        return SyncUpsertResult.applied(save(event, request, user));
    }

    @Transactional
    public void deleteByExternalId(String idExterno, Usuario user) {
        remove(getByExternalId(idExterno), user);
    }

    private EventoReprodutivo save(EventoReprodutivo event, EventoReprodutivoRequest request, Usuario user) {
        Animal previousAnimal = event.getAnimal();
        apply(event, request, user);
        EventoReprodutivo saved = eventoReprodutivoRepository.save(event);
        deletedRecordService.clearDeletionMarker(SyncEntityNames.EVENT, saved.getIdExterno());

        resumoReprodutivoAnimalService.recalcular(saved.getAnimal());
        if (previousAnimal != null && !previousAnimal.getId().equals(saved.getAnimal().getId())) {
            resumoReprodutivoAnimalService.recalcular(previousAnimal);
        }
        return saved;
    }

    private void remove(EventoReprodutivo event, Usuario user) {
        Animal animal = event.getAnimal();
        eventoReprodutivoRepository.delete(event);
        eventoReprodutivoRepository.flush();
        deletedRecordService.registerDeletion(SyncEntityNames.EVENT, event.getIdExterno(), user.getId());
        resumoReprodutivoAnimalService.recalcular(animal);
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
        Propriedade property = propriedadeService.resolve(request.idPropriedade(), request.idExternoPropriedade(), "Evento");
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
        event.setDetalhesJson(writeDetails(request.detalhes()));
        event.setDataPrevistaParto(previsaoDeParto(request.tipo(), request.dataEvento()));

        // O resumo reprodutivo e recalculado depois de salvar; aqui ficam so os
        // efeitos sobre a situacao do animal no rebanho.
        if (request.tipo() == TipoEventoReprodutivo.DISCARD) {
            animal.setStatus(StatusAnimal.INATIVO);
        } else if (request.tipo() == TipoEventoReprodutivo.DEATH) {
            animal.setStatus(StatusAnimal.OBITO);
        }
    }

    static LocalDate previsaoDeParto(TipoEventoReprodutivo tipo, LocalDate dataEvento) {
        return tipo == TipoEventoReprodutivo.INSEMINATION ? dataEvento.plusDays(DIAS_DA_IA_ATE_O_PARTO) : null;
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
                readDetails(event.getDetalhesJson()),
                event.getDataCriacao(),
                event.getDataAtualizacao(),
                event.getVersao(),
                event.getVisita() == null ? null : event.getVisita().getIdExterno()
        );
    }

    private String writeDetails(Map<String, Object> details) {
        if (details == null || details.isEmpty()) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(details);
        } catch (JsonProcessingException exception) {
            throw new IllegalArgumentException("Detalhes do evento invalidos", exception);
        }
    }

    private Map<String, Object> readDetails(String detailsJson) {
        if (detailsJson == null || detailsJson.isBlank()) {
            return Map.of();
        }
        try {
            return objectMapper.readValue(detailsJson, new TypeReference<Map<String, Object>>() {
            });
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Falha ao ler detalhes do evento", exception);
        }
    }
}
