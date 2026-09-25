import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/api/sync_api.dart';
import 'package:cysvet_app/api/visits_api.dart';
import 'package:cysvet_app/core/enums/sync_status_enum.dart';
import 'package:cysvet_app/core/network/api_error.dart';
import 'package:cysvet_app/local/animals_local_store.dart';
import 'package:cysvet_app/local/properties_local_store.dart';
import 'package:cysvet_app/local/sync_queue_store.dart';
import 'package:cysvet_app/local/visits_local_store.dart';
import 'package:cysvet_app/models/animal_summary_model.dart';
import 'package:cysvet_app/models/property_summary_model.dart';
import 'package:cysvet_app/models/sync_models.dart';
import 'package:cysvet_app/providers/auth_state.dart';
import 'package:cysvet_app/providers/connectivity_provider.dart';
import 'package:cysvet_app/providers/offline_first.dart';
import 'package:cysvet_app/providers/properties_provider.dart';
import 'package:cysvet_app/providers/visits_provider.dart';

final syncControllerProvider = NotifierProvider<SyncController, SyncState>(
  SyncController.new,
);

class SyncState {
  const SyncState({
    this.enabled = false,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.errorCount = 0,
    this.lastSyncedAt,
    this.lastMessage,
  });

  /// `false` fora do mobile ou sem sessão.
  final bool enabled;
  final bool isSyncing;

  /// Mutações ainda na fila (inclui as que falharam).
  final int pendingCount;
  final int errorCount;
  final DateTime? lastSyncedAt;

  /// Última mensagem relevante para o usuário (erro ou conflito).
  final String? lastMessage;

  SyncStatusEnum get status {
    if (isSyncing) return SyncStatusEnum.syncing;
    if (errorCount > 0) return SyncStatusEnum.error;
    if (pendingCount > 0) return SyncStatusEnum.pending;
    return SyncStatusEnum.synced;
  }

  SyncState copyWith({
    bool? isSyncing,
    int? pendingCount,
    int? errorCount,
    DateTime? lastSyncedAt,
    String? lastMessage,
    bool clearMessage = false,
  }) {
    return SyncState(
      enabled: enabled,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      errorCount: errorCount ?? this.errorCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastMessage: clearMessage ? null : lastMessage ?? this.lastMessage,
    );
  }
}

/// Orquestra a sincronização offline-first do mobile:
/// push da fila (`POST /api/sync`) seguido de pull incremental
/// (`GET /api/sync/pull?since=checkpoint`).
///
/// Dispara automaticamente ao abrir o app, ao voltar a conexão, após cada
/// gravação local e periodicamente enquanto houver pendências.
class SyncController extends Notifier<SyncState> {
  static const _batchSize = 50;
  static const _retryInterval = Duration(minutes: 2);

  bool _running = false;
  bool _rerunRequested = false;

  @override
  SyncState build() {
    final scope = ref.watch(offlineScopeProvider);
    if (scope == null) return const SyncState();

    ref.listen<AsyncValue<bool>>(isOnlineProvider, (previous, next) {
      // A primeira leitura já é coberta pelo sync de abertura abaixo.
      final wasOnline = previous?.asData?.value;
      if (wasOnline == null) return;
      if (next.asData?.value == true && !wasOnline) {
        unawaited(syncNow());
      }
    });

    final timer = Timer.periodic(_retryInterval, (_) {
      if (state.pendingCount > 0) unawaited(syncNow());
    });
    ref.onDispose(timer.cancel);

    Future.microtask(() async {
      await ref.read(syncQueueStoreProvider).recoverInterrupted();
      await notifyLocalChange();
      await syncNow();
    });

    return const SyncState(enabled: true);
  }

  /// Chamado após gravar algo localmente: atualiza contadores e telas.
  Future<void> notifyLocalChange() async {
    final scope = ref.read(offlineScopeProvider);
    if (scope == null) return;

    await _refreshCounts(scope);
    await _refreshLocalMirror(scope);
    ref.invalidate(visitsProvider);
    ref.invalidate(localVisitRecordsProvider);
  }

