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
import com.cysvet.backend.dto.sync.PullSyncResponse;
import com.cysvet.backend.dto.sync.SyncEntityNames;
import com.cysvet.backend.dto.sync.SyncItemRequest;
import com.cysvet.backend.dto.sync.SyncItemResponse;
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
import com.cysvet.backend.exception.ResourceNotFoundException;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validator;
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
                        "SYNCED",
                        mutation.getIdEntidade(),
                        extractExternalId(item),
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
            Propriedade property = handleProperty(item, user);
            idempotencyService.register(item.chaveMutacao(), entity, user.getId(), property.getId());
            return new SyncItemResponse(item.chaveMutacao(), "SYNCED", property.getId(), property.getIdExterno(), "Sincronizado com sucesso");
        }

        if (SyncEntityNames.ANIMAL.equals(entity)) {
            if (item.operationType() == TipoOperacaoSincronizacao.DELETE) {
                return deleteAnimal(item, user);
            }
            Animal animal = handleAnimal(item, user);
            idempotencyService.register(item.chaveMutacao(), entity, user.getId(), animal.getId());
            return new SyncItemResponse(item.chaveMutacao(), "SYNCED", animal.getId(), animal.getIdExterno(), "Sincronizado com sucesso");
        }

        if (SyncEntityNames.LOT.equals(entity)) {
            if (item.operationType() == TipoOperacaoSincronizacao.DELETE) {
                return deleteLot(item, user);
            }
            Lote lote = handleLot(item, user);
            idempotencyService.register(item.chaveMutacao(), entity, user.getId(), lote.getId());
            return new SyncItemResponse(item.chaveMutacao(), "SYNCED", lote.getId(), lote.getIdExterno(), "Sincronizado com sucesso");
        }

        if (SyncEntityNames.EVENT.equals(entity)) {
            if (item.operationType() == TipoOperacaoSincronizacao.DELETE) {
                return deleteEvent(item, user);
            }
            EventoReprodutivo event = handleEvent(item, user);
            idempotencyService.register(item.chaveMutacao(), entity, user.getId(), event.getId());
            return new SyncItemResponse(item.chaveMutacao(), "SYNCED", event.getId(), event.getIdExterno(), "Sincronizado com sucesso");
        }

        if (SyncEntityNames.VISIT.equals(entity)) {
            if (item.operationType() == TipoOperacaoSincronizacao.DELETE) {
                return deleteVisit(item, user);
            }
            Visita visit = handleVisit(item, user);
            idempotencyService.register(item.chaveMutacao(), entity, user.getId(), visit.getId());
            return new SyncItemResponse(item.chaveMutacao(), "SYNCED", visit.getId(), visit.getIdExterno(), "Sincronizado com sucesso");
        }

        throw new IllegalArgumentException("Entidade de sincronizacao nao suportada: " + item.entity());
    }

    private Propriedade handleProperty(SyncItemRequest item, Usuario user) {
        PropriedadeRequest request = convertAndValidate(item.payload(), PropriedadeRequest.class);
        return propriedadeService.upsertForSync(request, resolveClientTimestamp(item.dataAtualizacaoCliente(), request.dataAtualizacaoCliente()), user);
    }

    private Animal handleAnimal(SyncItemRequest item, Usuario user) {
        AnimalRequest request = convertAndValidate(item.payload(), AnimalRequest.class);
        return animalService.upsertForSync(request, resolveClientTimestamp(item.dataAtualizacaoCliente(), request.dataAtualizacaoCliente()), user);
    }

    private Lote handleLot(SyncItemRequest item, Usuario user) {
        LoteRequest request = convertAndValidate(item.payload(), LoteRequest.class);
        return loteService.upsertForSync(request, resolveClientTimestamp(item.dataAtualizacaoCliente(), request.dataAtualizacaoCliente()), user);
    }

    private EventoReprodutivo handleEvent(SyncItemRequest item, Usuario user) {
        EventoReprodutivoRequest request = convertAndValidate(item.payload(), EventoReprodutivoRequest.class);
        return eventoReprodutivoService.upsertForSync(request, resolveClientTimestamp(item.dataAtualizacaoCliente(), request.dataAtualizacaoCliente()), user);
    }

    private Visita handleVisit(SyncItemRequest item, Usuario user) {
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
        return new SyncItemResponse(item.chaveMutacao(), "SYNCED", idEntidade, idExterno, "Sincronizado com sucesso");
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

    @FunctionalInterface
    private interface EntityIdSupplier {
        Long get();
    }
}
