import 'package:cysvet_app/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('403 Empresa desativada', () {
    expect(
      classifyForbidden(403, {'message': 'Empresa desativada'}),
      ForbiddenAction.companyDeactivated,
    );
  });

  test('403 Troca de senha obrigatoria', () {
    expect(
      classifyForbidden(403, {'message': 'Troca de senha obrigatoria'}),
      ForbiddenAction.passwordChangeRequired,
    );
  });

  test('403 com outra mensagem nao faz nada', () {
    expect(
      classifyForbidden(403, {'message': 'Acesso negado'}),
      ForbiddenAction.none,
    );
  });

  test('401 nao faz nada', () {
    expect(
      classifyForbidden(401, {'message': 'Empresa desativada'}),
      ForbiddenAction.none,
    );
  });

  test('data nulo ou string nao faz nada', () {
    expect(classifyForbidden(403, null), ForbiddenAction.none);
    expect(classifyForbidden(403, 'Empresa desativada'), ForbiddenAction.none);
  });
}
