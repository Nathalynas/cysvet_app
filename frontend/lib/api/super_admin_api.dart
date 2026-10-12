import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/api/api_response.dart';
import 'package:cysvet_app/core/network/api_client.dart';
import 'package:cysvet_app/models/client_company_model.dart';

final superAdminRepositoryProvider = Provider<SuperAdminRepository>((ref) {
  return SuperAdminRepository(ref.watch(apiClientProvider));
});

class SuperAdminRepository {
  SuperAdminRepository(this._dio);

  final Dio _dio;

  Future<List<ClientCompanyModel>> list() async {
    final response = await _dio.get<Object?>('/api/super/companies');
    return apiList(
      response.data,
    ).map(ClientCompanyModel.fromMap).toList(growable: false);
  }

  Future<({ClientCompanyModel company, bool emailSent})> create({
    required String companyName,
    required String responsibleName,
    required String responsibleEmail,
  }) async {
    final response = await _dio.post<Object?>(
      '/api/super/companies',
      data: {
        'companyName': companyName.trim(),
        'responsibleName': responsibleName.trim(),
        'responsibleEmail': responsibleEmail.trim(),
      },
    );
    final body = apiMap(response.data);
    return (
      company: ClientCompanyModel.fromMap(apiMap(body['company'])),
      emailSent: body['emailSent'] == true,
    );
  }

  Future<ClientCompanyModel> setActive(int id, bool active) async {
    final response = await _dio.patch<Object?>(
      '/api/super/companies/$id/status',
      data: {'active': active},
    );
    return ClientCompanyModel.fromMap(apiMap(response.data));
  }

  Future<bool> resendAccess(int id) async {
    final response = await _dio.post<Object?>(
      '/api/super/companies/$id/resend-access',
    );
    return apiMap(response.data)['emailSent'] == true;
  }
}
