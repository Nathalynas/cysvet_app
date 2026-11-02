import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/models/animal_summary_model.dart';
import 'package:cysvet_app/models/property_summary_model.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';
import 'package:cysvet_app/core/widgets/visit_in_progress_bar.dart';
import 'package:cysvet_app/pages/visits/visit_form_page.dart';
import 'package:cysvet_app/providers/animals_provider.dart';
import 'package:cysvet_app/providers/properties_provider.dart';
import 'package:cysvet_app/providers/reproductive_shortcuts_provider.dart';
import 'package:cysvet_app/providers/visits_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeAnimalsController extends AnimalsController {
  _FakeAnimalsController(super.ref, this.animals);

  final List<AnimalSummaryModel> animals;

  @override
  Future<List<AnimalSummaryModel>> listByProperty(int propertyId) async =>
      animals;
}

class _FakeVisitsController extends VisitsController {
  _FakeVisitsController(super.ref, this.saved);

  final List<VisitSummaryModel> saved;

  @override
  Future<List<VisitSummaryModel>> listByProperty(
    int propertyId, {
    String? excludeIdExterno,
  }) async => const [];

  @override
  Future<VisitSummaryModel> save(VisitSummaryModel visit) async {
    saved.add(visit);
    return visit;
  }
}

class _FakeShortcuts extends ReproductiveShortcutsNotifier {
  final saves = <List<AnimalReproductiveStatus>?>[];

  @override
  Future<List<AnimalReproductiveStatus>> build() async =>
      defaultReproductiveShortcuts;

