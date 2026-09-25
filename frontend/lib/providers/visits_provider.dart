import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../filters/visit_filter.dart';
import 'package:cysvet_app/core/enums/sync_status_enum.dart';
import 'package:cysvet_app/core/network/api_error.dart';
import 'package:cysvet_app/local/animals_local_store.dart';
import 'package:cysvet_app/local/sync_queue_store.dart';
import 'package:cysvet_app/local/visits_local_store.dart';
import 'package:cysvet_app/models/animal_summary_model.dart';
import 'package:cysvet_app/models/resumo_reprodutivo_preview.dart';
import 'package:cysvet_app/models/sync_models.dart';
import 'package:cysvet_app/providers/animals_provider.dart';
import 'package:cysvet_app/providers/auth_state.dart';
import 'package:cysvet_app/providers/offline_first.dart';
import 'package:cysvet_app/providers/sync_provider.dart';
import 'package:cysvet_app/api/visits_api.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';

final visitsBusyProvider = NotifierProvider<VisitsBusyNotifier, bool>(
  VisitsBusyNotifier.new,
);

final visitsReportBusyProvider =
    NotifierProvider<VisitsReportBusyNotifier, bool>(
      VisitsReportBusyNotifier.new,
    );

final visitsControllerProvider = Provider<VisitsController>((ref) {
  return VisitsController(ref);
});

final savedVisitProvider =
    NotifierProvider<SavedVisitNotifier, VisitSummaryModel?>(
      SavedVisitNotifier.new,
    );

final localVisitsProvider =
    NotifierProvider<LocalVisitsNotifier, Map<int, VisitSummaryModel>>(
      LocalVisitsNotifier.new,
    );

/// Estado local (rascunho / sync) das visitas do mobile, por `idExterno`.
/// Vazio fora do mobile.
final localVisitRecordsProvider = FutureProvider<Map<String, LocalVisitRecord>>(
  (ref) async {
    final scope = ref.watch(offlineScopeProvider);
    if (scope == null) return const {};

    final records = await ref
        .watch(visitsLocalStoreProvider)
        .list(scope.companyId);
    return {for (final record in records) record.visit.idExterno: record};
  },
);

final visitsProvider = FutureProvider<List<VisitSummaryModel>>((ref) async {
  final session = ref.watch(authSessionProvider);
  final propertyId = ref.watch(visitsPropertyFilterProvider);

  if (session == null) {
    throw StateError('Sessão indisponível.');
  }

  final scope = ref.watch(offlineScopeProvider);
  if (scope != null) {
    return _loadLocalFirstVisits(ref, scope, propertyId: propertyId);
  }

  final localItems = ref.watch(localVisitsProvider);

  final remoteItems = await ref
      .watch(visitsRepositoryProvider)
      .list(propertyId: propertyId);
  final merged =
      {
        for (final visit in remoteItems)
          visit.id: localItems[visit.id] ?? visit,
        ...localItems,
      }.values.where((visit) {
        return propertyId == null || visit.idPropriedade == propertyId;
      }).toList();
  merged.sort(_compareVisitsByDateDesc);
  return merged;
});

/// Mobile: atualiza o banco local com o backend quando possível e sempre
/// devolve a visão local (inclui rascunhos e visitas pendentes de sync).
Future<List<VisitSummaryModel>> _loadLocalFirstVisits(
  Ref ref,
  OfflineScope scope, {
  int? propertyId,
  bool includeDrafts = true,
}) async {
  final store = ref.read(visitsLocalStoreProvider);
  try {
    final remoteItems = await ref
        .read(visitsRepositoryProvider)
        .list(propertyId: propertyId);
    await store.removeSyncedMissingFrom(
      scope.companyId,
      remoteItems.map((visit) => visit.idExterno),
      propertyId: propertyId,
    );
    await store.upsertFromServer(scope.companyId, remoteItems);
  } catch (error) {
    if (!isNetworkError(error)) rethrow;
  }

  final records = await store.list(scope.companyId, propertyId: propertyId);
  final visits = records
      .where((record) => includeDrafts || !record.isDraft)
      .map((record) => record.visit)
      .toList();
  visits.sort(_compareVisitsByDateDesc);
  return visits;
}

