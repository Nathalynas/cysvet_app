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

  /// Atalhos de situação reprodutiva da visita (valores da API, na ordem).
  Future<List<String>> reproductiveShortcuts() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/account/preferences',
    );
    return _shortcuts(response.data);
  }

  /// Salva os atalhos; `null` volta ao padrão. Devolve o que ficou gravado.
  Future<List<String>> saveReproductiveShortcuts(List<String>? values) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/account/preferences',
      data: {'atalhosSituacaoReprodutiva': values},
    );
    return _shortcuts(response.data);
  }

  static List<String> _shortcuts(Map<String, dynamic>? data) {
    final values = data?['atalhosSituacaoReprodutiva'] as List? ?? const [];
    return [for (final value in values) value.toString()];
  }
}
