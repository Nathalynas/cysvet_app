import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/auth_session_model.dart';

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

    return AuthSessionModelMapper.fromMap(_asMap(response.data));
  }

  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Object?>(
      '/api/auth/login',
      data: {'email': email.trim(), 'password': password},
    );

    return AuthSessionModelMapper.fromMap(_asMap(response.data));
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

    return AllowedCompanyModelMapper.fromMap(_asMap(response.data));
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
