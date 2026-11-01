import 'package:cysvet_app/local/sync_queue_store.dart';
import 'package:cysvet_app/models/auth_session_model.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';
import 'package:cysvet_app/providers/auth_state.dart';
import 'package:cysvet_app/providers/offline_first.dart';
import 'package:cysvet_app/providers/visit_in_progress_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guarda os metadados em memória, no lugar do SQLite do aparelho.
class _MemoryStore extends SyncQueueStore {
  _MemoryStore() : super(() => throw UnimplementedError());

  final values = <String, String?>{};

  @override
  Future<String?> readMeta(String key) async => values[key];

  @override
  Future<void> writeMeta(String key, String? value) async {
    values[key] = value;
  }
}

class _NoSession extends AuthSessionNotifier {
  @override
  AuthSessionModel? build() => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final visit = VisitInProgress(
    route: '/visitas/nova',
    propertyId: 7,
    propertyName: 'Sítio Boa Água',
    dataVisita: '01/11/2026',
    entries: [
      VisitAnimalEntryModel(
        animalId: 3,
        animalCodigo: '103',
        situacaoReprodutiva: 'prenha',
        dataUltimaIa: DateTime(2026, 11, 1),
        numeroIaRecebida: 2,
      ),
    ],
    reviewedAnimalIds: const {3},
    selectedAnimalId: 3,
    iaHistory: {
      3: VisitIaHistorySnapshot(dates: [DateTime(2026, 8, 10)], totalIas: 1),
    },
  );

  ProviderContainer containerWith(_MemoryStore store) {
    final container = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith(_NoSession.new),
        offlineScopeProvider.overrideWithValue(
          const OfflineScope(companyId: 1, userId: 2),
        ),
        syncQueueStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('ida e volta em JSON preserva a coleta', () {
    final restored = VisitInProgress.fromJson(visit.toJson());

    expect(restored.route, '/visitas/nova');
    expect(restored.propertyId, 7);
    expect(restored.propertyName, 'Sítio Boa Água');
    expect(restored.dataVisita, '01/11/2026');
    expect(restored.reviewedAnimalIds, {3});
    expect(restored.selectedAnimalId, 3);
    final entry = restored.entries.single;
    expect(entry.animalCodigo, '103');
    expect(entry.situacaoReprodutiva, 'prenha');
    // O mapper grava em UTC; o dia do calendário é o mesmo.
    expect(
      DateUtils.dateOnly(entry.dataUltimaIa!.toLocal()),
      DateTime(2026, 11, 1),
    );
    expect(entry.numeroIaRecebida, 2);
    expect(restored.iaHistory[3]!.dates, [DateTime(2026, 8, 10)]);
    expect(restored.iaHistory[3]!.totalIas, 1);
  });

  test('visita gravada no aparelho volta quando o app é reaberto', () async {
    final store = _MemoryStore();
    final first = containerWith(store);
    first.read(visitInProgressProvider.notifier).remember(visit);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    expect(store.values['visit_in_progress.1.2'], isNotNull);
    first.dispose();

    // Outro processo: só o que ficou gravado.
    final second = containerWith(store);
    second.read(visitInProgressProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final restored = second.read(visitInProgressProvider);
    expect(restored, isNotNull);
    expect(restored!.entries.single.situacaoReprodutiva, 'prenha');
    expect(restored.collectedCount, 1);
  });

  test('salvar ou cancelar apaga a visita gravada', () async {
    final store = _MemoryStore();
    final container = containerWith(store);
    final notifier = container.read(visitInProgressProvider.notifier);
    notifier.remember(visit);
    await Future<void>.delayed(const Duration(milliseconds: 800));

    notifier.clear();
    await Future<void>.delayed(Duration.zero);

    expect(store.values['visit_in_progress.1.2'], isNull);
  });
}
