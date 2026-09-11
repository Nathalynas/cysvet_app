import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../filters/visit_filter.dart';
import 'package:cysvet_app/providers/auth_state.dart';
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

final visitsProvider = FutureProvider<List<VisitSummaryModel>>((ref) async {
  final session = ref.watch(authSessionProvider);
  final propertyId = ref.watch(visitsPropertyFilterProvider);
  final localItems = ref.watch(localVisitsProvider);

  if (session == null) {
    throw StateError('Sessão indisponível.');
  }

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

class VisitsController {
  const VisitsController(this._ref);

  final Ref _ref;

  Future<VisitSummaryModel> save(VisitSummaryModel visit) async {
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
