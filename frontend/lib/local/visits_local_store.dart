import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'package:cysvet_app/api/api_response.dart';
import 'package:cysvet_app/core/enums/sync_status_enum.dart';
import 'package:cysvet_app/local/local_database.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';

final visitsLocalStoreProvider = Provider<VisitsLocalStore>((ref) {
  return VisitsLocalStore(() => ref.read(localDatabaseProvider.future));
});

// TODO BACKEND: `VisitaRequest` não tem status (rascunho/finalizada). Por isso
// o rascunho existe só no aparelho e a visita só é enviada ao finalizar.
enum VisitLocalStatus {
  /// Visita em andamento, salva só no aparelho (não entra na fila de sync).
  draft,

  /// Visita concluída pelo veterinário; entra na fila de sync.
  finalized;

  static VisitLocalStatus fromName(String? value) {
    return value == VisitLocalStatus.draft.name
        ? VisitLocalStatus.draft
        : VisitLocalStatus.finalized;
  }
}

class LocalVisitRecord {
  const LocalVisitRecord({
    required this.visit,
    required this.localStatus,
    required this.syncStatus,
    this.syncError,
  });

  /// `visit.id` é o id do servidor quando já sincronizada; caso contrário é
  /// um id local negativo (mesma convenção dos providers em memória).
  final VisitSummaryModel visit;
  final VisitLocalStatus localStatus;
  final SyncStatusEnum syncStatus;
  final String? syncError;

  bool get isDraft => localStatus == VisitLocalStatus.draft;
  bool get hasLocalChanges => syncStatus != SyncStatusEnum.synced;
}

/// Persistência local de visitas e dos eventos da visita (um evento por animal
/// avaliado, `VisitAnimalEntryModel`).
class VisitsLocalStore {
  VisitsLocalStore(this._database);

  final Future<Database> Function() _database;

  Future<List<LocalVisitRecord>> list(int companyId, {int? propertyId}) async {
    final db = await _database();
    final rows = await db.query(
      'visits',
      where: propertyId == null
          ? 'company_id = ?'
          : 'company_id = ? AND property_id = ?',
      whereArgs: [companyId, ?propertyId],
      orderBy: 'data_visita DESC, updated_at DESC',
    );
    if (rows.isEmpty) return const [];

    final events = await _eventsByVisit(
      db,
      rows.map((row) => row['id_externo'] as String).toList(growable: false),
    );
    return rows
        .map((row) => _toRecord(row, events[row['id_externo']] ?? const []))
        .toList(growable: false);
  }

