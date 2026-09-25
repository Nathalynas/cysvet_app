import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'package:cysvet_app/local/local_database.dart';
import 'package:cysvet_app/models/property_summary_model.dart';

final propertiesLocalStoreProvider = Provider<PropertiesLocalStore>((ref) {
  return PropertiesLocalStore(() => ref.read(localDatabaseProvider.future));
});

/// Cache local de propriedades (somente leitura offline).
class PropertiesLocalStore {
  PropertiesLocalStore(this._database);

  final Future<Database> Function() _database;

  Future<List<PropertySummaryModel>> list(int companyId) async {
    final db = await _database();
    final rows = await db.query(
      'properties',
      where: 'company_id = ?',
      whereArgs: [companyId],
    );

    return rows
        .map((row) => _decode(row['payload']))
        .whereType<PropertySummaryModel>()
        .toList(growable: false);
  }

  /// Substitui o snapshot completo da empresa (resultado de `GET /api/properties`).
  Future<void> replaceAll(
    int companyId,
    List<PropertySummaryModel> properties,
  ) async {
    final db = await _database();
    await db.transaction((txn) async {
      await txn.delete(
        'properties',
        where: 'company_id = ?',
        whereArgs: [companyId],
      );
      final batch = txn.batch();
      for (final property in properties) {
        _upsert(batch, companyId, property);
      }
      await batch.commit(noResult: true);
    });
  }

  /// Aplica alterações incrementais vindas do pull de sincronização.
  Future<void> upsertAll(
    int companyId,
    List<PropertySummaryModel> properties,
  ) async {
    if (properties.isEmpty) return;
    final db = await _database();
    final batch = db.batch();
    for (final property in properties) {
      _upsert(batch, companyId, property);
    }
    await batch.commit(noResult: true);
  }

  void _upsert(Batch batch, int companyId, PropertySummaryModel property) {
    batch.insert('properties', {
      'company_id': companyId,
      'id': property.id,
      'id_externo': property.idExterno,
      'payload': jsonEncode(property.toMap()),
      'cached_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  PropertySummaryModel? _decode(Object? payload) {
    try {
      final decoded = jsonDecode(payload as String);
      return PropertySummaryModelMapper.fromMap(
        Map<String, dynamic>.from(decoded as Map),
      );
    } catch (_) {
      return null;
    }
  }
}
