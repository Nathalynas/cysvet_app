package com.cysvet.backend.service;

import java.time.Instant;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.cysvet.backend.dto.visita.VisitaRequest;
import com.cysvet.backend.dto.visita.VisitaResponse;
import com.cysvet.backend.entity.Propriedade;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.entity.Visita;
import com.cysvet.backend.exception.ResourceNotFoundException;
import com.cysvet.backend.repository.VisitaRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class VisitaService {

    private final VisitaRepository visitRepository;
    private final PropriedadeService propriedadeService;
    private final UsuarioAutenticadoProvider authenticatedUserProvider;
    private final RegistroExcluidoService deletedRecordService;

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
        deletedRecordService.clearDeletionMarker("visit", saved.getIdExterno(), user.getId());
        return toResponse(saved);
    }

    @Transactional
    public VisitaResponse update(Long id, VisitaRequest request) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Visita visit = getEntity(id);
        apply(visit, request, user);
        Visita saved = visitRepository.save(visit);
        deletedRecordService.clearDeletionMarker("visit", saved.getIdExterno(), user.getId());
        return toResponse(saved);
    }

    @Transactional
    public void delete(Long id) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Visita visit = getEntity(id);
        visitRepository.delete(visit);
        deletedRecordService.registerDeletion("visit", visit.getIdExterno(), user.getId());
    }

    @Transactional
    public Visita upsertForSync(VisitaRequest request, Instant dataAtualizacaoCliente, Usuario user) {
        Visita visit = visitRepository.findByIdExterno(request.idExterno())
                .orElseGet(Visita::new);

        if (visit.getId() != null && dataAtualizacaoCliente != null && visit.getDataAtualizacao().isAfter(dataAtualizacaoCliente)) {
            return visit;
        }

        apply(visit, request, user);
        Visita saved = visitRepository.save(visit);
        deletedRecordService.clearDeletionMarker("visit", saved.getIdExterno(), user.getId());
        return saved;
    }

    @Transactional
    public void deleteByExternalId(String idExterno, Usuario user) {
        Visita visit = getByExternalId(idExterno);
        visitRepository.delete(visit);
        deletedRecordService.registerDeletion("visit", visit.getIdExterno(), user.getId());
    }

    public VisitaResponse toResponse(Visita visit) {
        return new VisitaResponse(
                visit.getId(),
                visit.getIdExterno(),
                visit.getPropriedade().getId(),
                visit.getPropriedade().getIdExterno(),
                visit.getDataVisita(),
                visit.getObservacoes(),
                visit.getDataCriacao(),
                visit.getDataAtualizacao(),
                visit.getVersao()
        );
    }

    private void apply(Visita visit, VisitaRequest request, Usuario user) {
        Propriedade property = request.idPropriedade() != null
                ? propriedadeService.getEntity(request.idPropriedade())
                : propriedadeService.getByExternalId(request.idExternoPropriedade());

        visit.setIdExterno(request.idExterno());
        visit.setPropriedade(property);
        visit.setUsuario(user);
        visit.setDataVisita(request.dataVisita());
        visit.setObservacoes(request.observacoes());
    }
}
