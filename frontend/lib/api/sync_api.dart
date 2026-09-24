import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/api/api_response.dart';
import 'package:cysvet_app/core/network/api_client.dart';
import 'package:cysvet_app/models/sync_models.dart';

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(ref.watch(apiClientProvider));
});

class SyncRepository {
  SyncRepository(this._dio);

  final Dio _dio;

  /// `POST /api/sync` — envia a fila de mutações.
  Future<List<SyncItemResult>> push(List<SyncMutation> mutations) async {
    final response = await _dio.post<Object?>(
      '/api/sync',
      data: {
        'items': mutations
            .map((mutation) => mutation.toRequestItem())
            .toList(growable: false),
      },
    );

    return apiList(
      apiMap(response.data)['items'],
    ).map(SyncItemResult.fromMap).toList(growable: false);
  }

  /// `GET /api/sync/pull?since=` — snapshot incremental desde o checkpoint.
  // TODO BACKEND: o pull devolve todas as coleções da empresa sem paginação e
  // sem filtro por propriedade/veterinário. Em bases grandes o primeiro pull
  // (since = null) pode ser pesado; avaliar paginação ou escopo por usuário.
  Future<PullSyncResult> pull({DateTime? since}) async {
    final response = await _dio.get<Object?>(
      '/api/sync/pull',
      queryParameters: {
        if (since != null) 'since': since.toUtc().toIso8601String(),
      },
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );

    final data = apiMap(response.data);
    return PullSyncResult(
      serverTime: DateTime.tryParse(data['serverTime']?.toString() ?? ''),
      properties: apiList(data['properties']),
      animals: apiList(data['animals']),
      visits: apiList(data['visits']),
      deletedRecords: apiList(data['deletedRecords'])
          .map(
            (item) => DeletedRecord(
              entity: item['nomeEntidade']?.toString() ?? '',
              idExterno: item['idExterno']?.toString() ?? '',
            ),
          )
          .where((item) => item.idExterno.isNotEmpty)
          .toList(growable: false),
    );
  }
}
