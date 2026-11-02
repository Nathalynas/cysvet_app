import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/models/animal_summary_model.dart';
import 'package:cysvet_app/models/property_summary_model.dart';
import 'package:cysvet_app/models/today_summary.dart';
import 'package:cysvet_app/pages/today/today_page.dart';
import 'package:cysvet_app/providers/today_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final hoje = DateTime.now();
  final animais = [
    AnimalSummaryModel(
      id: 1,
      idPropriedade: 10,
      codigo: '1234',
      statusReprodutivo: AnimalReproductiveStatus.inseminated,
      dataInseminacao: hoje.subtract(const Duration(days: 34)),
    ),
    AnimalSummaryModel(
      id: 2,
      idPropriedade: 10,
      codigo: '871',
      statusReprodutivo: AnimalReproductiveStatus.pregnant,
      situacaoProdutiva: AnimalProductiveSituation.lactating,
      dataInseminacao: hoje.subtract(const Duration(days: 100)),
    ),
  ];
  final fazendas = [
    TodayFarm(
      property: const PropertySummaryModel(id: 10, nome: 'Sítio Boa Vista'),
      animals: animais,
      summary: TodaySummary.build(animais, hoje),
      lastVisit: DateTime(2026, 10, 18),
    ),
    TodayFarm(
      property: const PropertySummaryModel(id: 11, nome: 'Estância Rio Claro'),
      animals: const [],
      summary: TodaySummary.build(const [], hoje),
    ),
  ];

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [todayFarmsProvider.overrideWith((ref) async => fazendas)],
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lista as fazendas com quantos animais precisam de atenção', (
    tester,
  ) async {
    await pump(tester, const TodayPage());

    expect(find.text('Sítio Boa Vista'), findsOneWidget);
    expect(find.text('1 atenção'), findsOneWidget);
    expect(find.text('em dia'), findsOneWidget);
  });

  testWidgets('a fazenda mostra os grupos, a busca e a nova visita', (
    tester,
  ) async {
    await pump(tester, const TodayFarmPage(propertyId: 10));

    expect(find.text('Nova visita aqui'), findsOneWidget);
    expect(find.text('Precisam de atenção (1)'), findsOneWidget);
    await tester.tap(find.text('Fazer DG'));
    await tester.pumpAndSettle();
    expect(find.text('Fazer DG · IA há 34 dias'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '87');
    await tester.pumpAndSettle();
    expect(find.text('871'), findsOneWidget);
    expect(find.textContaining('Prenha · 100 d'), findsOneWidget);
  });
}
