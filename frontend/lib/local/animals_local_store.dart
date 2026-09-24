import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'package:cysvet_app/local/local_database.dart';
import 'package:cysvet_app/models/animal_summary_model.dart';

final animalsLocalStoreProvider = Provider<AnimalsLocalStore>((ref) {
  return AnimalsLocalStore(() => ref.read(localDatabaseProvider.future));
});

/// Cache local de animais (somente leitura offline).
class AnimalsLocalStore {
  AnimalsLocalStore(this._database);

  final Future<Database> Function() _database;

  Future<List<AnimalSummaryModel>> list(
    int companyId, {
    int? propertyId,
  }) async {
    final db = await _database();
    final rows = await db.query(
      'animals',
      where: propertyId == null
          ? 'company_id = ?'
          : 'company_id = ? AND property_id = ?',
      whereArgs: [companyId, ?propertyId],
    );

    return rows
        .map((row) => _decode(row['payload']))
        .whereType<AnimalSummaryModel>()
        .toList(growable: false);
  }

  /// Substitui o snapshot da empresa (ou só da propriedade, quando informada).
  Future<void> replaceAll(
    int companyId,
    List<AnimalSummaryModel> animals, {
    int? propertyId,
  }) async {
    final db = await _database();
    await db.transaction((txn) async {
      await txn.delete(
        'animals',
        where: propertyId == null
            ? 'company_id = ?'
            : 'company_id = ? AND property_id = ?',
        whereArgs: [companyId, ?propertyId],
      );
      final batch = txn.batch();
      for (final animal in animals) {
        _upsert(batch, companyId, animal);
      }
      await batch.commit(noResult: true);
    });
  }

  /// Aplica alterações incrementais vindas do pull de sincronização.
  Future<void> upsertAll(
    int companyId,
    List<AnimalSummaryModel> animals,
  ) async {
    if (animals.isEmpty) return;
    final db = await _database();
    final batch = db.batch();
    for (final animal in animals) {
      _upsert(batch, companyId, animal);
    }
    await batch.commit(noResult: true);
  }

  void _upsert(Batch batch, int companyId, AnimalSummaryModel animal) {
    batch.insert('animals', {
      'company_id': companyId,
      'id': animal.id,
      'id_externo': animal.idExterno,
      'property_id': animal.idPropriedade,
      'payload': jsonEncode(animal.toMap()),
      'cached_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  AnimalSummaryModel? _decode(Object? payload) {
    try {
      final decoded = jsonDecode(payload as String);
      return AnimalSummaryModelMapper.fromMap(
        Map<String, dynamic>.from(decoded as Map),
      );
    } catch (_) {
      return null;
    }
  }
}
