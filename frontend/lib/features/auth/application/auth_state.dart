import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/auth_session_model.dart';

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSessionModel?>(
      AuthSessionNotifier.new,
    );
final authBusyProvider = NotifierProvider<BusyNotifier, bool>(BusyNotifier.new);

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

class AuthController {
  AuthController(this._ref);

  final Ref _ref;

  Future<void> login({required String email, required String password}) async {
    _ref.read(authBusyProvider.notifier).setBusy(true);
    try {
      final session = await _ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      _ref.read(authSessionProvider.notifier).setSession(session);
    } finally {
      _ref.read(authBusyProvider.notifier).setBusy(false);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _ref.read(authBusyProvider.notifier).setBusy(true);
    try {
      final session = await _ref
          .read(authRepositoryProvider)
          .register(name: name, email: email, password: password);
      _ref.read(authSessionProvider.notifier).setSession(session);
    } finally {
      _ref.read(authBusyProvider.notifier).setBusy(false);
    }
  }

  Future<void> logout() async {
    final session = _ref.read(authSessionProvider);
    _ref.read(authBusyProvider.notifier).setBusy(true);

    try {
      if (session != null && session.refreshToken.isNotEmpty) {
        try {
          await _ref.read(authRepositoryProvider).logout(session.refreshToken);
        } catch (_) {
          // Clear local state even if the backend token was already invalidated.
        }
      }
    } finally {
      _ref.read(authSessionProvider.notifier).clearSession();
      _ref.read(authBusyProvider.notifier).setBusy(false);
    }
  }
}

class AuthSessionNotifier extends Notifier<AuthSessionModel?> {
  @override
  AuthSessionModel? build() => null;

  void setSession(AuthSessionModel? session) {
    state = session;
  }

  void clearSession() {
    state = null;
  }
}

class BusyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setBusy(bool value) {
    state = value;
  }
}
