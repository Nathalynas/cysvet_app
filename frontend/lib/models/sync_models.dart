import 'dart:convert';

/// Nomes lógicos de entidade aceitos por `POST /api/sync`
/// (ver `SyncEntityNames` no backend).
class SyncEntity {
  const SyncEntity._();

  static const property = 'property';
  static const lot = 'lot';
  static const animal = 'animal';
  static const visit = 'visit';
  static const event = 'event';

  /// Ordem oficial de envio para criação/atualização.
  static const createUpdateOrder = [property, lot, animal, visit, event];
}

enum SyncOperationType {
  create('CREATE'),
  update('UPDATE'),
  delete('DELETE');

  const SyncOperationType(this.apiValue);

  final String apiValue;

  static SyncOperationType fromApi(String? value) {
    for (final type in values) {
      if (type.apiValue == value) return type;
    }
    return SyncOperationType.update;
  }
}

enum SyncMutationStatus { pending, syncing, error }

class SyncMutation {
  const SyncMutation({
    required this.id,
    required this.chaveMutacao,
    required this.companyId,
    required this.userId,
    required this.entity,
    required this.entityIdExterno,
    required this.operation,
    required this.payload,
    required this.clientUpdatedAt,
    required this.status,
    required this.attempts,
    this.lastError,
  });

  factory SyncMutation.fromRow(Map<String, Object?> row) {
    return SyncMutation(
      id: row['id'] as int,
      chaveMutacao: row['chave_mutacao'] as String,
      companyId: row['company_id'] as int,
      userId: row['user_id'] as int,
      entity: row['entity'] as String,
      entityIdExterno: row['entity_id_externo'] as String,
      operation: SyncOperationType.fromApi(row['operation'] as String?),
      payload: Map<String, dynamic>.from(
        jsonDecode(row['payload'] as String) as Map,
      ),
      clientUpdatedAt: DateTime.parse(row['client_updated_at'] as String),
      status: SyncMutationStatus.values.byName(row['status'] as String),
      attempts: row['attempts'] as int? ?? 0,
      lastError: row['last_error'] as String?,
    );
  }

  final int id;
  final String chaveMutacao;
  final int companyId;
  final int userId;
  final String entity;
  final String entityIdExterno;
  final SyncOperationType operation;
  final Map<String, dynamic> payload;
  final DateTime clientUpdatedAt;
  final SyncMutationStatus status;
  final int attempts;
  final String? lastError;

  int get entityOrder {
    final index = SyncEntity.createUpdateOrder.indexOf(entity);
    return index < 0 ? SyncEntity.createUpdateOrder.length : index;
  }

  /// Item no formato de `SyncItemRequest`.
  Map<String, dynamic> toRequestItem() {
    return {
      'chaveMutacao': chaveMutacao,
      'operationType': operation.apiValue,
      'entity': entity,
      'dataAtualizacaoCliente': clientUpdatedAt.toUtc().toIso8601String(),
      'payload': payload,
    };
  }

  SyncMutation copyWith({int? id, SyncOperationType? operation}) {
    return SyncMutation(
      id: id ?? this.id,
      chaveMutacao: chaveMutacao,
      companyId: companyId,
      userId: userId,
      entity: entity,
      entityIdExterno: entityIdExterno,
      operation: operation ?? this.operation,
      payload: payload,
      clientUpdatedAt: clientUpdatedAt,
      status: status,
      attempts: attempts,
      lastError: lastError,
    );
  }
}

/// Status de `SyncItemResponse` no backend.
enum SyncItemStatus {
  synced,
  replayed,
  conflictServerWins,

  /// Dados inválidos ou referência inexistente: nada foi aplicado no servidor.
  rejected,
  unknown;

  static SyncItemStatus fromApi(String? value) {
    switch (value) {
      case 'SYNCED':
        return SyncItemStatus.synced;
      case 'REPLAYED':
        return SyncItemStatus.replayed;
      case 'CONFLICT_SERVER_WINS':
        return SyncItemStatus.conflictServerWins;
      case 'REJECTED':
        return SyncItemStatus.rejected;
      default:
        return SyncItemStatus.unknown;
    }
  }

  /// O backend aceitou (ou já tinha aceitado) a mutação; ela sai da fila.
  bool get isAccepted =>
      this != SyncItemStatus.rejected && this != SyncItemStatus.unknown;
}

class SyncItemResult {
  const SyncItemResult({
    required this.chaveMutacao,
    required this.status,
    this.idEntidade,
    this.idExterno,
    this.message,
  });

  factory SyncItemResult.fromMap(Map<String, dynamic> map) {
    final rawId = map['idEntidade'];
    return SyncItemResult(
      chaveMutacao: map['chaveMutacao']?.toString() ?? '',
      status: SyncItemStatus.fromApi(map['status']?.toString()),
      idEntidade: rawId is num ? rawId.toInt() : int.tryParse('$rawId'),
      idExterno: map['idExterno']?.toString(),
      message: map['message']?.toString(),
    );
  }

  final String chaveMutacao;
  final SyncItemStatus status;
  final int? idEntidade;
  final String? idExterno;
  final String? message;
}

class DeletedRecord {
  const DeletedRecord({required this.entity, required this.idExterno});

  final String entity;
  final String idExterno;
}

/// Resposta de `GET /api/sync/pull`. As coleções ficam como mapas crus para
/// serem convertidas pelos mappers já usados nas rotas REST.
class PullSyncResult {
  const PullSyncResult({
    required this.serverTime,
    required this.properties,
    required this.animals,
    required this.visits,
    required this.deletedRecords,
  });

  final DateTime? serverTime;
  final List<Map<String, dynamic>> properties;
  final List<Map<String, dynamic>> animals;
  final List<Map<String, dynamic>> visits;
  final List<DeletedRecord> deletedRecords;
}
