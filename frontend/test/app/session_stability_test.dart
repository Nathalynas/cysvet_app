import 'package:cysvet_app/app/router.dart';
import 'package:cysvet_app/core/network/api_client.dart';
import 'package:cysvet_app/models/auth_session_model.dart';
import 'package:cysvet_app/providers/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AuthSessionModel sessao(String token, {int empresa = 1}) => AuthSessionModel(
    accessToken: token,
    refreshToken: 'r-$token',
    user: const AuthenticatedUserModel(id: 7, perfil: 'VETERINARIO'),
    activeCompanyId: empresa,
  );

  test('renovar o token não recria o router, o Dio nem a chave da sessão', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var chaveMudou = 0;
    container.listen(sessionKeyProvider, (_, _) => chaveMudou++);
    final router = container.read(appRouterProvider);
    final dio = container.read(apiClientProvider);

    final notifier = container.read(authSessionProvider.notifier);
    // Espera a restauração da sessão de abertura (armazenamento vazio).
    await pumpEventQueue();
    container.read(sessionKeyProvider);
    await notifier.setSession(sessao('a'));
    container.read(sessionKeyProvider);
    expect(chaveMudou, 1);

    await notifier.setSession(sessao('b'));
    container.read(sessionKeyProvider);

    expect(identical(container.read(appRouterProvider), router), isTrue);
    expect(identical(container.read(apiClientProvider), dio), isTrue);
    expect(chaveMudou, 1, reason: 'só o token mudou');

    await notifier.setSession(sessao('b', empresa: 2));
    container.read(sessionKeyProvider);
    expect(chaveMudou, 2, reason: 'troca de empresa recarrega as listas');
  });
}
