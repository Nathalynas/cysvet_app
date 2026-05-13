import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/auth_session_model.dart';

class AuthSessionStorage {
  const AuthSessionStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'cysvet.auth.session';

  final FlutterSecureStorage _storage;

  Future<AuthSessionModel?> read() async {
    final json = await _storage.read(key: _sessionKey);
    if (json == null || json.isEmpty) return null;

    try {
      final session = AuthSessionModelMapper.fromJson(json);
      if (session.accessToken.isEmpty) return null;
      return session;
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> save(AuthSessionModel session) {
    return _storage.write(key: _sessionKey, value: session.toJson());
  }

  Future<void> clear() {
    return _storage.delete(key: _sessionKey);
  }
}
