import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/core/network/api_error.dart';
import 'package:cysvet_app/core/platform/offline_platform.dart';
import 'package:cysvet_app/models/auth_session_model.dart';
import 'package:cysvet_app/providers/auth_state.dart';

/// Escopo dos dados locais: empresa ativa + usuário logado.
class OfflineScope {
  const OfflineScope({required this.companyId, required this.userId});

  final int companyId;
  final int userId;

  @override
  bool operator ==(Object other) {
    return other is OfflineScope &&
        other.companyId == companyId &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(companyId, userId);
}

/// `null` fora do mobile ou sem sessão — nesse caso nada é gravado localmente.
final offlineScopeProvider = Provider<OfflineScope?>((ref) {
  if (!isOfflineFirstPlatform) return null;

  final session = ref.watch(authSessionProvider);
  if (session == null) return null;

  final companyId = session.activeCompany?.id ?? session.activeCompanyId;
  if (companyId <= 0) return null;

  return OfflineScope(companyId: companyId, userId: session.user.id);
});

/// Busca remota com cache local (read-through) para o mobile.
///
/// - Online: busca no backend, grava o snapshot local e devolve o remoto.
/// - Falha de rede: devolve o que estiver no banco local.
/// - Outros erros (401, 403, 500...) seguem propagando como hoje.
/// - Fora do mobile (`scope == null`): só chama o backend, sem mudança.
Future<List<T>> fetchWithLocalFallback<T>({
  required OfflineScope? scope,
  required Future<List<T>> Function() remote,
  required Future<void> Function(OfflineScope scope, List<T> items) saveLocal,
  required Future<List<T>> Function(OfflineScope scope) readLocal,
}) async {
  if (scope == null) return remote();

  try {
    final items = await remote();
    try {
      await saveLocal(scope, items);
    } catch (_) {
      // Cache é best-effort: falha no SQLite não pode quebrar o fluxo online.
    }
    return items;
  } catch (error) {
    if (!isNetworkError(error)) rethrow;

    final cached = await readLocal(scope);
    if (cached.isEmpty) rethrow;
    return cached;
  }
}
