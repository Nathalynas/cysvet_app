import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/dashboard_metrics.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<DashboardMetrics> fetch({int? propertyId}) async {
    final response = await _dio.get<Object?>(
      '/api/dashboard',
      queryParameters: {
        ...?propertyId != null ? {'idPropriedade': propertyId} : null,
      },
    );

    return DashboardMetricsMapper.fromMap(_asMap(response.data));
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    return const {};
  }
}
