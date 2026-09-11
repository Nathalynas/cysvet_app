import 'package:dio/dio.dart';

import 'package:cysvet_app/api/api_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/core/network/api_client.dart';
import 'package:cysvet_app/models/auth_session_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthSessionModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Object?>(
      '/api/auth/register',
      data: {'name': name.trim(), 'email': email.trim(), 'password': password},
    );

    return AuthSessionModelMapper.fromMap(apiMap(response.data));
  }

  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Object?>(
      '/api/auth/login',
      data: {'email': email.trim(), 'password': password},
    );

    return AuthSessionModelMapper.fromMap(apiMap(response.data));
  }

  Future<AuthSessionModel> refresh({required String refreshToken}) async {
    final response = await _dio.post<Object?>(
      '/api/auth/refresh',
      data: {'refreshToken': refreshToken},
    );

    return AuthSessionModelMapper.fromMap(apiMap(response.data));
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post<void>(
      '/api/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }

  Future<AllowedCompanyModel> updateActiveCompany({
    required String name,
    required String email,
  }) async {
    final response = await _dio.put<Object?>(
      '/api/companies/active',
      data: {'name': name.trim(), 'email': email.trim()},
    );

    return AllowedCompanyModelMapper.fromMap(apiMap(response.data));
  }
}
