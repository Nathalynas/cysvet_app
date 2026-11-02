import 'package:cysvet_app/core/enums/sync_status_enum.dart';
import 'package:cysvet_app/local/local_database.dart';
import 'package:cysvet_app/local/sync_queue_store.dart';
import 'package:cysvet_app/local/visits_local_store.dart';
import 'package:cysvet_app/models/sync_models.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  late SyncQueueStore queue;
  late VisitsLocalStore visits;

  setUp(() async {
    db = await LocalDatabase.openWith(databaseFactoryFfi, inMemoryDatabasePath);
    queue = SyncQueueStore(() async => db);
    visits = VisitsLocalStore(() async => db);
  });

  tearDown(() => db.close());

  VisitSummaryModel visita(String idExterno) => VisitSummaryModel(
    id: 0,
    idExterno: idExterno,
    idPropriedade: 1,
    idExternoPropriedade: 'prop-1',
    dataVisita: DateTime(2026, 11, 1),
    animais: const [],
  );

  Future<SyncMutation> enfileirar(SyncOperationType operation) {
    return queue.enqueue(
      companyId: 1,
      userId: 1,
      entity: SyncEntity.visit,
      entityIdExterno: 'v-1',
      operation: operation,
      payload: const {'idExterno': 'v-1'},
    );
  }

  test('CREATE seguido de UPDATE vira uma mutação só, mantendo CREATE', () async {
    await enfileirar(SyncOperationType.create);
    await enfileirar(SyncOperationType.update);

    final fila = await queue.listSendable(companyId: 1, userId: 1);
    expect(fila, hasLength(1));
    expect(fila.single.operation, SyncOperationType.create);
  });

  test('envio interrompido volta para a fila ao abrir o app', () async {
    final mutation = await enfileirar(SyncOperationType.create);
    await queue.markSyncing([mutation.id]);
    expect(await queue.listSendable(companyId: 1, userId: 1), isEmpty);

    await queue.recoverInterrupted();

    final fila = await queue.listSendable(companyId: 1, userId: 1);
    expect(fila.single.chaveMutacao, mutation.chaveMutacao);
    expect(fila.single.attempts, 1);
  });

  test('falha dentro da transação não deixa visita finalizada sem fila', () async {
    await expectLater(
      visits.saveLocal(
        companyId: 1,
        visit: visita('v-falha'),
        localStatus: VisitLocalStatus.finalized,
        syncStatus: SyncStatusEnum.pending,
        inSameTransaction: (txn, saved) async {
          throw StateError('app morreu no meio');
        },
      ),
      throwsStateError,
    );

    expect(await visits.findByIdExterno('v-falha'), isNull);
    expect(await queue.countPending(companyId: 1, userId: 1), 0);
  });

  test('visita finalizada sem mutação é encontrada para reenfileirar', () async {
    await visits.saveLocal(
      companyId: 1,
      visit: visita('v-orfa'),
      localStatus: VisitLocalStatus.finalized,
      syncStatus: SyncStatusEnum.pending,
    );
    await visits.saveLocal(
      companyId: 1,
      visit: visita('v-rascunho'),
      localStatus: VisitLocalStatus.draft,
      syncStatus: SyncStatusEnum.localOnly,
    );

    final orfas = await visits.listFinalizedWithoutMutation(1);
    expect(orfas.map((r) => r.visit.idExterno), ['v-orfa']);
  });
}
