import 'package:cysvet_app/models/animal_summary_model.dart';
import 'package:cysvet_app/models/property_summary_model.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';
import 'package:cysvet_app/pages/animals/animals_page.dart';
import 'package:cysvet_app/pages/visits/visits_page.dart';
import 'package:cysvet_app/providers/animals_provider.dart';
import 'package:cysvet_app/providers/properties_provider.dart';
import 'package:cysvet_app/providers/visits_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// As listas do celular montam só os cartões visíveis; a rolagem ainda precisa
/// alcançar o último registro e o rodapé.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const total = 200;
  final animals = List.generate(
    total,
    (i) => AnimalSummaryModel(
      id: i + 1,
      idPropriedade: 1,
      codigo: 'AN-${i.toString().padLeft(5, '0')}',
    ),
  );
  final visits = List.generate(
    total,
    (i) => VisitSummaryModel(
      id: i + 1,
      idPropriedade: 1,
      dataVisita: DateTime(2026, 1, 1).add(Duration(days: i)),
      nomeUsuario: 'Veterinario teste',
      observacoes: 'Visita de teste $i',
    ),
  );

  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animalsProvider.overrideWith((ref) async => animals),
          visitsProvider.overrideWith((ref) async => visits),
          propertiesProvider.overrideWith(
            (ref) async => const [
              PropertySummaryModel(id: 1, nome: 'Fazenda teste'),
            ],
          ),
        ],
        child: MaterialApp(home: page),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lista de animais monta sob demanda e chega ao fim', (
    tester,
  ) async {
    await pumpPage(tester, const AnimalsPage());

    expect(find.textContaining('AN-00000'), findsOneWidget);
    expect(find.textContaining('AN-00199'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('$total registros no filtro atual'),
      2000,
      maxScrolls: 200,
      scrollable: _pageScrollable(),
    );
    expect(find.textContaining('AN-00199'), findsOneWidget);
    expect(find.textContaining('AN-00000'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lista de visitas monta sob demanda e chega ao fim', (
    tester,
  ) async {
    await pumpPage(tester, const VisitsPage());

    expect(find.textContaining('19/07/2026'), findsNothing);
    await tester.scrollUntilVisible(
      find.textContaining('19/07/2026'),
      2000,
      maxScrolls: 200,
      scrollable: _pageScrollable(),
    );
    expect(find.textContaining('19/07/2026'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Finder _pageScrollable() => find
    .descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    )
    .first;
