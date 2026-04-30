package com.cysvet.backend.service;

import java.time.Instant;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.cysvet.backend.dto.propriedade.PropriedadeRequest;
import com.cysvet.backend.dto.propriedade.PropriedadeResponse;
import com.cysvet.backend.entity.Propriedade;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.exception.ResourceNotFoundException;
import com.cysvet.backend.repository.AnimalRepository;
import com.cysvet.backend.repository.EventoReprodutivoRepository;
import com.cysvet.backend.repository.PropriedadeRepository;
import com.cysvet.backend.repository.VisitaRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class PropriedadeService {

    private final PropriedadeRepository farmPropertyRepository;
    private final UsuarioAutenticadoProvider authenticatedUserProvider;
    private final EventoReprodutivoRepository reproductiveEventRepository;
    private final AnimalRepository animalRepository;
    private final VisitaRepository visitRepository;
    private final RegistroExcluidoService deletedRecordService;

    @Transactional(readOnly = true)
    public List<PropriedadeResponse> list() {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        return farmPropertyRepository.findAllByUsuarioIdOrderByNomeAsc(user.getId()).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<PropriedadeResponse> listUpdatedSince(Long idUsuario, Instant dataAtualizacao) {
        return farmPropertyRepository.findAllByUsuarioIdAndDataAtualizacaoAfterOrderByDataAtualizacaoAsc(idUsuario, dataAtualizacao).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public Propriedade getEntity(Long id, Long idUsuario) {
        return farmPropertyRepository.findByIdAndUsuarioId(id, idUsuario)
                .orElseThrow(() -> new ResourceNotFoundException("Propriedade nao encontrada"));
    }

    @Transactional(readOnly = true)
    public Propriedade getByExternalId(String idExterno, Long idUsuario) {
        return farmPropertyRepository.findByIdExternoAndUsuarioId(idExterno, idUsuario)
                .orElseThrow(() -> new ResourceNotFoundException("Propriedade nao encontrada"));
    }

    @Transactional
    public PropriedadeResponse create(PropriedadeRequest request) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Propriedade property = new Propriedade();
        apply(property, request, user);
        Propriedade saved = farmPropertyRepository.save(property);
        deletedRecordService.clearDeletionMarker("property", saved.getIdExterno(), user.getId());
        return toResponse(saved);
    }

    @Transactional
    public PropriedadeResponse update(Long id, PropriedadeRequest request) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Propriedade property = getEntity(id, user.getId());
        apply(property, request, user);
        Propriedade saved = farmPropertyRepository.save(property);
        deletedRecordService.clearDeletionMarker("property", saved.getIdExterno(), user.getId());
        return toResponse(saved);
    }

    @Transactional
    public void delete(Long id) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Propriedade property = getEntity(id, user.getId());

        visitRepository.findAllByUsuarioIdAndPropriedadeIdOrderByDataVisitaDesc(user.getId(), property.getId())
                .forEach(visit -> {
                    visitRepository.delete(visit);
                    deletedRecordService.registerDeletion("visit", visit.getIdExterno(), user.getId());
                });

        reproductiveEventRepository.findAllByUsuarioIdAndPropriedadeIdOrderByDataEventoDesc(user.getId(), property.getId())
                .forEach(event -> {
                    reproductiveEventRepository.delete(event);
                    deletedRecordService.registerDeletion("event", event.getIdExterno(), user.getId());
                });

        animalRepository.findAllByUsuarioIdAndPropriedadeIdOrderByCodigoAsc(user.getId(), property.getId())
                .forEach(animal -> {
                    animalRepository.delete(animal);
                    deletedRecordService.registerDeletion("animal", animal.getIdExterno(), user.getId());
                });

        farmPropertyRepository.delete(property);
        deletedRecordService.registerDeletion("property", property.getIdExterno(), user.getId());
    }

    @Transactional
    public Propriedade upsertForSync(PropriedadeRequest request, Instant dataAtualizacaoCliente, Usuario user) {
        Propriedade property = farmPropertyRepository.findByIdExternoAndUsuarioId(request.idExterno(), user.getId())
                .orElseGet(Propriedade::new);

        if (property.getId() != null && dataAtualizacaoCliente != null && property.getDataAtualizacao().isAfter(dataAtualizacaoCliente)) {
            return property;
        }

        apply(property, request, user);
        Propriedade saved = farmPropertyRepository.save(property);
        deletedRecordService.clearDeletionMarker("property", saved.getIdExterno(), user.getId());
        return saved;
    }

    @Transactional
    public void deleteByExternalId(String idExterno, Usuario user) {
        Propriedade property = getByExternalId(idExterno, user.getId());

        visitRepository.findAllByUsuarioIdAndPropriedadeIdOrderByDataVisitaDesc(user.getId(), property.getId())
                .forEach(visit -> {
                    visitRepository.delete(visit);
                    deletedRecordService.registerDeletion("visit", visit.getIdExterno(), user.getId());
                });

        reproductiveEventRepository.findAllByUsuarioIdAndPropriedadeIdOrderByDataEventoDesc(user.getId(), property.getId())
                .forEach(event -> {
                    reproductiveEventRepository.delete(event);
                    deletedRecordService.registerDeletion("event", event.getIdExterno(), user.getId());
                });

        animalRepository.findAllByUsuarioIdAndPropriedadeIdOrderByCodigoAsc(user.getId(), property.getId())
                .forEach(animal -> {
                    animalRepository.delete(animal);
                    deletedRecordService.registerDeletion("animal", animal.getIdExterno(), user.getId());
                });

        farmPropertyRepository.delete(property);
        deletedRecordService.registerDeletion("property", property.getIdExterno(), user.getId());
    }

    private void apply(Propriedade property, PropriedadeRequest request, Usuario user) {
        property.setIdExterno(request.idExterno());
        property.setNome(request.nome());
        property.setNomeProprietario(request.nomeProprietario());
        property.setCidade(request.cidade());
        property.setEstado(request.estado());
        property.setObservacoes(request.observacoes());
        property.setUsuario(user);
    }

    public PropriedadeResponse toResponse(Propriedade property) {
        return new PropriedadeResponse(
                property.getId(),
                property.getIdExterno(),
                property.getNome(),
                property.getNomeProprietario(),
                property.getCidade(),
                property.getEstado(),
                property.getObservacoes(),
                property.getDataCriacao(),
                property.getDataAtualizacao(),
                property.getVersao()
        );
    }
}