  Future<LocalVisitRecord?> findByIdExterno(String idExterno) async {
    final db = await _database();
    final rows = await db.query(
      'visits',
      where: 'id_externo = ?',
      whereArgs: [idExterno],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final events = await _eventsByVisit(db, [idExterno]);
    return _toRecord(rows.first, events[idExterno] ?? const []);
  }

  /// Salva (cria ou atualiza) a visita feita no aparelho. A identidade é o
  /// `idExterno`, então editar a mesma visita nunca gera um segundo registro.
  Future<LocalVisitRecord> saveLocal({
    required int companyId,
    required VisitSummaryModel visit,
    required VisitLocalStatus localStatus,
    required SyncStatusEnum syncStatus,
  }) async {
    final db = await _database();
    await db.transaction((txn) async {
      final existing = await txn.query(
        'visits',
        columns: ['local_id', 'server_id'],
        where: 'id_externo = ?',
        whereArgs: [visit.idExterno],
        limit: 1,
      );
      final serverId = existing.isNotEmpty
          ? existing.first['server_id'] as int?
          : (visit.id > 0 ? visit.id : null);
      final localId = existing.isNotEmpty
          ? existing.first['local_id'] as int
          : (visit.id != 0 ? visit.id : await _nextLocalId(txn));

      await _writeVisit(
        txn,
        companyId: companyId,
        visit: visit,
        localId: localId,
        serverId: serverId,
        localStatus: localStatus,
        syncStatus: syncStatus,
      );
    });

    return (await findByIdExterno(visit.idExterno))!;
  }

  Future<void> updateSyncStatus(
    List<String> idsExternos,
    SyncStatusEnum status, {
    String? error,
  }) async {
    if (idsExternos.isEmpty) return;
    final db = await _database();
    await db.update(
      'visits',
      {'sync_status': status.name, 'sync_error': error},
      where:
          'id_externo IN (${List.filled(idsExternos.length, '?').join(',')}) '
          'AND local_status = ?',
      whereArgs: [...idsExternos, VisitLocalStatus.finalized.name],
    );
  }

  /// Marca a visita como confirmada pelo backend, gravando o id do servidor.
  Future<void> markSynced(String idExterno, {int? serverId}) async {
    final db = await _database();
    await db.update(
      'visits',
      {
        'sync_status': SyncStatusEnum.synced.name,
        'sync_error': null,
        if (serverId != null && serverId > 0) 'server_id': serverId,
      },
      where: 'id_externo = ?',
      whereArgs: [idExterno],
    );
  }

  /// Reconcilia visitas vindas do servidor (listagem online ou pull).
  /// Visitas com alterações locais ainda não enviadas não são sobrescritas:
  /// primeiro o push, depois o pull reconcilia (política do contrato de sync).
  Future<void> upsertFromServer(
    int companyId,
    List<VisitSummaryModel> visits,
  ) async {
    if (visits.isEmpty) return;
    final db = await _database();
    await db.transaction((txn) async {
      for (final visit in visits) {
        if (visit.idExterno.isEmpty) continue;

        final existing = await txn.query(
          'visits',
          columns: ['local_id', 'sync_status'],
          where: 'id_externo = ?',
          whereArgs: [visit.idExterno],
          limit: 1,
        );
        if (existing.isNotEmpty &&
            existing.first['sync_status'] != SyncStatusEnum.synced.name) {
          continue;
        }

        await _writeVisit(
          txn,
          companyId: companyId,
          visit: visit,
          localId: existing.isNotEmpty
              ? existing.first['local_id'] as int
              : visit.id,
          serverId: visit.id > 0 ? visit.id : null,
          localStatus: VisitLocalStatus.finalized,
          syncStatus: SyncStatusEnum.synced,
        );
      }
    });
  }

  /// Remove visitas já sincronizadas que não vieram na listagem online
  /// (excluídas no servidor). Visitas com alterações locais são preservadas.
  Future<void> removeSyncedMissingFrom(
    int companyId,
    Iterable<String> remoteIdsExternos, {
    int? propertyId,
  }) async {
    final db = await _database();
    final keep = remoteIdsExternos.toSet();
    final rows = await db.query(
      'visits',
      columns: ['id_externo'],
      where: propertyId == null
          ? 'company_id = ? AND sync_status = ?'
          : 'company_id = ? AND sync_status = ? AND property_id = ?',
      whereArgs: [companyId, SyncStatusEnum.synced.name, ?propertyId],
    );
    final stale = rows
        .map((row) => row['id_externo'] as String)
        .where((id) => !keep.contains(id))
        .toList(growable: false);
    await deleteSyncedByIdExterno(stale);
  }

  /// Aplica tombstones do pull. Só remove visitas sem alterações locais.
  Future<void> deleteSyncedByIdExterno(List<String> idsExternos) async {
    if (idsExternos.isEmpty) return;
    final db = await _database();
    const chunkSize = 500;
    for (var start = 0; start < idsExternos.length; start += chunkSize) {
      final chunk = idsExternos.sublist(
        start,
        (start + chunkSize).clamp(0, idsExternos.length),
      );
      await db.delete(
        'visits',
        where:
            'id_externo IN (${List.filled(chunk.length, '?').join(',')}) '
            'AND sync_status = ?',
        whereArgs: [...chunk, SyncStatusEnum.synced.name],
      );
    }
  }

  Future<void> deleteByIdExterno(String idExterno) async {
    final db = await _database();
    await db.delete('visits', where: 'id_externo = ?', whereArgs: [idExterno]);
  }

  Future<void> _writeVisit(
    Transaction txn, {
    required int companyId,
    required VisitSummaryModel visit,
    required int localId,
    required int? serverId,
    required VisitLocalStatus localStatus,
    required SyncStatusEnum syncStatus,
  }) async {
    await txn.insert('visits', {
      'id_externo': visit.idExterno,
      'company_id': companyId,
      'local_id': localId,
      'server_id': serverId,
      'property_id': visit.idPropriedade == 0 ? null : visit.idPropriedade,
      'id_externo_propriedade': visit.idExternoPropriedade,
      'data_visita': apiDate(visit.dataVisita),
      'observacoes': visit.observacoes,
      'id_usuario': visit.idUsuario,
      'nome_usuario': visit.nomeUsuario,
      'local_status': localStatus.name,
      'sync_status': syncStatus.name,
      'sync_error': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Reescreve os eventos da visita a partir do estado atual do formulário.
    await txn.delete(
      'visit_events',
      where: 'visit_id_externo = ?',
      whereArgs: [visit.idExterno],
    );
    for (var index = 0; index < visit.animais.length; index++) {
      final entry = visit.animais[index];
      await txn.insert('visit_events', {
        'visit_id_externo': visit.idExterno,
        'position': index,
        'animal_id': entry.animalId == 0 ? null : entry.animalId,
        'animal_id_externo': entry.animalIdExterno,
        'payload': jsonEncode(entry.toMap()),
      });
    }
  }

  Future<int> _nextLocalId(Transaction txn) async {
    final result = await txn.rawQuery(
      'SELECT MIN(local_id) AS min_id FROM visits WHERE local_id < 0',
    );
    final minId = result.first['min_id'] as int?;
    return (minId ?? 0) - 1;
  }

  Future<Map<String, List<VisitAnimalEntryModel>>> _eventsByVisit(
    Database db,
    List<String> idsExternos,
  ) async {
    final result = <String, List<VisitAnimalEntryModel>>{};
    // SQLite limita a quantidade de parâmetros por consulta.
    const chunkSize = 500;
    for (var start = 0; start < idsExternos.length; start += chunkSize) {
      final chunk = idsExternos.sublist(
        start,
        (start + chunkSize).clamp(0, idsExternos.length),
      );
      final rows = await db.query(
        'visit_events',
        where:
            'visit_id_externo IN (${List.filled(chunk.length, '?').join(',')})',
        whereArgs: chunk,
        orderBy: 'visit_id_externo, position',
      );
      for (final row in rows) {
        final entry = _decodeEvent(row['payload']);
        if (entry == null) continue;
        result
            .putIfAbsent(row['visit_id_externo'] as String, () => [])
            .add(entry);
      }
    }
    return result;
  }

  LocalVisitRecord _toRecord(
    Map<String, Object?> row,
    List<VisitAnimalEntryModel> events,
  ) {
    final serverId = row['server_id'] as int?;
    final dataVisita = row['data_visita'] as String?;

    return LocalVisitRecord(
      visit: VisitSummaryModel(
        id: serverId ?? row['local_id'] as int,
        idExterno: row['id_externo'] as String,
        idPropriedade: row['property_id'] as int? ?? 0,
        idExternoPropriedade: row['id_externo_propriedade'] as String? ?? '',
        dataVisita: dataVisita == null ? null : DateTime.tryParse(dataVisita),
        observacoes: row['observacoes'] as String?,
        idUsuario: row['id_usuario'] as int?,
        nomeUsuario: row['nome_usuario'] as String?,
        animais: events,
      ),
      localStatus: VisitLocalStatus.fromName(row['local_status'] as String?),
      syncStatus: SyncStatusEnum.fromName(row['sync_status'] as String?),
      syncError: row['sync_error'] as String?,
    );
  }

  VisitAnimalEntryModel? _decodeEvent(Object? payload) {
    try {
      final decoded = jsonDecode(payload as String);
      return VisitAnimalEntryModelMapper.fromMap(
        Map<String, dynamic>.from(decoded as Map),
      );
    } catch (_) {
      return null;
    }
  }
}
