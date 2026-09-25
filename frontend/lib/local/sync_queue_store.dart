import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:cysvet_app/local/local_database.dart';
import 'package:cysvet_app/models/sync_models.dart';

final syncQueueStoreProvider = Provider<SyncQueueStore>((ref) {
  return SyncQueueStore(() => ref.read(localDatabaseProvider.future));
});

/// Fila de mutações pendentes (`sync_mutations`) e metadados de sync
/// (`sync_meta`, ex.: checkpoint do pull por empresa).
class SyncQueueStore {
  SyncQueueStore(this._database);

  final Future<Database> Function() _database;

  /// Enfileira a mutação da entidade. Mutações ainda não enviadas da mesma
  /// entidade são substituídas: o payload mais recente já contém o estado
  /// completo, e o backend faz upsert por `idExterno`.
  ///
  /// Cada enfileiramento recebe uma `chaveMutacao` nova. Reusar a chave de uma
  /// mutação que talvez já tenha chegado ao servidor faria o backend responder
  /// REPLAYED e descartar a edição mais nova.
  Future<SyncMutation> enqueue({
    required int companyId,
    required int userId,
    required String entity,
    required String entityIdExterno,
    required SyncOperationType operation,
    required Map<String, dynamic> payload,
  }) async {
    final db = await _database();
    final now = DateTime.now().toUtc();
    final mutation = SyncMutation(
      id: 0,
      chaveMutacao: const Uuid().v4(),
      companyId: companyId,
      userId: userId,
      entity: entity,
      entityIdExterno: entityIdExterno,
      operation: operation,
      payload: payload,
      clientUpdatedAt: now,
      status: SyncMutationStatus.pending,
      attempts: 0,
    );

    final id = await db.transaction((txn) async {
      final previous = await txn.query(
        'sync_mutations',
        columns: ['operation'],
        where:
            'entity = ? AND entity_id_externo = ? AND company_id = ? AND status != ?',
        whereArgs: [
          entity,
          entityIdExterno,
          companyId,
          SyncMutationStatus.syncing.name,
        ],
      );
      await txn.delete(
        'sync_mutations',
        where:
            'entity = ? AND entity_id_externo = ? AND company_id = ? AND status != ?',
        whereArgs: [
          entity,
          entityIdExterno,
          companyId,
          SyncMutationStatus.syncing.name,
        ],
      );

      // Um CREATE que nunca foi confirmado continua sendo CREATE.
      final keepsCreate = previous.any(
        (row) => row['operation'] == SyncOperationType.create.apiValue,
      );
      final effective = keepsCreate && operation == SyncOperationType.update
          ? SyncOperationType.create
          : operation;

      return txn.insert(
        'sync_mutations',
        mutation.copyWith(operation: effective).toRow(now),
      );
    });

    return mutation.copyWith(id: id);
  }

  /// Mutações a enviar, na ordem oficial do contrato
  /// (property -> lot -> animal -> visit -> event) e, dentro da entidade, na
  /// ordem de criação. Inclui as que falharam antes (nova tentativa).
  Future<List<SyncMutation>> listSendable({
    required int companyId,
    required int userId,
  }) async {
    final db = await _database();
    final rows = await db.query(
      'sync_mutations',
      where: 'company_id = ? AND user_id = ? AND status != ?',
      whereArgs: [companyId, userId, SyncMutationStatus.syncing.name],
      orderBy: 'id ASC',
    );

    final mutations = rows.map(SyncMutation.fromRow).toList();
    mutations.sort((a, b) {
      final order = a.entityOrder.compareTo(b.entityOrder);
      return order != 0 ? order : a.id.compareTo(b.id);
    });
    return mutations;
  }

  Future<int> countPending({
    required int companyId,
    required int userId,
  }) async {
    final db = await _database();
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM sync_mutations '
      'WHERE company_id = ? AND user_id = ?',
      [companyId, userId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> countErrors({required int companyId, required int userId}) async {
    final db = await _database();
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM sync_mutations '
      'WHERE company_id = ? AND user_id = ? AND status = ?',
      [companyId, userId, SyncMutationStatus.error.name],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<bool> hasMutationsFor(String entity, String entityIdExterno) async {
    final db = await _database();
    final result = await db.query(
      'sync_mutations',
      columns: ['id'],
      where: 'entity = ? AND entity_id_externo = ?',
      whereArgs: [entity, entityIdExterno],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<void> markSyncing(List<int> ids) {
    return _updateStatus(ids, {
      'status': SyncMutationStatus.syncing.name,
    }, incrementAttempts: true);
  }

  /// Volta para a fila sem marcar erro (ex.: sem conexão no meio do envio).
  Future<void> markPending(List<int> ids) {
    return _updateStatus(ids, {'status': SyncMutationStatus.pending.name});
  }

  Future<void> markError(List<int> ids, String message) {
    return _updateStatus(ids, {
      'status': SyncMutationStatus.error.name,
      'last_error': message,
    });
  }

  Future<void> deleteByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await _database();
    await db.delete(
      'sync_mutations',
      where: 'id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
  }

  /// Chamado ao abrir o app: mutações que ficaram em `syncing` (app fechado
  /// no meio do envio) voltam para a fila. Reenviar é seguro: o backend
  /// deduplica por `chaveMutacao` e faz upsert por `idExterno`.
  Future<void> recoverInterrupted() async {
    final db = await _database();
    await db.update(
      'sync_mutations',
      {'status': SyncMutationStatus.pending.name},
      where: 'status = ?',
      whereArgs: [SyncMutationStatus.syncing.name],
    );
  }

  Future<String?> readMeta(String key) async {
    final db = await _database();
    final rows = await db.query(
      'sync_meta',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> writeMeta(String key, String? value) async {
    final db = await _database();
    await db.insert('sync_meta', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _updateStatus(
    List<int> ids,
    Map<String, Object?> values, {
    bool incrementAttempts = false,
  }) async {
    if (ids.isEmpty) return;
    final db = await _database();
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.transaction((txn) async {
      await txn.update(
        'sync_mutations',
        values,
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
      if (incrementAttempts) {
        await txn.rawUpdate(
          'UPDATE sync_mutations SET attempts = attempts + 1 '
          'WHERE id IN ($placeholders)',
          ids,
        );
      }
    });
  }
}

extension on SyncMutation {
  Map<String, Object?> toRow(DateTime createdAt) {
    return {
      'chave_mutacao': chaveMutacao,
      'company_id': companyId,
      'user_id': userId,
      'entity': entity,
      'entity_id_externo': entityIdExterno,
      'operation': operation.apiValue,
      'payload': jsonEncode(payload),
      'client_updated_at': clientUpdatedAt.toIso8601String(),
      'status': status.name,
      'attempts': attempts,
      'last_error': lastError,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