class VisitsController {
  const VisitsController(this._ref);

  final Ref _ref;

  /// Visitas anteriores da propriedade (usadas no histórico do formulário).
  Future<List<VisitSummaryModel>> listByProperty(
    int propertyId, {
    String? excludeIdExterno,
  }) async {
    final scope = _ref.read(offlineScopeProvider);
    if (scope != null) {
      List<VisitSummaryModel> visits;
      try {
        visits = await _loadLocalFirstVisits(
          _ref,
          scope,
          propertyId: propertyId,
          includeDrafts: false,
        );
      } catch (_) {
        // Histórico é complementar: qualquer falha remota usa só o local.
        final records = await _ref
            .read(visitsLocalStoreProvider)
            .list(scope.companyId, propertyId: propertyId);
        visits = records
            .where((record) => !record.isDraft)
            .map((record) => record.visit)
            .toList(growable: false);
      }
      return visits
          .where((visit) => visit.idExterno != excludeIdExterno)
          .toList(growable: false);
    }

    final localVisits = _ref
        .read(localVisitsProvider)
        .values
        .where((visit) => visit.idPropriedade == propertyId)
        .toList(growable: false);

    try {
      final remoteVisits = await _ref
          .read(visitsRepositoryProvider)
          .list(propertyId: propertyId);
      return {
        for (final visit in remoteVisits) visit.id: visit,
        for (final visit in localVisits) visit.id: visit,
      }.values.toList(growable: false);
    } catch (error) {
      return localVisits;
    }
  }

  /// Visita salva no aparelho (mobile), para continuar/editar offline.
  Future<LocalVisitRecord?> findLocal(String idExterno) async {
    if (_ref.read(offlineScopeProvider) == null) return null;
    return _ref.read(visitsLocalStoreProvider).findByIdExterno(idExterno);
  }

  /// Finaliza a visita. No mobile grava localmente, enfileira a mutação e
  /// tenta sincronizar em seguida; fora do mobile mantém o fluxo online.
  Future<VisitSummaryModel> save(VisitSummaryModel visit) async {
    final scope = _ref.read(offlineScopeProvider);
    if (scope != null) {
      return _saveLocalFirst(scope, visit, finalize: true);
    }

    _ref.read(visitsBusyProvider.notifier).setBusy(true);
    try {
      final repository = _ref.read(visitsRepositoryProvider);
      final saved = visit.id <= 0
          ? await repository.create(visit)
          : await repository.update(visit);

      _ref.read(localVisitsProvider.notifier).remove(visit.id);
      _ref.invalidate(visitsProvider);
      _ref.read(localVisitsProvider.notifier).save(saved);
      _ref.read(savedVisitProvider.notifier).set(saved);
      return saved;
    } finally {
      _ref.read(visitsBusyProvider.notifier).setBusy(false);
    }
  }

  /// Salva a visita como rascunho só no aparelho (mobile). Não entra na
  /// fila de sincronização até ser finalizada.
  Future<VisitSummaryModel> saveDraft(VisitSummaryModel visit) async {
    final scope = _ref.read(offlineScopeProvider);
    if (scope == null) {
      throw StateError('Rascunho disponivel apenas no app mobile.');
    }
    return _saveLocalFirst(scope, visit, finalize: false);
  }