  /// Sincroniza agora. Usado automaticamente e pelo botão "Sincronizar".
  /// Retorna `false` quando não foi possível falar com o backend.
  Future<bool> syncNow() async {
    final scope = ref.read(offlineScopeProvider);
    if (scope == null) return false;

    if (_running) {
      _rerunRequested = true;
      return true;
    }

    if (ref.read(isOfflineProvider)) {
      state = state.copyWith(
        lastMessage: 'Sem conexão. Os dados continuam salvos no aparelho.',
      );
      return false;
    }

    _running = true;
    state = state.copyWith(isSyncing: true, clearMessage: true);
    var reachedBackend = false;

    try {
      await ref.read(authSessionProvider.notifier).refreshIfExpired();
      final conflicts = await _push(scope);
      await _pull(scope);
      reachedBackend = true;
      state = state.copyWith(
        lastSyncedAt: DateTime.now(),
        lastMessage: conflicts > 0
            ? '$conflicts registro(s) já tinham versão mais recente no servidor; '
                  'a versão do servidor foi mantida.'
            : null,
      );
    } catch (error) {
      state = state.copyWith(
        lastMessage: isNetworkError(error)
            ? 'Não foi possível falar com o servidor. '
                  'Os dados continuam salvos no aparelho.'
            : describeError(error),
      );
    } finally {
      _running = false;
      if (ref.mounted) {
        state = state.copyWith(isSyncing: false);
        await notifyLocalChange();
        ref.invalidate(propertiesProvider);
      }
    }

    if (_rerunRequested && ref.mounted) {
      _rerunRequested = false;
      return syncNow();
    }
    return reachedBackend;
  }

  /// Envia a fila. Retorna quantos itens tiveram conflito (servidor venceu).
  Future<int> _push(OfflineScope scope) async {
    final queue = ref.read(syncQueueStoreProvider);
    final visitsStore = ref.read(visitsLocalStoreProvider);
    final mutations = await queue.listSendable(
      companyId: scope.companyId,
      userId: scope.userId,
    );
    if (mutations.isEmpty) return 0;

    await queue.markSyncing(_ids(mutations));
    await visitsStore.updateSyncStatus(
      _visitIds(mutations),
      SyncStatusEnum.syncing,
    );
    await _refreshLocalMirror(scope);
    ref.invalidate(localVisitRecordsProvider);

    var conflicts = 0;
    for (var start = 0; start < mutations.length; start += _batchSize) {
      final batch = mutations.sublist(
        start,
        (start + _batchSize).clamp(0, mutations.length),
      );
      try {
        conflicts += await _pushBatch(batch);
      } catch (error) {
        // Sem conexão / sessão inválida: tudo o que não foi enviado volta
        // para a fila como pendente, sem marcar erro.
        final remaining = <SyncMutation>[];
        for (final mutation in mutations.sublist(start)) {
          // No reenvio item a item, parte do lote pode já ter sido aplicada.
          if (await queue.hasMutationsFor(
            mutation.entity,
            mutation.entityIdExterno,
          )) {
            remaining.add(mutation);
          }
        }
        await queue.markPending(_ids(remaining));
        await visitsStore.updateSyncStatus(
          _visitIds(remaining),
          SyncStatusEnum.pending,
        );
        rethrow;
      }
    }
    return conflicts;
  }

  Future<int> _pushBatch(List<SyncMutation> batch) async {
    try {
      final results = await ref.read(syncRepositoryProvider).push(batch);
      return _applyResults(batch, results);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final rejectedByServer =
          !isNetworkError(error) && statusCode != null && statusCode != 401;
      if (!rejectedByServer) rethrow;

      // O backend devolve REJECTED por item; um erro no lote inteiro indica
      // envelope inválido ou servidor antigo. Reenvia item a item para isolar
      // o problemático sem travar os demais.
      if (batch.length > 1) {
        var conflicts = 0;
        for (final mutation in batch) {
          conflicts += await _pushBatch([mutation]);
        }
        return conflicts;
      }

      final message = describeError(error);
      await ref.read(syncQueueStoreProvider).markError(_ids(batch), message);
      await ref
          .read(visitsLocalStoreProvider)
          .updateSyncStatus(
            _visitIds(batch),
            SyncStatusEnum.error,
            error: message,
          );
      return 0;
    }
  }

