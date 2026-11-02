import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/models/indicador_reprodutivo_calculator.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  VisitAnimalEntryModel calcular(
    VisitAnimalEntryModel entry,
    DateTime dataVisita,
  ) {
    return IndicadorReprodutivoCalculator.applyAutomaticCalculations(
      entry: entry,
      dataAtual: dataVisita,
    );
  }

  test('DEL é contado até a data da visita, não até hoje', () {
    // Visita antiga: o DEL não pode mudar conforme o dia em que é reaberta.
    final entry = VisitAnimalEntryModel(
      animalId: 1,
      situacaoProdutiva: AnimalProductiveSituation.lactating,
      dataUltimoParto: DateTime(2020, 1, 1),
    );
    expect(calcular(entry, DateTime(2020, 3, 31)).del, 90);
  });

  test('prazos do PDF real: IA 10/05/25 → secagem, pré-parto e parto', () {
    final entry = calcular(
      VisitAnimalEntryModel(
        animalId: 2,
        situacaoReprodutiva: 'prenha',
        situacaoProdutiva: AnimalProductiveSituation.lactating,
        dataUltimaIa: DateTime(2025, 5, 10),
      ),
      DateTime(2025, 9, 1),
    );
    expect(entry.previsaoSecagem, DateTime(2025, 12, 16));
    expect(entry.dataPreParto, DateTime(2026, 1, 17));
    expect(entry.previsaoParto, DateTime(2026, 2, 16));
  });

  test('previsão de parto atravessa o 29 de fevereiro', () {
    final entry = calcular(
      VisitAnimalEntryModel(
        animalId: 3,
        situacaoReprodutiva: 'prenha',
        dataUltimaIa: DateTime(2023, 5, 23),
      ),
      DateTime(2023, 9, 1),
    );
    expect(entry.previsaoParto, DateTime(2024, 2, 29));
  });
}
