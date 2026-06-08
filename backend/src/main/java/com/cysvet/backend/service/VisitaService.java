package com.cysvet.backend.service;

import com.cysvet.backend.dto.visita.VisitaAnimalItemDto;
import com.cysvet.backend.dto.visita.VisitaRequest;
import com.cysvet.backend.dto.visita.VisitaResponse;
import com.cysvet.backend.dto.sync.SyncEntityNames;
import com.cysvet.backend.entity.Propriedade;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.entity.Visita;
import com.cysvet.backend.exception.ResourceNotFoundException;
import com.cysvet.backend.repository.VisitaRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Instant;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class VisitaService {

    private final VisitaRepository visitRepository;
    private final PropriedadeService propriedadeService;
    private final UsuarioAutenticadoProvider authenticatedUserProvider;
    private final RegistroExcluidoService deletedRecordService;
    private final ObjectMapper objectMapper;

    @Transactional(readOnly = true)
    public List<VisitaResponse> list(Long idPropriedade) {
        List<Visita> visits = idPropriedade == null
                ? visitRepository.findAllByOrderByDataVisitaDesc()
                : visitRepository.findAllByPropriedadeIdOrderByDataVisitaDesc(idPropriedade);
        return visits.stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<VisitaResponse> listUpdatedSince(Instant since) {
        return visitRepository.findAllByDataAtualizacaoAfterOrderByDataAtualizacaoAsc(since).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public Visita getEntity(Long id) {
        return visitRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Visita nao encontrada"));
    }

    @Transactional(readOnly = true)
    public Visita getByExternalId(String idExterno) {
        return visitRepository.findByIdExterno(idExterno)
                .orElseThrow(() -> new ResourceNotFoundException("Visita nao encontrada"));
    }

    @Transactional
    public VisitaResponse create(VisitaRequest request) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Visita visit = new Visita();
        apply(visit, request, user);
        Visita saved = visitRepository.save(visit);
        deletedRecordService.clearDeletionMarker(SyncEntityNames.VISIT, saved.getIdExterno());
        return toResponse(saved);
    }

    @Transactional
    public VisitaResponse update(Long id, VisitaRequest request) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Visita visit = getEntity(id);
        apply(visit, request, user);
        Visita saved = visitRepository.save(visit);
        deletedRecordService.clearDeletionMarker(SyncEntityNames.VISIT, saved.getIdExterno());
        return toResponse(saved);
    }

    @Transactional
    public void delete(Long id) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Visita visit = getEntity(id);
        visitRepository.delete(visit);
        deletedRecordService.registerDeletion(SyncEntityNames.VISIT, visit.getIdExterno(), user.getId());
    }

    @Transactional
    public SyncUpsertResult<Visita> upsertForSync(VisitaRequest request, Instant dataAtualizacaoCliente, Usuario user) {
        Visita visit = visitRepository.findByIdExterno(request.idExterno())
                .orElseGet(Visita::new);

        if (visit.getId() != null && dataAtualizacaoCliente != null && visit.getDataAtualizacao().isAfter(dataAtualizacaoCliente)) {
            return SyncUpsertResult.conflicted(visit);
        }

        apply(visit, request, user);
        Visita saved = visitRepository.save(visit);
        deletedRecordService.clearDeletionMarker(SyncEntityNames.VISIT, saved.getIdExterno());
        return SyncUpsertResult.applied(saved);
    }

    @Transactional
    public void deleteByExternalId(String idExterno, Usuario user) {
        Visita visit = getByExternalId(idExterno);
        visitRepository.delete(visit);
        deletedRecordService.registerDeletion(SyncEntityNames.VISIT, visit.getIdExterno(), user.getId());
    }

    public VisitaResponse toResponse(Visita visit) {
        return new VisitaResponse(
                visit.getId(),
                visit.getIdExterno(),
                visit.getPropriedade().getId(),
                visit.getPropriedade().getIdExterno(),
                visit.getDataVisita(),
                visit.getObservacoes(),
                readAnimalItems(visit),
                visit.getDataCriacao(),
                visit.getDataAtualizacao(),
                visit.getVersao()
        );
    }

    private void apply(Visita visit, VisitaRequest request, Usuario user) {
        Propriedade property = resolveProperty(request.idPropriedade(), request.idExternoPropriedade());

        visit.setIdExterno(request.idExterno());
        visit.setPropriedade(property);
        visit.setUsuario(user);
        visit.setDataVisita(request.dataVisita());
        visit.setObservacoes(request.observacoes());
        visit.setAnimaisJson(writeAnimalItems(request.animais()));
    }

    private Propriedade resolveProperty(Long idPropriedade, String idExternoPropriedade) {
        if (idPropriedade != null) {
            return propriedadeService.getEntity(idPropriedade);
        }
        if (idExternoPropriedade != null && !idExternoPropriedade.isBlank()) {
            return propriedadeService.getByExternalId(idExternoPropriedade);
        }
        throw new IllegalArgumentException("Visita deve informar idPropriedade ou idExternoPropriedade");
    }

    private List<VisitaAnimalItemDto> readAnimalItems(Visita visit) {
        if (visit.getAnimaisJson() == null || visit.getAnimaisJson().isBlank()) {
            return List.of();
        }

        try {
            return objectMapper.readValue(visit.getAnimaisJson(), new TypeReference<List<VisitaAnimalItemDto>>() {
            });
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Falha ao ler animais da visita: " + exception.getMessage(), exception);
        }
    }

    private String writeAnimalItems(List<VisitaAnimalItemDto> items) {
        if (items == null || items.isEmpty()) {
            return null;
        }

        try {
            return objectMapper.writeValueAsString(items);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Falha ao salvar animais da visita: " + exception.getMessage(), exception);
        }
    }
}
