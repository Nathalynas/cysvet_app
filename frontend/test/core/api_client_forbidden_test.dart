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

  group('handleForbiddenAction', () {
    ({int clears, List<String> warnings}) run(
      ForbiddenAction action, {
      bool hasSession = true,
    }) {
      var clears = 0;
      final warnings = <String>[];
      handleForbiddenAction(
        action,
        hasSession: hasSession,
        clearSession: () => clears++,
        warn: warnings.add,
      );
      return (clears: clears, warnings: warnings);
    }

    test('troca de senha obrigatoria limpa a sessao e avisa', () {
      final result = run(ForbiddenAction.passwordChangeRequired);
      expect(result.clears, 1);
      expect(result.warnings, [
        'Sua senha foi redefinida. Entre com a senha provisória enviada por e-mail.',
      ]);
    });

    test('empresa desativada limpa a sessao e avisa', () {
      final result = run(ForbiddenAction.companyDeactivated);
      expect(result.clears, 1);
      expect(result.warnings, [
        'Sua empresa foi desativada. Fale com o suporte do CYSVET.',
      ]);
    });

    test('sem sessao nao faz nada', () {
      for (final action in [
        ForbiddenAction.passwordChangeRequired,
        ForbiddenAction.companyDeactivated,
      ]) {
        final result = run(action, hasSession: false);
        expect(result.clears, 0);
        expect(result.warnings, isEmpty);
      }
    });

    test('none nao faz nada', () {
      final result = run(ForbiddenAction.none);
      expect(result.clears, 0);
      expect(result.warnings, isEmpty);
    });
  });
}
