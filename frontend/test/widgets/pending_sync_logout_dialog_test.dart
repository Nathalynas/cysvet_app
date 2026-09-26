import 'package:cysvet_app/core/widgets/pending_sync_logout_dialog.dart';
import 'package:cysvet_app/providers/sync_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeSyncController extends SyncController {
  _FakeSyncController(this.initial, {this.afterSync});

  final SyncState initial;
  final SyncState? afterSync;
  int syncCalls = 0;

  @override
  SyncState build() => initial;

  @override
  Future<bool> syncNow() async {
    syncCalls++;
    if (afterSync != null) state = afterSync!;
    return true;
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<bool? Function()> pumpHarness(
    WidgetTester tester,
    _FakeSyncController controller,
  ) async {
    bool? result;
    final done = <bool>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [syncControllerProvider.overrideWith(() => controller)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () async {
                result = await confirmLogoutWithPendingSync(context, ref);
                done.add(true);
              },
              child: const Text('Sair'),
            ),
          ),
        ),
      ),
    );
    return () => done.isEmpty ? null : result;
  }

  testWidgets('sai direto quando nao ha pendencias', (tester) async {
    final controller = _FakeSyncController(const SyncState(enabled: true));
    final result = await pumpHarness(tester, controller);

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(find.text('Alterações não enviadas'), findsNothing);
    expect(result(), isTrue);
  });

  testWidgets('avisa sobre pendencias e respeita "Sair mesmo assim"', (
    tester,
  ) async {
    final controller = _FakeSyncController(
      const SyncState(enabled: true, pendingCount: 2),
    );
    final result = await pumpHarness(tester, controller);

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(
      find.text('2 alterações ainda não foram enviadas ao servidor.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Sair mesmo assim'));
    await tester.pumpAndSettle();
    expect(result(), isTrue);
    expect(controller.syncCalls, 0);
  });

  testWidgets('sincroniza e sai quando a fila esvazia', (tester) async {
    final controller = _FakeSyncController(
      const SyncState(enabled: true, pendingCount: 1),
      afterSync: const SyncState(enabled: true),
    );
    final result = await pumpHarness(tester, controller);

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sincronizar agora'));
    await tester.pumpAndSettle();

    expect(controller.syncCalls, 1);
    expect(find.text('Alterações não enviadas'), findsNothing);
    expect(result(), isTrue);
  });

  testWidgets('fechar o aviso cancela a saida', (tester) async {
    final controller = _FakeSyncController(
      const SyncState(enabled: true, pendingCount: 1),
    );
    final result = await pumpHarness(tester, controller);

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();

    expect(result(), isFalse);
  });
}
