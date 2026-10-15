import 'package:cysvet_app/app/auth_redirect.dart';
import 'package:cysvet_app/models/auth_session_model.dart';
import 'package:flutter_test/flutter_test.dart';

AuthSessionModel _session({String perfil = 'ADMIN', bool trocarSenha = false}) {
  return AuthSessionModel(
    accessToken: 'token',
    user: AuthenticatedUserModel(perfil: perfil, trocarSenha: trocarSenha),
  );
}

String? _redirect(AuthSessionModel? session, String location) {
  return resolveAuthRedirect(
    bootstrapComplete: true,
    session: session,
    location: location,
  );
}

void main() {
  test('bootstrap incompleto envia para splash', () {
    expect(
      resolveAuthRedirect(
        bootstrapComplete: false,
        session: null,
        location: '/dashboard',
      ),
      '/splash',
    );
    expect(
      resolveAuthRedirect(
        bootstrapComplete: false,
        session: null,
        location: '/splash',
      ),
      isNull,
    );
  });

  test('sem sessao em /dashboard vai para /login', () {
    expect(_redirect(null, '/dashboard'), '/login');
  });

  test('sem sessao em rota desconhecida vai para /login', () {
    expect(_redirect(null, '/rota-inexistente'), '/login');
  });

  test('sem sessao em /login permanece', () {
    expect(_redirect(null, '/login'), isNull);
  });

  test('super usuario em /dashboard vai para /super', () {
    expect(_redirect(_session(perfil: 'SUPER_ADMIN'), '/dashboard'), '/super');
  });

  test('super usuario em /super permanece', () {
    expect(_redirect(_session(perfil: 'SUPER_ADMIN'), '/super'), isNull);
  });

  test('trocarSenha em /super vai para /trocar-senha', () {
    expect(
      _redirect(_session(perfil: 'SUPER_ADMIN', trocarSenha: true), '/super'),
      '/trocar-senha',
    );
  });

  test('trocarSenha em /dashboard vai para /trocar-senha', () {
    expect(
      _redirect(_session(trocarSenha: true), '/dashboard'),
      '/trocar-senha',
    );
  });

  test('trocarSenha em /trocar-senha permanece', () {
    expect(_redirect(_session(trocarSenha: true), '/trocar-senha'), isNull);
  });

  test('admin em /super vai para /dashboard', () {
    expect(_redirect(_session(), '/super'), '/dashboard');
  });

  test('admin em /login vai para /dashboard', () {
    expect(_redirect(_session(), '/login'), '/dashboard');
  });

  test('admin em /trocar-senha sem pendencia vai para /dashboard', () {
    expect(_redirect(_session(), '/trocar-senha'), '/dashboard');
  });

  test('veterinario em /usuarios vai para /dashboard', () {
    expect(
      _redirect(_session(perfil: 'VETERINARIO'), '/usuarios'),
      '/dashboard',
    );
  });

  test('admin em /usuarios permanece', () {
    expect(_redirect(_session(), '/usuarios'), isNull);
  });

  test('splash com super usuario vai para /super', () {
    expect(_redirect(_session(perfil: 'SUPER_ADMIN'), '/splash'), '/super');
  });

  test('splash com trocarSenha vai para /trocar-senha', () {
    expect(_redirect(_session(trocarSenha: true), '/splash'), '/trocar-senha');
  });

  test('splash sem sessao vai para /login', () {
    expect(_redirect(null, '/splash'), '/login');
  });
}
