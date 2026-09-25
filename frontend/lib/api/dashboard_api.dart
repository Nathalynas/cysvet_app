import 'package:dio/dio.dart';

import 'package:cysvet_app/api/api_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/core/network/api_client.dart';
import 'package:cysvet_app/models/dashboard_metrics_model.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<DashboardMetricsModel> fetch({int? propertyId}) async {
    final response = await _dio.get<Object?>(
      '/api/dashboard',
      queryParameters: {
        ...?propertyId != null ? {'idPropriedade': propertyId} : null,
      },
    );

    return DashboardMetricsModelMapper.fromMap(apiMap(response.data));
  }
}
