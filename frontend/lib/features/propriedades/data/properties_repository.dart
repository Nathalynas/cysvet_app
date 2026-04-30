import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/property_summary.dart';

final propertiesRepositoryProvider = Provider<PropertiesRepository>((ref) {
  return PropertiesRepository(ref.watch(apiClientProvider));
});

class PropertiesRepository {
  PropertiesRepository(this._dio);

  final Dio _dio;

  Future<List<PropertySummary>> list() async {
    final response = await _dio.get<Object?>('/api/properties');
    final items = _asList(response.data);

    return items
        .map((item) => PropertySummary.fromJson(item))
        .toList(growable: false);
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
