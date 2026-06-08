package com.cysvet.backend.service;

import java.time.Instant;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.cysvet.backend.dto.animal.AnimalRequest;
import com.cysvet.backend.dto.evento.EventoReprodutivoRequest;
import com.cysvet.backend.dto.lote.LoteRequest;
import com.cysvet.backend.dto.propriedade.PropriedadeRequest;
import com.cysvet.backend.dto.sync.DeleteRequest;
import com.cysvet.backend.dto.sync.SyncContractResponse;
import com.cysvet.backend.dto.sync.PullSyncResponse;
import com.cysvet.backend.dto.sync.SyncEntityNames;
import com.cysvet.backend.dto.sync.SyncItemRequest;
import com.cysvet.backend.dto.sync.SyncItemResponse;
import com.cysvet.backend.dto.sync.SyncItemStatus;
import com.cysvet.backend.dto.sync.SyncRequest;
import com.cysvet.backend.dto.sync.SyncResponse;
import com.cysvet.backend.dto.visita.VisitaRequest;
import com.cysvet.backend.entity.Animal;
import com.cysvet.backend.entity.EventoReprodutivo;
import com.cysvet.backend.entity.Lote;
import com.cysvet.backend.entity.Propriedade;
import com.cysvet.backend.entity.TipoOperacaoSincronizacao;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.entity.Visita;
import com.cysvet.backend.entity.BaseEntity;
import com.cysvet.backend.exception.ResourceNotFoundException;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validator;
import java.util.Map;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class SyncService {

    private final UsuarioAutenticadoProvider authenticatedUserProvider;
    private final IdempotencyService idempotencyService;
    private final PropriedadeService propriedadeService;
    private final LoteService loteService;
    private final AnimalService animalService;
    private final EventoReprodutivoService eventoReprodutivoService;
    private final VisitaService visitService;
    private final RegistroExcluidoService deletedRecordService;
    private final ObjectMapper objectMapper;
    private final Validator validator;

    @Transactional
    public SyncResponse sync(SyncRequest request) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        List<SyncItemResponse> responses = request.items().stream()
                .map(item -> process(item, user))
                .toList();
        return new SyncResponse(responses);
    }

    @Transactional(readOnly = true)
    public PullSyncResponse pull(Instant since) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        Instant baseInstant = since == null ? Instant.EPOCH : since;

        return new PullSyncResponse(
                Instant.now(),
                buildContract(),
                propriedadeService.listUpdatedSince(baseInstant),
                loteService.listUpdatedSince(baseInstant),
                animalService.listUpdatedSince(baseInstant),
                visitService.listUpdatedSince(baseInstant),
                eventoReprodutivoService.listUpdatedSince(baseInstant),
                deletedRecordService.findDeletedSince(baseInstant)
        );
    }

    private SyncItemResponse process(SyncItemRequest item, Usuario user) {
        return idempotencyService.findByMutationKey(item.chaveMutacao())
                .map(mutation -> new SyncItemResponse(
                        item.chaveMutacao(),
                        SyncItemStatus.REPLAYED,
                        mutation.getIdEntidade(),
                        extractExternalId(item),
                        null,
                        "Operacao reaproveitada por idempotencia"
                ))
                .orElseGet(() -> execute(item, user));
    }

    private SyncItemResponse execute(SyncItemRequest item, Usuario user) {
        String entity = SyncEntityNames.normalize(item.entity());

        if (SyncEntityNames.PROPERTY.equals(entity)) {
            if (item.operationType() == TipoOperacaoSincronizacao.DELETE) {
                return deleteProperty(item, user);
            }
            SyncUpsertResult<Propriedade> property = handleProperty(item, user);
            idempotencyService.register(item.chaveMutacao(), entity, user.getId(), property.entity().getId());
            return buildUpsertResponse(item, property.entity(), property.applied(), property.entity().getIdExterno());
        }

        if (SyncEntityNames.ANIMAL.equals(entity)) {
            if (item.operationType() == TipoOperacaoSincronizacao.DELETE) {
                return deleteAnimal(item, user);
            }
            SyncUpsertResult<Animal> animal = handleAnimal(item, user);
            idempotencyService.register(item.chaveMutacao(), entity, user.getId(), animal.entity().getId());
            return buildUpsertResponse(item, animal.entity(), animal.applied(), animal.entity().getIdExterno());
        }

        if (SyncEntityNames.LOT.equals(entity)) {
            if (item.operationType() == TipoOperacaoSincronizacao.DELETE) {
                return deleteLot(item, user);
            }
            SyncUpsertResult<Lote> lote = handleLot(item, user);
            idempotencyService.register(item.chaveMutacao(), entity, user.getId(), lote.entity().getId());
            return buildUpsertResponse(item, lote.entity(), lote.applied(), lote.entity().getIdExterno());
        }

        if (SyncEntityNames.EVENT.equals(entity)) {
            if (item.operationType() == TipoOperacaoSincronizacao.DELETE) {
                return deleteEvent(item, user);
            }
            SyncUpsertResult<EventoReprodutivo> event = handleEvent(item, user);
            idempotencyService.register(item.chaveMutacao(), entity, user.getId(), event.entity().getId());
            return buildUpsertResponse(item, event.entity(), event.applied(), event.entity().getIdExterno());
        }

        if (SyncEntityNames.VISIT.equals(entity)) {
            if (item.operationType() == TipoOperacaoSincronizacao.DELETE) {
                return deleteVisit(item, user);
            }
            SyncUpsertResult<Visita> visit = handleVisit(item, user);
            idempotencyService.register(item.chaveMutacao(), entity, user.getId(), visit.entity().getId());
            return buildUpsertResponse(item, visit.entity(), visit.applied(), visit.entity().getIdExterno());
        }

        throw new IllegalArgumentException("Entidade de sincronizacao nao suportada: " + item.entity());
    }

    private SyncUpsertResult<Propriedade> handleProperty(SyncItemRequest item, Usuario user) {
        PropriedadeRequest request = convertAndValidate(item.payload(), PropriedadeRequest.class);
        return propriedadeService.upsertForSync(request, resolveClientTimestamp(item.dataAtualizacaoCliente(), request.dataAtualizacaoCliente()), user);
    }

    private SyncUpsertResult<Animal> handleAnimal(SyncItemRequest item, Usuario user) {
        AnimalRequest request = convertAndValidate(item.payload(), AnimalRequest.class);
        return animalService.upsertForSync(request, resolveClientTimestamp(item.dataAtualizacaoCliente(), request.dataAtualizacaoCliente()), user);
    }

    private SyncUpsertResult<Lote> handleLot(SyncItemRequest item, Usuario user) {
        LoteRequest request = convertAndValidate(item.payload(), LoteRequest.class);
        return loteService.upsertForSync(request, resolveClientTimestamp(item.dataAtualizacaoCliente(), request.dataAtualizacaoCliente()), user);
    }

    private SyncUpsertResult<EventoReprodutivo> handleEvent(SyncItemRequest item, Usuario user) {
        EventoReprodutivoRequest request = convertAndValidate(item.payload(), EventoReprodutivoRequest.class);
        return eventoReprodutivoService.upsertForSync(request, resolveClientTimestamp(item.dataAtualizacaoCliente(), request.dataAtualizacaoCliente()), user);
    }

    private SyncUpsertResult<Visita> handleVisit(SyncItemRequest item, Usuario user) {
        VisitaRequest request = convertAndValidate(item.payload(), VisitaRequest.class);
        return visitService.upsertForSync(request, resolveClientTimestamp(item.dataAtualizacaoCliente(), request.dataAtualizacaoCliente()), user);
    }

    private SyncItemResponse deleteProperty(SyncItemRequest item, Usuario user) {
        DeleteRequest request = convertAndValidate(item.payload(), DeleteRequest.class);
        return deleteEntity(item, user, request.idExterno(), null, () -> propriedadeService.deleteByExternalId(request.idExterno(), user),
                () -> propriedadeService.getByExternalId(request.idExterno()).getId());
    }

    private SyncItemResponse deleteAnimal(SyncItemRequest item, Usuario user) {
        DeleteRequest request = convertAndValidate(item.payload(), DeleteRequest.class);
        return deleteEntity(item, user, request.idExterno(), null, () -> animalService.deleteByExternalId(request.idExterno(), user),
                () -> animalService.getByExternalId(request.idExterno()).getId());
    }

    private SyncItemResponse deleteLot(SyncItemRequest item, Usuario user) {
        DeleteRequest request = convertAndValidate(item.payload(), DeleteRequest.class);
        return deleteEntity(item, user, request.idExterno(), null, () -> loteService.deleteByExternalId(request.idExterno(), user),
                () -> loteService.getByExternalId(request.idExterno()).getId());
    }

    private SyncItemResponse deleteEvent(SyncItemRequest item, Usuario user) {
        DeleteRequest request = convertAndValidate(item.payload(), DeleteRequest.class);
        return deleteEntity(item, user, request.idExterno(), SyncEntityNames.EVENT, () -> eventoReprodutivoService.deleteByExternalId(request.idExterno(), user),
                () -> eventoReprodutivoService.getByExternalId(request.idExterno()).getId());
    }

    private SyncItemResponse deleteVisit(SyncItemRequest item, Usuario user) {
        DeleteRequest request = convertAndValidate(item.payload(), DeleteRequest.class);
        return deleteEntity(item, user, request.idExterno(), SyncEntityNames.VISIT, () -> visitService.deleteByExternalId(request.idExterno(), user),
                () -> visitService.getByExternalId(request.idExterno()).getId());
    }

    private SyncItemResponse deleteEntity(
            SyncItemRequest item,
            Usuario user,
            String idExterno,
            String nomeEntidade,
            Runnable deleteAction,
            EntityIdSupplier entityIdSupplier
    ) {
        Long idEntidade = 0L;
        try {
            idEntidade = entityIdSupplier.get();
            deleteAction.run();
        } catch (ResourceNotFoundException exception) {
            if (nomeEntidade != null) {
                deletedRecordService.registerDeletion(nomeEntidade, idExterno, user.getId());
            }
        }

        idempotencyService.register(item.chaveMutacao(), SyncEntityNames.normalize(item.entity()), user.getId(), idEntidade);
        return new SyncItemResponse(item.chaveMutacao(), SyncItemStatus.SYNCED, idEntidade, idExterno, Instant.now(), "Sincronizado com sucesso");
    }

    private <T> T convertAndValidate(Object payload, Class<T> type) {
        T request = objectMapper.convertValue(payload, type);
        ConstraintViolation<T> violation = validator.validate(request).stream()
                .findFirst()
                .orElse(null);
        if (violation != null) {
            throw new IllegalArgumentException(violation.getMessage());
        }
        return request;
    }

    private Instant resolveClientTimestamp(Instant envelopeTimestamp, Instant payloadTimestamp) {
        return envelopeTimestamp != null ? envelopeTimestamp : payloadTimestamp;
    }

    private String extractExternalId(SyncItemRequest item) {
        if (item.payload() == null) {
            return null;
        }
        if (item.payload().hasNonNull("idExterno")) {
            return item.payload().get("idExterno").asText();
        }
        if (item.payload().hasNonNull("id_externo")) {
            return item.payload().get("id_externo").asText();
        }
        return null;
    }

    private SyncItemResponse buildUpsertResponse(
            SyncItemRequest item,
            BaseEntity entity,
            boolean applied,
            String idExterno
    ) {
        if (applied) {
            return new SyncItemResponse(
                    item.chaveMutacao(),
                    SyncItemStatus.SYNCED,
                    entity.getId(),
                    idExterno,
                    entity.getDataAtualizacao(),
                    "Sincronizado com sucesso"
            );
        }

        return new SyncItemResponse(
                item.chaveMutacao(),
                SyncItemStatus.CONFLICT_SERVER_WINS,
                entity.getId(),
                idExterno,
                entity.getDataAtualizacao(),
                "Atualizacao ignorada porque o servidor possui versao mais recente; o cliente deve executar um pull para reconciliar"
        );
    }

    private SyncContractResponse buildContract() {
        return new SyncContractResponse(
                "offline-sync-v1",
                SyncEntityNames.createUpdateOrder(),
                SyncEntityNames.deleteOrder(),
                SyncEntityNames.snapshotCollections(),
                "SERVER_WINS_WHEN_SERVER_DATA_ATUALIZACAO_IS_AFTER_CLIENT_TIMESTAMP",
                "AFTER_PUSH_EXECUTE_INCREMENTAL_PULL_USING_LAST_SUCCESSFUL_CHECKPOINT",
                Map.of(
                        SyncEntityNames.PROPERTY, "SOFT_DELETE_WITH_STATUS_INATIVO",
                        SyncEntityNames.LOT, "SOFT_DELETE_WITH_STATUS_INATIVO",
                        SyncEntityNames.ANIMAL, "SOFT_DELETE_WITH_STATUS_INATIVO",
                        SyncEntityNames.VISIT, "HARD_DELETE_WITH_DELETED_RECORD_TOMBSTONE",
                        SyncEntityNames.EVENT, "HARD_DELETE_WITH_DELETED_RECORD_TOMBSTONE"
                ),
                "ONLINE_ONLY",
                "ONLINE_ONLY"
        );
    }

    @FunctionalInterface
    private interface EntityIdSupplier {
        Long get();
    }
}
