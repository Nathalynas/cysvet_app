import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/user_status.dart';
import '../../../core/network/api_client.dart';
import '../domain/user_summary_model.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(ref.watch(apiClientProvider));
});

class UsersRepository {
  UsersRepository(this._dio);

  final Dio _dio;

  Future<List<UserSummaryModel>> list() async {
    final response = await _dio.get<Object?>('/api/users');
    final items = _asList(response.data);
    return items.map(_fromMap).toList(growable: false);
  }

  Future<UserSummaryModel> create({
    required UserSummaryModel user,
    required String password,
  }) async {
    final response = await _dio.post<Object?>(
      '/api/users',
      data: {
        'name': user.name.trim(),
        'email': user.email.trim(),
        'password': password,
      },
    );

    return _fromMap(_asMap(response.data));
  }

  Future<UserSummaryModel> update(UserSummaryModel user) async {
    final response = await _dio.put<Object?>(
      '/api/users/${user.id}',
      data: {'name': user.name.trim(), 'email': user.email.trim()},
    );

    return _fromMap(_asMap(response.data));
  }

  Future<UserSummaryModel> updateStatus({
    required int id,
    required UserStatus status,
  }) async {
    final response = await _dio.patch<Object?>(
      '/api/users/$id/status',
      data: {'status': status.apiValue},
    );

    return _fromMap(_asMap(response.data));
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
    );
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

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    return const {};
  }
}
