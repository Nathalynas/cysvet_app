import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/auth_session_model.dart';

final authSessionStorageProvider = Provider<AuthSessionStorage>((ref) {
  return AuthSessionStorage(const FlutterSecureStorage());
});

class AuthSessionStorage {
  AuthSessionStorage(this._storage);

  static const _sessionKey = 'cysvet.auth.session';

  final FlutterSecureStorage _storage;

  Future<AuthSessionModel?> read() async {
    final rawValue = await _storage.read(key: _sessionKey);
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(rawValue);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return AuthSessionModelMapper.fromMap(decoded);
  }

  Future<void> write(AuthSessionModel session) {
    return _storage.write(
      key: _sessionKey,
      value: jsonEncode(session.toMap()),
    );
  }

  Future<void> clear() {
    return _storage.delete(key: _sessionKey);
  }
}