  Future<VisitSummaryModel> _saveLocalFirst(
    OfflineScope scope,
    VisitSummaryModel visit, {
    required bool finalize,
  }) async {
    _ref.read(visitsBusyProvider.notifier).setBusy(true);
    try {
      final user = _ref.read(authSessionProvider)?.user;
      final toSave = visit.copyWith(
        idUsuario: visit.idUsuario ?? user?.id,
        nomeUsuario: visit.nomeUsuario ?? user?.name,
      );

      final record = await _ref
          .read(visitsLocalStoreProvider)
          .saveLocal(
            companyId: scope.companyId,
            visit: toSave,
            localStatus: finalize
                ? VisitLocalStatus.finalized
                : VisitLocalStatus.draft,
            syncStatus: finalize
                ? SyncStatusEnum.pending
                : SyncStatusEnum.localOnly,
          );

      if (finalize) {
        await _ref
            .read(syncQueueStoreProvider)
            .enqueue(
              companyId: scope.companyId,
              userId: scope.userId,
              entity: SyncEntity.visit,
              entityIdExterno: record.visit.idExterno,
              operation: record.visit.id > 0
                  ? SyncOperationType.update
                  : SyncOperationType.create,
              payload: _ref
                  .read(visitsRepositoryProvider)
                  .toRequest(record.visit),
            );
        await _applyAnimalPreview(scope, record.visit);
      }

      final sync = _ref.read(syncControllerProvider.notifier);
      await sync.notifyLocalChange();
      if (finalize) unawaited(sync.syncNow());

      _ref.read(savedVisitProvider.notifier).set(record.visit);
      return record.visit;
    } finally {
      _ref.read(visitsBusyProvider.notifier).setBusy(false);
    }
  }

  // Mostra no aparelho o efeito da visita finalizada sobre os animais até o
  // servidor devolver, pelo pull, o resumo recalculado a partir dos eventos.
  Future<void> _applyAnimalPreview(
    OfflineScope scope,
    VisitSummaryModel visit,
  ) async {
    final store = _ref.read(animalsLocalStoreProvider);
    final animals = await store.list(
      scope.companyId,
      propertyId: visit.idPropriedade > 0 ? visit.idPropriedade : null,
    );
    final byId = {for (final animal in animals) animal.id: animal};
    final byIdExterno = {
      for (final animal in animals) animal.idExterno: animal,
    };

    final previews = <int, AnimalSummaryModel>{};
    for (final entry in visit.animais) {
      final animal = byId[entry.animalId] ?? byIdExterno[entry.animalIdExterno];
      if (animal == null) continue;
      previews[animal.id] = previewAnimalAfterVisit(
        previews[animal.id] ?? animal,
        entry,
      );
    }
    if (previews.isEmpty) return;

    await store.upsertAll(scope.companyId, previews.values.toList());
    _ref.invalidate(animalsProvider);
  }

  Future<Uint8List> downloadReportPdf(int visitId) async {
    _ref.read(visitsReportBusyProvider.notifier).setBusy(true);
    try {
      return _ref.read(visitsRepositoryProvider).downloadReportPdf(visitId);
    } finally {
      _ref.read(visitsReportBusyProvider.notifier).setBusy(false);
    }
  }
}

class LocalVisitsNotifier extends Notifier<Map<int, VisitSummaryModel>> {
  @override
  Map<int, VisitSummaryModel> build() => const {};

  void save(VisitSummaryModel visit) {
    final id = visit.id == 0 ? _nextLocalId() : visit.id;
    state = {...state, id: visit.copyWith(id: id)};
  }

  void remove(int id) {
    if (!state.containsKey(id)) return;
    final updated = {...state}..remove(id);
    state = updated;
  }

  /// Mobile: espelha as visitas não sincronizadas do banco local.
  void replaceAll(Iterable<VisitSummaryModel> visits) {
    state = {for (final visit in visits) visit.id: visit};
  }

  int _nextLocalId() {
    final ids = state.keys.where((id) => id < 0);
    if (ids.isEmpty) return -1;
    return ids.reduce((a, b) => a < b ? a : b) - 1;
  }
}

class SavedVisitNotifier extends Notifier<VisitSummaryModel?> {
  @override
  VisitSummaryModel? build() => null;

  void set(VisitSummaryModel visit) => state = visit;
}

class VisitsBusyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setBusy(bool value) => state = value;
}

class VisitsReportBusyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setBusy(bool value) => state = value;
}

int _compareVisitsByDateDesc(VisitSummaryModel a, VisitSummaryModel b) {
  final dateA = a.dataVisita;
  final dateB = b.dataVisita;
  if (dateA == null && dateB == null) return b.id.compareTo(a.id);
  if (dateA == null) return 1;
  if (dateB == null) return -1;
  final dateComparison = dateB.compareTo(dateA);
  if (dateComparison != 0) return dateComparison;
  return b.id.compareTo(a.id);
}
