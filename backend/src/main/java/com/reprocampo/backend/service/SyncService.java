package com.reprocampo.backend.service;

import java.time.Instant;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.reprocampo.backend.dto.animal.AnimalRequest;
import com.reprocampo.backend.dto.evento.EventoReprodutivoRequest;
import com.reprocampo.backend.dto.propriedade.PropriedadeRequest;
import com.reprocampo.backend.dto.sync.DeleteRequest;
import com.reprocampo.backend.dto.sync.PullSyncResponse;
import com.reprocampo.backend.dto.sync.SyncItemRequest;
import com.reprocampo.backend.dto.sync.SyncItemResponse;
import com.reprocampo.backend.dto.sync.SyncRequest;
import com.reprocampo.backend.dto.sync.SyncResponse;
import com.reprocampo.backend.dto.visita.VisitaRequest;
import com.reprocampo.backend.entity.Animal;
import com.reprocampo.backend.entity.EventoReprodutivo;
import com.reprocampo.backend.entity.Propriedade;
import com.reprocampo.backend.entity.TipoOperacaoSincronizacao;
import com.reprocampo.backend.entity.Usuario;
import com.reprocampo.backend.entity.Visita;
import com.reprocampo.backend.exception.ResourceNotFoundException;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class SyncService {

    private final UsuarioAutenticadoProvider authenticatedUserProvider;
    private final IdempotencyService idempotencyService;
    private final PropriedadeService propriedadeService;
    private final AnimalService animalService;
    private final EventoReprodutivoService eventoReprodutivoService;
    private final VisitaService visitService;
    private final RegistroExcluidoService deletedRecordService;
    private final ObjectMapper objectMapper;

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
                propriedadeService.listUpdatedSince(user.getId(), baseInstant),
                animalService.listUpdatedSince(user.getId(), baseInstant),
                visitService.listUpdatedSince(user.getId(), baseInstant),
                eventoReprodutivoService.listUpdatedSince(user.getId(), baseInstant),
                deletedRecordService.findDeletedSince(user.getId(), baseInstant)
        );
    }

    private SyncItemResponse process(SyncItemRequest item, Usuario user) {
        return idempotencyService.findByMutationKey(item.chaveMutacao())
                .map(mutation -> new SyncItemResponse(
                        item.chaveMutacao(),
                        "SYNCED",
                        mutation.getIdEntidade(),
                        null,
                        "Operacao reaproveitada por idempotencia"
                ))
                .orElseGet(() -> execute(item, user));
    }

    private SyncItemResponse execute(SyncItemRequest item, Usuario user) {
        if ("property".equalsIgnoreCase(item.entity())) {
            if (item.operationType() == TipoOperacaoSincronizacao.DELETE) {
                return deleteProperty(item, user);
            }
            Propriedade property = handleProperty(item, user);
            idempotencyService.register(item.chaveMutacao(), item.entity(), user.getId(), property.getId());
            return new SyncItemResponse(item.chaveMutacao(), "SYNCED", property.getId(), property.getIdExterno(), "Sincronizado com sucesso");
        }

        if ("animal".equalsIgnoreCase(item.entity())) {
            if (item.operationType() == TipoOperacaoSincronizacao.DELETE) {
                return deleteAnimal(item, user);
            }
            Animal animal = handleAnimal(item, user);
            idempotencyService.register(item.chaveMutacao(), item.entity(), user.getId(), animal.getId());
            return new SyncItemResponse(item.chaveMutacao(), "SYNCED", animal.getId(), animal.getIdExterno(), "Sincronizado com sucesso");
        }

        if ("event".equalsIgnoreCase(item.entity())) {
            if (item.operationType() == TipoOperacaoSincronizacao.DELETE) {
                return deleteEvent(item, user);
            }
            EventoReprodutivo event = handleEvent(item, user);
            idempotencyService.register(item.chaveMutacao(), item.entity(), user.getId(), event.getId());
            return new SyncItemResponse(item.chaveMutacao(), "SYNCED", event.getId(), event.getIdExterno(), "Sincronizado com sucesso");
        }

        if ("visit".equalsIgnoreCase(item.entity())) {
            if (item.operationType() == TipoOperacaoSincronizacao.DELETE) {
                return deleteVisit(item, user);
            }
            Visita visit = handleVisit(item, user);
            idempotencyService.register(item.chaveMutacao(), item.entity(), user.getId(), visit.getId());
            return new SyncItemResponse(item.chaveMutacao(), "SYNCED", visit.getId(), visit.getIdExterno(), "Sincronizado com sucesso");
        }

        throw new IllegalArgumentException("Entidade de sincronizacao nao suportada: " + item.entity());
    }

    private Propriedade handleProperty(SyncItemRequest item, Usuario user) {
        PropriedadeRequest request = objectMapper.convertValue(item.payload(), PropriedadeRequest.class);
        return propriedadeService.upsertForSync(request, item.dataAtualizacaoCliente(), user);
    }

    private Animal handleAnimal(SyncItemRequest item, Usuario user) {
        AnimalRequest request = objectMapper.convertValue(item.payload(), AnimalRequest.class);
        return animalService.upsertForSync(request, item.dataAtualizacaoCliente(), user);
    }

    private EventoReprodutivo handleEvent(SyncItemRequest item, Usuario user) {
        EventoReprodutivoRequest request = objectMapper.convertValue(item.payload(), EventoReprodutivoRequest.class);
        return eventoReprodutivoService.upsertForSync(request, item.dataAtualizacaoCliente(), user);
    }

    private Visita handleVisit(SyncItemRequest item, Usuario user) {
        VisitaRequest request = objectMapper.convertValue(item.payload(), VisitaRequest.class);
        return visitService.upsertForSync(request, item.dataAtualizacaoCliente(), user);
    }

    private SyncItemResponse deleteProperty(SyncItemRequest item, Usuario user) {
        DeleteRequest request = objectMapper.convertValue(item.payload(), DeleteRequest.class);
        return deleteEntity(item, user, request.idExterno(), "property", () -> propriedadeService.deleteByExternalId(request.idExterno(), user),
                () -> propriedadeService.getByExternalId(request.idExterno(), user.getId()).getId());
    }

    private SyncItemResponse deleteAnimal(SyncItemRequest item, Usuario user) {
        DeleteRequest request = objectMapper.convertValue(item.payload(), DeleteRequest.class);
        return deleteEntity(item, user, request.idExterno(), "animal", () -> animalService.deleteByExternalId(request.idExterno(), user),
                () -> animalService.getByExternalId(request.idExterno(), user.getId()).getId());
    }

    private SyncItemResponse deleteEvent(SyncItemRequest item, Usuario user) {
        DeleteRequest request = objectMapper.convertValue(item.payload(), DeleteRequest.class);
        return deleteEntity(item, user, request.idExterno(), "event", () -> eventoReprodutivoService.deleteByExternalId(request.idExterno(), user),
                () -> eventoReprodutivoService.getByExternalId(request.idExterno(), user.getId()).getId());
    }

    private SyncItemResponse deleteVisit(SyncItemRequest item, Usuario user) {
        DeleteRequest request = objectMapper.convertValue(item.payload(), DeleteRequest.class);
        return deleteEntity(item, user, request.idExterno(), "visit", () -> visitService.deleteByExternalId(request.idExterno(), user),
                () -> visitService.getByExternalId(request.idExterno(), user.getId()).getId());
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
            deletedRecordService.registerDeletion(nomeEntidade, idExterno, user.getId());
        }

        idempotencyService.register(item.chaveMutacao(), item.entity(), user.getId(), idEntidade);
        return new SyncItemResponse(item.chaveMutacao(), "SYNCED", idEntidade, idExterno, "Sincronizado com sucesso");
    }

    @FunctionalInterface
    private interface EntityIdSupplier {
        Long get();
    }
}
