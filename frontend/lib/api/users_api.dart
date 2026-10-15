import 'package:dio/dio.dart';

import 'package:cysvet_app/api/api_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/core/enums/user_status.dart';
import 'package:cysvet_app/core/network/api_client.dart';
import 'package:cysvet_app/models/user_summary_model.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(ref.watch(apiClientProvider));
});

class UsersRepository {
  UsersRepository(this._dio);

  final Dio _dio;

  Future<List<UserSummaryModel>> list() async {
    final response = await _dio.get<Object?>('/api/users');
    final items = apiList(response.data);
    return items.map(_fromMap).toList(growable: false);
  }

  Future<CreateUserResult> create(UserSummaryModel user) async {
    final response = await _dio.post<Object?>(
      '/api/users',
      data: {'name': user.name.trim(), 'email': user.email.trim()},
    );

    final map = apiMap(response.data);
    return CreateUserResult(
      user: _fromMap(Map<String, dynamic>.from(map['user'] as Map)),
      emailSent: map['emailSent'] == true,
      existingAccount: map['existingAccount'] == true,
    );
  }

  /// Gera nova senha provisoria e envia por e-mail; retorna se o e-mail saiu.
  Future<bool> resendAccess(int id) async {
    final response = await _dio.post<Object?>('/api/users/$id/resend-access');
    return apiMap(response.data)['emailSent'] == true;
  }

  Future<UserSummaryModel> update(UserSummaryModel user) async {
    final response = await _dio.put<Object?>(
      '/api/users/${user.id}',
      data: {'name': user.name.trim(), 'email': user.email.trim()},
    );

    return _fromMap(apiMap(response.data));
  }

  Future<UserSummaryModel> updateStatus({
    required int id,
    required UserStatus status,
  }) async {
    final response = await _dio.patch<Object?>(
      '/api/users/$id/status',
      data: {'status': status.apiValue},
    );

    return _fromMap(apiMap(response.data));
  }

  Future<void> delete(int id) async {
    await _dio.delete<void>('/api/users/$id');
  }

  UserSummaryModel _fromMap(Map<String, dynamic> map) {
    return UserSummaryModel(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      perfil: map['perfil']?.toString() ?? 'VETERINARIO',
      companyName: map['companyName']?.toString(),
      status: UserStatus.fromApi(map['status']?.toString()),
      awaitingFirstAccess: map['awaitingFirstAccess'] == true,
    );
  }
}
