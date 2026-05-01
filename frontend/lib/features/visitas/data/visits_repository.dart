import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/visit_summary_model.dart';

final visitsRepositoryProvider = Provider<VisitsRepository>((ref) {
  return VisitsRepository(ref.watch(apiClientProvider));
});

class VisitsRepository {
  VisitsRepository(this._dio);

  final Dio _dio;

  Future<List<VisitSummaryModel>> list({int? propertyId}) async {
    final response = await _dio.get<Object?>(
      '/api/visits',
      queryParameters: {
        ...?propertyId != null ? {'idPropriedade': propertyId} : null,
      },
    );

    final items = _asList(response.data);
    return items.map(VisitSummaryModelMapper.fromMap).toList(growable: false);
  }

  List<Map<String, dynamic>> _asList(Object? data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (item) => item.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList(growable: false);
    }

    return const [];
  }
}
