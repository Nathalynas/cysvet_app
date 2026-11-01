import 'package:cysvet_app/api/account_api.dart';
import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/local/sync_queue_store.dart';
import 'package:cysvet_app/models/auth_session_model.dart';
import 'package:cysvet_app/providers/auth_state.dart';
import 'package:cysvet_app/providers/offline_first.dart';
import 'package:cysvet_app/providers/reproductive_shortcuts_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore extends SyncQueueStore {
  _MemoryStore() : super(() => throw UnimplementedError());

  final values = <String, String?>{};

  @override
  Future<String?> readMeta(String key) async => values[key];

  @override
  Future<void> writeMeta(String key, String? value) async {
    values[key] = value;
  }
}

/// Servidor falso: guarda os atalhos e pode ficar "sem sinal".
class _FakeAccount extends AccountRepository {
  _FakeAccount() : super(Dio());

  List<String>? server;
  bool offline = false;

  void _check() {
    if (offline) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/account/preferences'),
        type: DioExceptionType.connectionError,
      );
    }
  }

  @override
  Future<List<String>> reproductiveShortcuts() async {
    _check();
    return server ?? ['prenha', 'vazia', 'inseminada', 'aguardando dg'];
  }

  @override
  Future<List<String>> saveReproductiveShortcuts(List<String>? values) async {
    _check();
    server = values;
    return reproductiveShortcuts();
  }
}

class _Session extends AuthSessionNotifier {
  @override
  AuthSessionModel? build() => const AuthSessionModel(
    accessToken: 'a',
    user: AuthenticatedUserModel(id: 2),
    activeCompanyId: 1,
  );
}

void main() {
  late _MemoryStore store;
  late _FakeAccount account;

  ProviderContainer container() {
    final container = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith(_Session.new),
        offlineScopeProvider.overrideWithValue(
          const OfflineScope(companyId: 1, userId: 2),
        ),
        syncQueueStoreProvider.overrideWithValue(store),
        accountRepositoryProvider.overrideWithValue(account),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    store = _MemoryStore();
    account = _FakeAccount();
  });

  test('sem escolha usa os quatro padrão do servidor', () async {
    final shortcuts = await container().read(
      reproductiveShortcutsProvider.future,
    );
    expect(shortcuts, defaultReproductiveShortcuts);
  });

  test('salvar envia ao servidor', () async {
    final c = container();
    await c.read(reproductiveShortcutsProvider.future);

    final synced = await c.read(reproductiveShortcutsProvider.notifier).save([
      AnimalReproductiveStatus.protocol,
    ]);

    expect(synced, isTrue);
    expect(account.server, ['em protocolo']);
    expect(c.read(reproductiveShortcutsProvider).value, [
      AnimalReproductiveStatus.protocol,
    ]);
  });

  test('sem sinal guarda no aparelho e envia na próxima abertura', () async {
    final first = container();
    await first.read(reproductiveShortcutsProvider.future);
    account.offline = true;

    final synced = await first
        .read(reproductiveShortcutsProvider.notifier)
        .save([AnimalReproductiveStatus.discard]);
    expect(synced, isFalse);
    expect(account.server, isNull);

    // Ainda sem sinal: a visita usa a cópia do aparelho.
    final offline = container();
    expect(await offline.read(reproductiveShortcutsProvider.future), [
      AnimalReproductiveStatus.discard,
    ]);
    offline.dispose();

    account.offline = false;
    final online = container();
    expect(await online.read(reproductiveShortcutsProvider.future), [
      AnimalReproductiveStatus.discard,
    ]);
    expect(account.server, ['descarte']);
  });
}
