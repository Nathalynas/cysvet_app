package com.cysvet.backend.service;

import java.time.Instant;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.cysvet.backend.dto.propriedade.PropriedadeRequest;
import com.cysvet.backend.dto.propriedade.PropriedadeResponse;
import com.cysvet.backend.dto.sync.SyncEntityNames;
import com.cysvet.backend.entity.Propriedade;
import com.cysvet.backend.entity.StatusPropriedade;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.exception.ResourceNotFoundException;
import com.cysvet.backend.repository.PropriedadeRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class PropriedadeService {

    private final PropriedadeRepository farmPropertyRepository;
    private final LoteService loteService;
    private final UsuarioAutenticadoProvider authenticatedUserProvider;
    private final RegistroExcluidoService deletedRecordService;

    @Transactional(readOnly = true)
    public List<PropriedadeResponse> list(String search, String status) {
        return farmPropertyRepository.search(normalizeSearch(search), parseStatus(status)).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<PropriedadeResponse> listUpdatedSince(Instant dataAtualizacao) {
        return farmPropertyRepository.findAllByDataAtualizacaoAfterOrderByDataAtualizacaoAsc(dataAtualizacao).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public Propriedade getEntity(Long id) {
        return farmPropertyRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Propriedade nao encontrada"));
    }

    @Transactional(readOnly = true)
    public Propriedade getByExternalId(String idExterno) {
        return farmPropertyRepository.findByIdExterno(idExterno)
                .orElseThrow(() -> new ResourceNotFoundException("Propriedade nao encontrada"));
    }

    @Transactional
    public PropriedadeResponse create(PropriedadeRequest request) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Propriedade property = new Propriedade();
        apply(property, request, user);
        Propriedade saved = farmPropertyRepository.save(property);
        loteService.ensureDefaultLotForProperty(saved, user);
        deletedRecordService.clearDeletionMarker(SyncEntityNames.PROPERTY, saved.getIdExterno());
        return toResponse(saved);
    }

    @Transactional
    public PropriedadeResponse update(Long id, PropriedadeRequest request) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Propriedade property = getEntity(id);
        apply(property, request, user);
        Propriedade saved = farmPropertyRepository.save(property);
        deletedRecordService.clearDeletionMarker(SyncEntityNames.PROPERTY, saved.getIdExterno());
        return toResponse(saved);
    }

    @Transactional
    public void delete(Long id) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Propriedade property = getEntity(id);
        updateStatus(property, StatusPropriedade.INATIVO, user);
    }

    @Transactional
    public PropriedadeResponse updateStatus(Long id, StatusPropriedade status) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Propriedade property = getEntity(id);
        Propriedade saved = updateStatus(property, status, user);
        return toResponse(saved);
    }

    @Transactional
    public Propriedade upsertForSync(PropriedadeRequest request, Instant dataAtualizacaoCliente, Usuario user) {
        Propriedade property = farmPropertyRepository.findByIdExterno(request.idExterno())
                .orElseGet(Propriedade::new);
        boolean isNewProperty = property.getId() == null;

        if (property.getId() != null && dataAtualizacaoCliente != null && property.getDataAtualizacao().isAfter(dataAtualizacaoCliente)) {
            return property;
        }

        apply(property, request, user);
        Propriedade saved = farmPropertyRepository.save(property);
        if (isNewProperty) {
            loteService.ensureDefaultLotForProperty(saved, user);
        }
        deletedRecordService.clearDeletionMarker(SyncEntityNames.PROPERTY, saved.getIdExterno());
        return saved;
    }

    @Transactional
    public void deleteByExternalId(String idExterno, Usuario user) {
        Propriedade property = getByExternalId(idExterno);
        updateStatus(property, StatusPropriedade.INATIVO, user);
    }

    private void apply(Propriedade property, PropriedadeRequest request, Usuario user) {
        property.setIdExterno(request.idExterno());
        property.setNome(request.nome());
        property.setNomeProprietario(request.nomeProprietario());
        property.setContato(request.contato());
        property.setCidade(request.cidade());
        property.setEstado(request.estado());
        property.setObservacoes(request.observacoes());
        if (request.status() != null) {
            property.setStatus(request.status());
        } else if (property.getStatus() == null) {
            property.setStatus(StatusPropriedade.ATIVO);
        }
        property.setUsuario(user);
    }

    private Propriedade updateStatus(Propriedade property, StatusPropriedade status, Usuario user) {
        property.setStatus(status);
        Propriedade saved = farmPropertyRepository.save(property);
        deletedRecordService.clearDeletionMarker(SyncEntityNames.PROPERTY, saved.getIdExterno());
        return saved;
    }

    private StatusPropriedade parseStatus(String status) {
        if (status == null || status.isBlank()) {
            return null;
        }
        return StatusPropriedade.fromValue(status);
    }

    private String normalizeSearch(String search) {
        if (search == null || search.isBlank()) {
            return null;
        }
        return search.trim();
    }

    public PropriedadeResponse toResponse(Propriedade property) {
        return new PropriedadeResponse(
                property.getId(),
                property.getIdExterno(),
                property.getNome(),
                property.getNomeProprietario(),
                property.getContato(),
                property.getCidade(),
                property.getEstado(),
                property.getObservacoes(),
                property.getStatus(),
                property.getDataCriacao(),
                property.getDataAtualizacao(),
                property.getVersao()
        );
    }
}
