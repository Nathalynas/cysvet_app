import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_state.dart';
import '../presentation/app_scaffold_messenger.dart';
import 'package:cysvet_app/models/auth_session_model.dart';
import '../config/api_config.dart';

enum ForbiddenAction { none, companyDeactivated, passwordChangeRequired }

ForbiddenAction classifyForbidden(int? status, Object? data) {
  if (status != 403 || data is! Map) {
    return ForbiddenAction.none;
  }

  return switch (data['message']) {
    'Empresa desativada' => ForbiddenAction.companyDeactivated,
    'Troca de senha obrigatoria' => ForbiddenAction.passwordChangeRequired,
    _ => ForbiddenAction.none,
  };
}

/// Aplica a reação a um 403 de bloqueio. Só age se ainda houver sessão: várias
/// requisições em andamento falham juntas e o aviso deve aparecer uma vez.
/// Só a sessão é limpa: fila de sync e banco local permanecem para não perder
/// dados offline pendentes.
void handleForbiddenAction(
  ForbiddenAction action, {
  required bool hasSession,
  required void Function() clearSession,
  required void Function(String message) warn,
}) {
  if (!hasSession) return;

  switch (action) {
    case ForbiddenAction.companyDeactivated:
      warn('Sua empresa foi desativada. Fale com o suporte do CYSVET.');
      clearSession();
    case ForbiddenAction.passwordChangeRequired:
      warn(
        'Sua senha foi redefinida. Entre com a senha provisória enviada por e-mail.',
      );
      clearSession();
    case ForbiddenAction.none:
      break;
  }
}

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

        handleForbiddenAction(
          classifyForbidden(error.response?.statusCode, error.response?.data),
          hasSession: ref.read(authSessionProvider) != null,
          clearSession: () =>
              unawaited(ref.read(authSessionProvider.notifier).clearSession()),
          warn: showAppWarning,
        );

        handler.next(error);
      },
    ),
  );

  ref.onDispose(dio.close);
  return dio;
});
