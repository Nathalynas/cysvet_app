import 'package:cysvet_app/core/widgets/sync_status_bar.dart';
import 'package:cysvet_app/providers/connectivity_provider.dart';
import 'package:cysvet_app/providers/sync_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeSyncController extends SyncController {
  _FakeSyncController(this.initial);

  final SyncState initial;

  @override
  SyncState build() => initial;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpBar(WidgetTester tester, SyncState state) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncControllerProvider.overrideWith(() => _FakeSyncController(state)),
          isOfflineProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(home: Scaffold(body: SyncStatusBar())),
      ),
    );
  }

  testWidgets('some quando tudo foi sincronizado e não há aviso', (
    tester,
  ) async {
    await pumpBar(tester, const SyncState(enabled: true));

    expect(find.byType(Material), findsWidgets);
    expect(find.textContaining('sincroniz'), findsNothing);
    expect(find.textContaining('enviado'), findsNothing);
  });

  testWidgets('alteração não aceita continua visível até fechar', (
    tester,
  ) async {
    await pumpBar(
      tester,
      const SyncState(
        enabled: true,
        rejectedNotice: 'Não foi aceito: animal 101.',
      ),
    );

    expect(find.text('Alteração não aceita pelo servidor'), findsOneWidget);
    expect(find.text('Não foi aceito: animal 101.'), findsOneWidget);

    await tester.tap(find.byTooltip('Fechar aviso'));
    await tester.pump();

    expect(find.text('Alteração não aceita pelo servidor'), findsNothing);
  });

  testWidgets('mostra o envio recém-concluído', (tester) async {
    await pumpBar(tester, const SyncState(enabled: true, justSentCount: 3));

    expect(find.text('Tudo enviado ao servidor'), findsOneWidget);
    expect(find.text('3 registros enviados.'), findsOneWidget);
  });
}
