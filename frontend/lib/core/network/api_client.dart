import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_state.dart';
import 'package:cysvet_app/models/auth_session_model.dart';
import '../config/api_config.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final session = ref.watch(authSessionProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Login, refresh e logout não usam sessão nem empresa; mandar o access
        // token expirado junto não ajuda e confunde o refresh.
        if (options.path.startsWith('/api/auth/')) {
          handler.next(options);
          return;
        }

        final token = session?.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        final companyId =
            session?.activeCompany?.id ?? session?.activeCompanyId;
        if (companyId != null && companyId > 0) {
          options.headers['empresaid'] = companyId.toString();
        }

        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          unawaited(ref.read(authSessionProvider.notifier).clearSession());
        }

        handler.next(error);
      },
    ),
  );

  ref.onDispose(dio.close);
  return dio;
});
