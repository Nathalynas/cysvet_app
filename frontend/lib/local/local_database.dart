import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Banco SQLite local usado pelo offline-first do mobile.
///
/// Todas as tabelas são particionadas por `company_id` (empresa ativa da
/// sessão), porque o backend é multi-tenant via header `empresaid`.
final localDatabaseProvider = FutureProvider<Database>((ref) async {
  final database = await LocalDatabase.open();
  ref.onDispose(database.close);
  return database;
});

class LocalDatabase {
  const LocalDatabase._();

  static const _fileName = 'cysvet_offline.db';
  static const _version = 1;

  static Future<Database> open() async {
    final directory = await getDatabasesPath();
    return openDatabase(
      p.join(directory, _fileName),
      version: _version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        final batch = db.batch();
        for (final statement in _schemaV1) {
          batch.execute(statement);
        }
        await batch.commit(noResult: true);
      },
    );
  }

  static const _schemaV1 = [
    '''
    CREATE TABLE properties (
      company_id INTEGER NOT NULL,
      id INTEGER NOT NULL,
      id_externo TEXT,
      payload TEXT NOT NULL,
      cached_at TEXT NOT NULL,
      PRIMARY KEY (company_id, id)
    )
    ''',
    '''
    CREATE TABLE animals (
      company_id INTEGER NOT NULL,
      id INTEGER NOT NULL,
      id_externo TEXT,
      property_id INTEGER,
      payload TEXT NOT NULL,
      cached_at TEXT NOT NULL,
      PRIMARY KEY (company_id, id)
    )
    ''',
    'CREATE INDEX idx_animals_property ON animals (company_id, property_id)',
    // Visita: id_externo (UUID do cliente) é a identidade estável. server_id
    // só é preenchido depois que o backend confirma o registro.
    '''
    CREATE TABLE visits (
      id_externo TEXT PRIMARY KEY,
      company_id INTEGER NOT NULL,
      local_id INTEGER NOT NULL,
      server_id INTEGER,
      property_id INTEGER,
      id_externo_propriedade TEXT,
      data_visita TEXT,
      observacoes TEXT,
      id_usuario INTEGER,
      nome_usuario TEXT,
      local_status TEXT NOT NULL,
      sync_status TEXT NOT NULL,
      sync_error TEXT,
      updated_at TEXT NOT NULL
    )
    ''',
    'CREATE INDEX idx_visits_company ON visits (company_id, property_id)',
    // Eventos da visita: um registro por animal avaliado na visita.
    '''
    CREATE TABLE visit_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      visit_id_externo TEXT NOT NULL
        REFERENCES visits (id_externo) ON DELETE CASCADE,
      position INTEGER NOT NULL,
      animal_id INTEGER,
      animal_id_externo TEXT,
      payload TEXT NOT NULL
    )
    ''',
    'CREATE INDEX idx_visit_events_visit ON visit_events (visit_id_externo)',
    // Fila de mutações enviadas para POST /api/sync.
    '''
    CREATE TABLE sync_mutations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      chave_mutacao TEXT NOT NULL UNIQUE,
      company_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      entity TEXT NOT NULL,
      entity_id_externo TEXT NOT NULL,
      operation TEXT NOT NULL,
      payload TEXT NOT NULL,
      client_updated_at TEXT NOT NULL,
      status TEXT NOT NULL,
      attempts INTEGER NOT NULL DEFAULT 0,
      last_error TEXT,
      created_at TEXT NOT NULL
    )
    ''',
    '''
    CREATE INDEX idx_sync_mutations_owner
      ON sync_mutations (company_id, user_id, status)
    ''',
    '''
    CREATE TABLE sync_meta (
      key TEXT PRIMARY KEY,
      value TEXT
    )
    ''',
  ];
}
