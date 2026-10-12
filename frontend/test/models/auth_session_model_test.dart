import 'package:cysvet_app/models/auth_session_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sessao de super usuario aceita empresaAtivaId nulo e sem empresas', () {
    final session = AuthSessionModelMapper.fromMap({
      'accessToken': 'a',
      'refreshToken': 'r',
      'user': {
        'id': 1,
        'name': 'L',
        'email': 'l@x',
        'perfil': 'SUPER_ADMIN',
        'trocarSenha': false,
      },
      'empresaAtivaId': null,
      'empresas': [],
    });

    expect(session.activeCompanyId, 0);
    expect(session.user.isSuperAdmin, isTrue);
    expect(session.user.displayRole, 'Super usuário');
    expect(session.companies, isEmpty);
  });

  test('sessao sem a chave empresaAtivaId tambem e aceita', () {
    final session = AuthSessionModelMapper.fromMap({
      'accessToken': 'a',
      'user': {'perfil': 'SUPER_ADMIN', 'trocarSenha': true},
    });

    expect(session.activeCompanyId, 0);
    expect(session.user.trocarSenha, isTrue);
  });

  test('trocarSenha e preservada ao serializar e restaurar', () {
    final session = AuthSessionModelMapper.fromMap({
      'accessToken': 'a',
      'user': {'perfil': 'ADMIN', 'trocarSenha': true},
    });

    final restored = AuthSessionModelMapper.fromMap(session.toMap());

    expect(restored.user.trocarSenha, isTrue);
  });
}
