import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/core/widgets/app_date_field.dart';
import 'package:cysvet_app/models/animal_summary_model.dart';
import 'package:cysvet_app/models/property_summary_model.dart';
import 'package:cysvet_app/pages/animals/animal_dialog.dart';
import 'package:cysvet_app/providers/animals_provider.dart';
import 'package:cysvet_app/providers/reproductive_shortcuts_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeAnimalsController extends AnimalsController {
  _FakeAnimalsController(super.ref, this.saved);

  final List<AnimalSummaryModel> saved;

  @override
  Future<void> save(AnimalSummaryModel animal) async => saved.add(animal);
}

class _DefaultShortcuts extends ReproductiveShortcutsNotifier {
  @override
  Future<List<AnimalReproductiveStatus>> build() async =>
      defaultReproductiveShortcuts;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<List<AnimalSummaryModel>> openDialog(
    WidgetTester tester, {
    AnimalSummaryModel? animal,
  }) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final saved = <AnimalSummaryModel>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animalsControllerProvider.overrideWith(
            (ref) => _FakeAnimalsController(ref, saved),
          ),
          reproductiveShortcutsProvider.overrideWith(_DefaultShortcuts.new),
        ],
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AnimalDialog.show(
                  context,
                  properties: const [
                    PropertySummaryModel(
                      id: 7,
                      idExterno: 'prop-7',
                      nome: 'Sítio Boa Água',
                    ),
                  ],
                  animal: animal,
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return saved;
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('cadastro novo com botões, propriedade única já escolhida', (
    tester,
  ) async {
    final saved = await openDialog(tester);

    expect(find.text('Sítio Boa Água'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '250');
    await tester.enterText(
      find.descendant(
        of: find.byType(AppDateField).first,
        matching: find.byType(TextField),
      ),
      '10032022',
    );
    await tapVisible(tester, find.widgetWithText(OutlinedButton, 'Prenha'));
    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Lactante'));
    await tapVisible(tester, find.byTooltip('Mais uma lactação'));
    await tapVisible(tester, find.byTooltip('Mais uma lactação'));
    await tapVisible(tester, find.text('Usar hoje').first);
    await tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, 'Cadastrar animal'),
    );

    final animal = saved.single;
    expect(animal.codigo, '250');
    expect(animal.idPropriedade, 7);
    expect(animal.idExternoPropriedade, 'prop-7');
    expect(animal.dataNascimento, DateTime(2022, 3, 10));
    expect(animal.statusReprodutivo, AnimalReproductiveStatus.pregnant);
    expect(animal.situacaoProdutiva, AnimalProductiveSituation.lactating);
    expect(animal.numeroLactacao, 2);
    expect(animal.dataUltimoParto, DateUtils.dateOnly(DateTime.now()));
  });

  testWidgets('nascimento é opcional, como na importação da planilha', (
    tester,
  ) async {
    final saved = await openDialog(tester);

    await tester.enterText(find.byType(TextField).first, '251');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, 'Cadastrar animal'),
    );

    expect(saved.single.codigo, '251');
    expect(saved.single.dataNascimento, isNull);
    expect(saved.single.statusReprodutivo, AnimalReproductiveStatus.pending);
  });

  testWidgets('brinco é obrigatório', (tester) async {
    final saved = await openDialog(tester);

    await tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, 'Cadastrar animal'),
    );

    expect(saved, isEmpty);
    expect(find.text('Campo obrigatório'), findsOneWidget);
  });

  testWidgets('edição mostra a situação salva marcada', (tester) async {
    await openDialog(
      tester,
      animal: const AnimalSummaryModel(
        id: 3,
        idPropriedade: 7,
        codigo: '103',
        statusReprodutivo: AnimalReproductiveStatus.discard,
        situacaoProdutiva: AnimalProductiveSituation.dry,
      ),
    );

    expect(find.text('Editar animal 103'), findsOneWidget);
    // "Descarte" não é atalho: "Outras situações" já abre com ela marcada.
    expect(find.widgetWithText(FilledButton, 'Descarte'), findsOneWidget);
    final dry = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Seca'),
    );
    expect(dry.selected, isTrue);
  });
}