  @override
  Future<bool> save(List<AnimalReproductiveStatus>? shortcuts) async {
    saves.add(shortcuts);
    state = AsyncData(shortcuts ?? defaultReproductiveShortcuts);
    return true;
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  late GoRouter lastRouter;

  final animals = [
    AnimalSummaryModel(
      id: 1,
      idExterno: 'animal-1',
      idPropriedade: 1,
      codigo: '101',
      statusReprodutivo: AnimalReproductiveStatus.empty,
    ),
    AnimalSummaryModel(
      id: 2,
      idExterno: 'animal-2',
      idPropriedade: 1,
      codigo: '102',
      statusReprodutivo: AnimalReproductiveStatus.empty,
    ),
  ];

  late _FakeShortcuts shortcuts;

  Future<List<VisitSummaryModel>> pumpForm(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    shortcuts = _FakeShortcuts();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final saved = <VisitSummaryModel>[];
    lastRouter = GoRouter(
      initialLocation: '/visitas/nova',
      routes: [
        GoRoute(
          path: '/visitas/nova',
          builder: (context, state) =>
              const Scaffold(body: VisitFormPage(initialPropertyId: 1)),
        ),
        GoRoute(
          path: '/animais',
          builder: (context, state) => const Scaffold(
            body: Column(
              children: [VisitInProgressBar(), Text('tela de animais')],
            ),
          ),
        ),
        GoRoute(
          path: '/visitas',
          builder: (context, state) => const Text('lista de visitas'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          propertiesProvider.overrideWith(
            (ref) async => const [
              PropertySummaryModel(id: 1, nome: 'Fazenda teste'),
            ],
          ),
          animalsControllerProvider.overrideWith(
            (ref) => _FakeAnimalsController(ref, animals),
          ),
          visitsControllerProvider.overrideWith(
            (ref) => _FakeVisitsController(ref, saved),
          ),
          reproductiveShortcutsProvider.overrideWith(() => shortcuts),
        ],
        child: MaterialApp.router(
          routerConfig: lastRouter,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return saved;
  }

  testWidgets(
    'marcar prenha e ir ao próximo salva o animal sem confirmar à parte',
    (tester) async {
      final saved = await pumpForm(tester);

      await tester.tap(find.text('101'));
      await tester.pumpAndSettle();
      expect(
        find.text('1 de 2 · ao trocar de animal o atual é salvo.'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Prenha'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Próximo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();

      // O modal já mostra o segundo animal; fecha sem mexer nele.
      expect(
        find.text('2 de 2 · ao trocar de animal o atual é salvo.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Concluir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Concluir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Finalizar visita'));
      await tester.pumpAndSettle();

      expect(saved, hasLength(1));
      final entries = saved.single.animais;
      expect(entries.map((entry) => entry.animalCodigo), ['101', '102']);
      expect(entries.first.situacaoReprodutiva, 'prenha');
    },
  );

  testWidgets('busca pelo brinco e "ir" abre direto o animal', (tester) async {
    await pumpForm(tester);

    await tester.enterText(find.byType(TextField).last, '102');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();

    expect(find.text('Brinco 102'), findsOneWidget);
  });

  testWidgets(
    'na tela larga, mudar a situação já conta como coleta sem confirmar',
    (tester) async {
      final saved = await pumpForm(tester, size: const Size(1400, 1000));

      // O primeiro animal já vem aberto no editor ao lado da lista.
      await tester.tap(find.widgetWithText(OutlinedButton, 'Prenha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finalizar visita'));
      await tester.pumpAndSettle();

      expect(saved, hasLength(1));
      expect(saved.single.animais, hasLength(1));
      expect(saved.single.animais.single.animalCodigo, '101');
      expect(saved.single.animais.single.situacaoReprodutiva, 'prenha');
    },
  );

  testWidgets('"Usar hoje" preenche a data da nova IA', (tester) async {
    final saved = await pumpForm(tester, size: const Size(1400, 1000));

    await tester.tap(find.text('Usar hoje').first);
    await tester.pumpAndSettle();

    final hoje = DateUtils.dateOnly(DateTime.now());
    expect(
      find.text(
        '${hoje.day.toString().padLeft(2, '0')}/'
        '${hoje.month.toString().padLeft(2, '0')}/${hoje.year}',
      ),
      findsWidgets,
    );
    // Some só o da nova IA; o do parto continua.
    expect(find.text('Usar hoje'), findsOneWidget);

    await tester.tap(find.text('Finalizar visita'));
    await tester.pumpAndSettle();

    final entry = saved.single.animais.single;
    expect(entry.dataUltimaIa, hoje);
    expect(entry.numeroIaRecebida, 1);
  });

  testWidgets('o calendário da nova IA abre em português', (tester) async {
    await pumpForm(tester, size: const Size(1400, 1000));

    await tester.tap(find.byTooltip('Abrir calendário').first);
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(find.text('Cancelar'), findsWidgets);
  });

  testWidgets('sair da visita e voltar mantém o que foi coletado', (
    tester,
  ) async {
    final saved = await pumpForm(tester, size: const Size(1400, 1000));

    await tester.tap(find.widgetWithText(OutlinedButton, 'Prenha'));
    await tester.pumpAndSettle();

    lastRouter.go('/animais');
    await tester.pumpAndSettle();
    expect(find.text('tela de animais'), findsOneWidget);
    expect(find.text('Visita em andamento'), findsOneWidget);
    expect(
      find.text('Fazenda teste · 1 animal coletado · não salva'),
      findsOneWidget,
    );

    await tester.tap(find.text('Voltar à visita'));
    await tester.pumpAndSettle();

    expect(find.text('Continuando a visita que ficou aberta.'), findsOneWidget);
    expect(find.text('1 com coleta'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Prenha'), findsOneWidget);

    await tester.tap(find.text('Finalizar visita'));
    await tester.pumpAndSettle();
    expect(saved.single.animais.single.situacaoReprodutiva, 'prenha');

    // Salva, a visita deixa de estar em andamento.
    lastRouter.go('/animais');
    await tester.pumpAndSettle();
    expect(find.text('Visita em andamento'), findsNothing);
  });

  testWidgets('"Começar outra" descarta a visita que ficou aberta', (
    tester,
  ) async {
    await pumpForm(tester, size: const Size(1400, 1000));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Prenha'));
    await tester.pumpAndSettle();
    lastRouter.go('/animais');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voltar à visita'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Começar outra'));
    await tester.pumpAndSettle();

    expect(find.text('0 com coleta'), findsOneWidget);
    expect(find.text('Continuando a visita que ficou aberta.'), findsNothing);
  });

  testWidgets(
    'no celular a mudança vai para a visita com o animal ainda aberto, '
    'e descartar desfaz',
    (tester) async {
      await pumpForm(tester);

      await tester.tap(find.text('101'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Prenha'));
      await tester.pumpAndSettle();

      // A tela da visita, atrás do modal, já tem o animal coletado.
      expect(find.text('1 com coleta', skipOffstage: false), findsOneWidget);

      await tester.ensureVisible(find.text('Descartar mudanças deste animal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Descartar mudanças deste animal'));
      await tester.pumpAndSettle();

      expect(find.text('0 com coleta'), findsOneWidget);
      expect(find.textContaining('prenha'), findsNothing);
    },
  );

  testWidgets(
    'voltar do Android com o animal aberto mantém o que foi marcado',
    (tester) async {
      final saved = await pumpForm(tester);

      await tester.tap(find.text('101'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Prenha'));
      await tester.pumpAndSettle();

      // Botão voltar do sistema fecha o modal.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('1 com coleta'), findsOneWidget);

      await tester.tap(find.text('Finalizar visita'));
      await tester.pumpAndSettle();
      expect(saved.single.animais.first.situacaoReprodutiva, 'prenha');
    },
  );

  testWidgets('"Outras situações" mostra as demais e grava a escolhida', (
    tester,
  ) async {
    final saved = await pumpForm(tester, size: const Size(1400, 1000));

    expect(find.widgetWithText(OutlinedButton, 'Descarte'), findsNothing);
    await tester.tap(find.text('Outras situações (10)'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Descarte'));
    await tester.pumpAndSettle();

    // Escolhida uma "outra", a lista continua aberta mostrando a marcada.
    expect(find.widgetWithText(FilledButton, 'Descarte'), findsOneWidget);
    await tester.tap(find.text('Finalizar visita'));
    await tester.pumpAndSettle();
    expect(saved.single.animais.single.situacaoReprodutiva, 'descarte');
  });

  testWidgets('veterinário escolhe os próprios atalhos', (tester) async {
    await pumpForm(tester, size: const Size(1400, 1000));

    await tester.tap(find.byTooltip('Escolher atalhos'));
    await tester.pumpAndSettle();
    for (final label in ['Vazia', 'Em protocolo']) {
      final tile = find.widgetWithText(CheckboxListTile, label);
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
    }
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salvar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(shortcuts.saves.single, [
      AnimalReproductiveStatus.pregnant,
      AnimalReproductiveStatus.inseminated,
      AnimalReproductiveStatus.waitingDiagnosis,
      AnimalReproductiveStatus.protocol,
    ]);
    expect(find.widgetWithText(OutlinedButton, 'Em protocolo'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Vazia'), findsNothing);
  });

  testWidgets('data do último parto fica à vista, fora de "Mais detalhes"', (
    tester,
  ) async {
    await pumpForm(tester, size: const Size(1400, 1000));

    expect(find.text('Data último parto'), findsOneWidget);
    expect(find.text('Diagnóstico'), findsNothing);
  });
}
