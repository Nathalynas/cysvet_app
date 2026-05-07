import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/auth_session_storage.dart';
import '../domain/auth_session_model.dart';

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSessionModel?>(
      AuthSessionNotifier.new,
    );
final authBootstrapProvider =
    NotifierProvider<AuthBootstrapNotifier, bool>(AuthBootstrapNotifier.new);
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
      await _ref.read(authSessionProvider.notifier).setSession(session);
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
      await _ref.read(authSessionProvider.notifier).setSession(session);
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
      await _ref.read(authSessionProvider.notifier).clearSession();
      _ref.read(authBusyProvider.notifier).setBusy(false);
    }
  }
}

class AuthSessionNotifier extends Notifier<AuthSessionModel?> {
  bool _restoreScheduled = false;

  @override
  AuthSessionModel? build() {
    if (!_restoreScheduled) {
      _restoreScheduled = true;
      Future.microtask(_restoreSession);
    }

    return null;
  }

  Future<void> setSession(AuthSessionModel? session) async {
    state = session;
    if (session == null) {
      await ref.read(authSessionStorageProvider).clear();
      return;
    }

    await ref.read(authSessionStorageProvider).write(session);
  }

  Future<void> switchActiveCompany(int companyId) async {
    final session = state;
    if (session == null) {
      return;
    }

    final companyExists = session.companies.any((company) => company.id == companyId);
    if (!companyExists) {
      return;
    }

    await setSession(
      AuthSessionModel(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        user: session.user,
        activeCompanyId: companyId,
        companies: session.companies,
      ),
    );
  }

  Future<void> clearSession() async {
    state = null;
    await ref.read(authSessionStorageProvider).clear();
  }

  Future<void> _restoreSession() async {
    try {
      final restoredSession = await ref.read(authSessionStorageProvider).read();
      if (restoredSession != null) {
        state = restoredSession;
      }
    } finally {
      ref.read(authBootstrapProvider.notifier).markReady();
    }
  }
}

class AuthBootstrapNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markReady() {
    state = true;
  }
}

class BusyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setBusy(bool value) {
    state = value;
  }
}
