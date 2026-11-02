import 'package:cysvet_app/models/sync_models.dart';
import 'package:flutter_test/flutter_test.dart';

SyncMutation _mutacao(int id, {int animais = 0}) => SyncMutation(
  id: id,
  chaveMutacao: 'k$id',
  companyId: 1,
  userId: 1,
  entity: SyncEntity.visit,
  entityIdExterno: 'v$id',
  operation: SyncOperationType.create,
  payload: {
    'animais': [
      for (var i = 0; i < animais; i++) {'animalCodigo': '$i', 'obs': 'x' * 900},
    ],
  },
  clientUpdatedAt: DateTime.utc(2026, 11, 1),
  status: SyncMutationStatus.pending,
  attempts: 0,
);

void main() {
  test('no máximo 10 itens por lote', () {
    final lotes = buildSyncBatches([for (var i = 0; i < 23; i++) _mutacao(i)]);
    expect(lotes.map((l) => l.length), [10, 10, 3]);
  });

  test('visitas grandes vão em lotes menores pelo tamanho', () {
    // ~300 animais ≈ 280 KB: cada uma passa do limite e vai sozinha.
    final grandes = [for (var i = 0; i < 3; i++) _mutacao(i, animais: 300)];
    final lotes = buildSyncBatches(grandes);
    expect(lotes.map((l) => l.length), [1, 1, 1]);
  });

  test('a ordem da fila é mantida', () {
    final fila = [for (var i = 0; i < 12; i++) _mutacao(i)];
    final lotes = buildSyncBatches(fila);
    expect(lotes.expand((l) => l).map((m) => m.id), [for (var i = 0; i < 12; i++) i]);
  });
}
