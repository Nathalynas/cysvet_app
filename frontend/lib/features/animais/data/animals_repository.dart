import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/animal_summary.dart';

final animalsRepositoryProvider = Provider<AnimalsRepository>((ref) {
  return AnimalsRepository(ref.watch(apiClientProvider));
});

class AnimalsRepository {
  AnimalsRepository(this._dio);

  final Dio _dio;

  Future<List<AnimalSummary>> list({int? propertyId}) async {
    final response = await _dio.get<Object?>(
      '/api/animals',
      queryParameters: {
        ...?propertyId != null ? {'idPropriedade': propertyId} : null,
      },
    );

    final items = _asList(response.data);
    return items.map(AnimalSummary.fromJson).toList(growable: false);
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