  Future<int> _applyResults(
    List<SyncMutation> batch,
    List<SyncItemResult> results,
  ) async {
    final queue = ref.read(syncQueueStoreProvider);
    final visitsStore = ref.read(visitsLocalStoreProvider);
    final byKey = {for (final result in results) result.chaveMutacao: result};

    final accepted = <SyncMutation>[];
    final missing = <SyncMutation>[];
    final rejected = <SyncMutation, String>{};
    var conflicts = 0;
    for (final mutation in batch) {
      final result = byKey[mutation.chaveMutacao];
      if (result?.status == SyncItemStatus.rejected) {
        rejected[mutation] = result?.message ?? 'O servidor recusou este item.';
        continue;
      }
      if (result == null || !result.status.isAccepted) {
        missing.add(mutation);
        continue;
      }
      if (result.status == SyncItemStatus.conflictServerWins) conflicts++;
      accepted.add(mutation);
    }

    await queue.deleteByIds(_ids(accepted));
    for (final mutation in accepted) {
      if (mutation.entity != SyncEntity.visit) continue;

      // Se o usuário editou a visita durante o envio, já existe uma mutação
      // mais nova na fila; a visita continua pendente até ela ser enviada.
      final hasNewer = await queue.hasMutationsFor(
        SyncEntity.visit,
        mutation.entityIdExterno,
      );
      if (hasNewer) {
        await visitsStore.updateSyncStatus([
          mutation.entityIdExterno,
        ], SyncStatusEnum.pending);
      } else {
        await visitsStore.markSynced(
          mutation.entityIdExterno,
          serverId: byKey[mutation.chaveMutacao]?.idEntidade,
        );
      }
    }

    if (missing.isNotEmpty) {
      const message = 'O servidor não confirmou o recebimento deste item.';
      await queue.markError(_ids(missing), message);
      await visitsStore.updateSyncStatus(
        _visitIds(missing),
        SyncStatusEnum.error,
        error: message,
      );
    }
    for (final entry in rejected.entries) {
      await queue.markError(_ids([entry.key]), entry.value);
      await visitsStore.updateSyncStatus(
        _visitIds([entry.key]),
        SyncStatusEnum.error,
        error: entry.value,
      );
    }
    return conflicts;
  }

  Future<void> _pull(OfflineScope scope) async {
    final queue = ref.read(syncQueueStoreProvider);
    final checkpointKey = 'pull_checkpoint.${scope.companyId}.${scope.userId}';
    final since = DateTime.tryParse(await queue.readMeta(checkpointKey) ?? '');

    final result = await ref.read(syncRepositoryProvider).pull(since: since);

    await ref
        .read(propertiesLocalStoreProvider)
        .upsertAll(
          scope.companyId,
          result.properties
              .map(PropertySummaryModelMapper.fromMap)
              .toList(growable: false),
        );
    await ref
        .read(animalsLocalStoreProvider)
        .upsertAll(
          scope.companyId,
          result.animals
              .map(AnimalSummaryModelMapper.fromMap)
              .toList(growable: false),
        );

    final visitsRepository = ref.read(visitsRepositoryProvider);
    final visitsStore = ref.read(visitsLocalStoreProvider);
    await visitsStore.upsertFromServer(
      scope.companyId,
      result.visits.map(visitsRepository.toModel).toList(growable: false),
    );
    await visitsStore.deleteSyncedByIdExterno(
      result.deletedRecords
          .where((record) => record.entity == SyncEntity.visit)
          .map((record) => record.idExterno)
          .toList(growable: false),
    );
    // TODO BACKEND: eventos reprodutivos (`events`) do pull ainda não são
    // usados no app — os eventos da visita trafegam dentro de
    // `VisitaRequest.animais`. Se o backend passar a derivar
    // EventoReprodutivo a partir da visita, reconciliar aqui também.

    if (result.serverTime != null) {
      await queue.writeMeta(
        checkpointKey,
        result.serverTime!.toUtc().toIso8601String(),
      );
    }
  }

  Future<void> _refreshCounts(OfflineScope scope) async {
    final queue = ref.read(syncQueueStoreProvider);
    final pending = await queue.countPending(
      companyId: scope.companyId,
      userId: scope.userId,
    );
    final errors = await queue.countErrors(
      companyId: scope.companyId,
      userId: scope.userId,
    );
    if (!ref.mounted) return;
    state = state.copyWith(pendingCount: pending, errorCount: errors);
  }

  /// Espelha visitas ainda não sincronizadas no `localVisitsProvider`, que já
  /// é consumido por dashboard, detalhes da propriedade e relatório.
  Future<void> _refreshLocalMirror(OfflineScope scope) async {
    final records = await ref
        .read(visitsLocalStoreProvider)
        .list(scope.companyId);
    if (!ref.mounted) return;
    ref
        .read(localVisitsProvider.notifier)
        .replaceAll(
          records
              .where((record) => record.hasLocalChanges)
              .map((record) => record.visit),
        );
  }

  List<int> _ids(List<SyncMutation> mutations) {
    return mutations.map((mutation) => mutation.id).toList(growable: false);
  }

  List<String> _visitIds(List<SyncMutation> mutations) {
    return mutations
        .where((mutation) => mutation.entity == SyncEntity.visit)
        .map((mutation) => mutation.entityIdExterno)
        .toList(growable: false);
  }
}
