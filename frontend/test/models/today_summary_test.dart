import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/models/animal_summary_model.dart';
import 'package:cysvet_app/models/today_summary.dart';
import 'package:cysvet_app/models/visit_action_hint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final hoje = DateTime(2026, 11, 1);
  DateTime haDias(int dias) => hoje.subtract(Duration(days: dias));

  final rebanho = [
    // Inseminada há 35 dias: DG.
    AnimalSummaryModel(
      id: 1,
      codigo: '101',
      statusReprodutivo: AnimalReproductiveStatus.inseminated,
      dataInseminacao: haDias(35),
    ),
    // Prenha há 210 dias, lactante: secar em 10 dias (e parto em 72).
    AnimalSummaryModel(
      id: 2,
      codigo: '102',
      statusReprodutivo: AnimalReproductiveStatus.pregnant,
      situacaoProdutiva: AnimalProductiveSituation.lactating,
      dataInseminacao: haDias(210),
    ),
    // Prenha há 265 dias, seca: pré-parto e parto em 17 dias.
    AnimalSummaryModel(
      id: 3,
      codigo: '103',
      statusReprodutivo: AnimalReproductiveStatus.pregnant,
      situacaoProdutiva: AnimalProductiveSituation.dry,
      dataInseminacao: haDias(265),
    ),
    // Vazia, DEL 90: sem IA.
    AnimalSummaryModel(
      id: 4,
      codigo: '104',
      statusReprodutivo: AnimalReproductiveStatus.empty,
      situacaoProdutiva: AnimalProductiveSituation.lactating,
      dataUltimoParto: haDias(90),
    ),
    // Vendida: fora da conta.
    AnimalSummaryModel(
      id: 5,
      codigo: '105',
      statusReprodutivo: AnimalReproductiveStatus.inseminated,
      dataInseminacao: haDias(40),
      status: AnimalStatus.sold,
    ),
  ];

  test('agrupa as ações da fazenda pelas regras da visita', () {
    final summary = TodaySummary.build(rebanho, hoje);

    List<String> codigos(VisitActionKind kind) =>
        summary.byKind[kind]!.map((a) => a.animal.codigo).toList();

    expect(codigos(VisitActionKind.diagnosis), ['101']);
    expect(codigos(VisitActionKind.dryOff), ['102']);
    expect(codigos(VisitActionKind.prepartum), ['103']);
    expect(codigos(VisitActionKind.noService), ['104']);
    expect(summary.animalsNeedingAttention, 4);
    expect(summary.totalAnimals, 4);
  });

  test('conta partos, secagens e pré-partos dos próximos 30 dias', () {
    final summary = TodaySummary.build(rebanho, hoje);
    expect(summary.upcomingCalvings, 1); // 103
    expect(summary.upcomingDryOffs, 1); // 102
    expect(summary.upcomingPrepartum, 0); // pré-parto da 103 já passou
  });
}
