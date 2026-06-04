package com.cysvet.backend.service;

import com.cysvet.backend.dto.lote.LoteRequest;
import com.cysvet.backend.dto.lote.LoteResponse;
import com.cysvet.backend.dto.sync.SyncEntityNames;
import com.cysvet.backend.entity.Lote;
import com.cysvet.backend.entity.Propriedade;
import com.cysvet.backend.entity.StatusLote;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.exception.ResourceNotFoundException;
import com.cysvet.backend.repository.LoteRepository;
import com.cysvet.backend.repository.PropriedadeRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class LoteService {

    private final LoteRepository loteRepository;
    private final PropriedadeRepository propriedadeRepository;
    private final UsuarioAutenticadoProvider authenticatedUserProvider;
    private final RegistroExcluidoService deletedRecordService;

    @Transactional(readOnly = true)
    public List<LoteResponse> list(Long idPropriedade, String search, String status) {
        return loteRepository.search(idPropriedade, normalizeSearch(search), parseStatus(status)).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<LoteResponse> listUpdatedSince(Instant dataAtualizacao) {
        return loteRepository.findAllByDataAtualizacaoAfterOrderByDataAtualizacaoAsc(dataAtualizacao).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public Lote getEntity(Long id) {
        return loteRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Lote nao encontrado"));
    }

    @Transactional(readOnly = true)
    public Lote getByExternalId(String idExterno) {
        return loteRepository.findByIdExterno(idExterno)
                .orElseThrow(() -> new ResourceNotFoundException("Lote nao encontrado"));
    }

    @Transactional
    public LoteResponse create(LoteRequest request) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Lote lote = new Lote();
        apply(lote, request, user);
        Lote saved = loteRepository.save(lote);
        deletedRecordService.clearDeletionMarker(SyncEntityNames.LOT, saved.getIdExterno());
        return toResponse(saved);
    }

    @Transactional
    public LoteResponse update(Long id, LoteRequest request) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Lote lote = getEntity(id);
        apply(lote, request, user);
        Lote saved = loteRepository.save(lote);
        deletedRecordService.clearDeletionMarker(SyncEntityNames.LOT, saved.getIdExterno());
        return toResponse(saved);
    }

    @Transactional
    public void delete(Long id) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Lote lote = getEntity(id);
        updateStatus(lote, StatusLote.INATIVO, user);
    }

    @Transactional
    public LoteResponse updateStatus(Long id, StatusLote status) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Lote lote = getEntity(id);
        return toResponse(updateStatus(lote, status, user));
    }

    @Transactional
    public Lote upsertForSync(LoteRequest request, Instant dataAtualizacaoCliente, Usuario user) {
        Lote lote = loteRepository.findByIdExterno(request.idExterno())
                .orElseGet(Lote::new);

        if (lote.getId() != null && dataAtualizacaoCliente != null && lote.getDataAtualizacao().isAfter(dataAtualizacaoCliente)) {
            return lote;
        }

        apply(lote, request, user);
        Lote saved = loteRepository.save(lote);
        deletedRecordService.clearDeletionMarker(SyncEntityNames.LOT, saved.getIdExterno());
        return saved;
    }

    @Transactional
    public void deleteByExternalId(String idExterno, Usuario user) {
        Lote lote = getByExternalId(idExterno);
        updateStatus(lote, StatusLote.INATIVO, user);
    }

    @Transactional
    public Lote ensureDefaultLotForProperty(Propriedade propriedade, Usuario user) {
        if (loteRepository.existsByPropriedadeId(propriedade.getId())) {
            return loteRepository.search(propriedade.getId(), null, null).stream()
                    .findFirst()
                    .orElseThrow(() -> new ResourceNotFoundException("Lote nao encontrado"));
        }

        Lote lote = new Lote();
        lote.setIdExterno(generateDefaultExternalId(propriedade));
        lote.setPropriedade(propriedade);
        lote.setUsuario(user);
        lote.setNome("Lote 1");
        lote.setDescricao(null);
        lote.setStatus(StatusLote.ATIVO);

        Lote saved = loteRepository.save(lote);
        deletedRecordService.clearDeletionMarker(SyncEntityNames.LOT, saved.getIdExterno());
        return saved;
    }

    private void apply(Lote lote, LoteRequest request, Usuario user) {
        Propriedade propriedade = resolveProperty(request.idPropriedade(), request.idExternoPropriedade());

        lote.setIdExterno(request.idExterno());
        lote.setPropriedade(propriedade);
        lote.setUsuario(user);
        lote.setNome(request.nome());
        lote.setDescricao(request.descricao());
        if (request.status() != null) {
            lote.setStatus(request.status());
        } else if (lote.getStatus() == null) {
            lote.setStatus(StatusLote.ATIVO);
        }
    }

    private Lote updateStatus(Lote lote, StatusLote status, Usuario user) {
        lote.setStatus(status);
        Lote saved = loteRepository.save(lote);
        deletedRecordService.clearDeletionMarker(SyncEntityNames.LOT, saved.getIdExterno());
        return saved;
    }

    private Propriedade resolveProperty(Long idPropriedade, String idExternoPropriedade) {
        if (idPropriedade != null) {
            return propriedadeRepository.findById(idPropriedade)
                    .orElseThrow(() -> new ResourceNotFoundException("Propriedade nao encontrada"));
        }
        if (idExternoPropriedade != null && !idExternoPropriedade.isBlank()) {
            return propriedadeRepository.findByIdExterno(idExternoPropriedade)
                    .orElseThrow(() -> new ResourceNotFoundException("Propriedade nao encontrada"));
        }
        throw new IllegalArgumentException("Lote deve informar idPropriedade ou idExternoPropriedade");
    }

    private StatusLote parseStatus(String status) {
        if (status == null || status.isBlank()) {
            return null;
        }
        return StatusLote.fromValue(status);
    }

    private String normalizeSearch(String search) {
        if (search == null || search.isBlank()) {
            return null;
        }
        return search.trim();
    }

    public LoteResponse toResponse(Lote lote) {
        return new LoteResponse(
                lote.getId(),
                lote.getIdExterno(),
                lote.getPropriedade().getId(),
                lote.getPropriedade().getIdExterno(),
                lote.getNome(),
                lote.getDescricao(),
                lote.getStatus(),
                lote.getDataCriacao(),
                lote.getDataAtualizacao(),
                lote.getVersao()
        );
    }

    private String generateDefaultExternalId(Propriedade propriedade) {
        return propriedade.getIdExterno() + "-lot-1-" + UUID.randomUUID();
    }
}
