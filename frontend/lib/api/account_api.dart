import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/core/network/api_client.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(apiClientProvider));
});

class AccountRepository {
  AccountRepository(this._dio);

  final Dio _dio;

  Future<void> changeRequiredPassword(String newPassword) async {
    await _dio.post<void>(
      '/api/account/password',
      data: {'newPassword': newPassword},
    );
  }
}
