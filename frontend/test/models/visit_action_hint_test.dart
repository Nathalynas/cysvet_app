import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/models/indicador_reprodutivo_calculator.dart';
import 'package:cysvet_app/models/visit_action_hint.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final visita = DateTime(2026, 11, 1);

  List<String> labels(VisitAnimalEntryModel entry) {
    final calculated =
        IndicadorReprodutivoCalculator.applyAutomaticCalculations(
          entry: entry,
          dataAtual: visita,
        );
    return visitActionHints(
      calculated,
      dataVisita: visita,
    ).map((hint) => hint.label).toList();
  }

  test('inseminada há 30 dias ou mais pede diagnóstico', () {
    expect(
      labels(
        VisitAnimalEntryModel(
          animalId: 1,
          situacaoReprodutiva: 'aguardando dg',
          dataUltimaIa: DateTime(2026, 9, 25),
        ),
      ),
      ['Fazer DG · IA há 37 dias'],
    );
    expect(
      labels(
        VisitAnimalEntryModel(
          animalId: 2,
          situacaoReprodutiva: 'inseminada',
          dataUltimaIa: DateTime(2026, 10, 20),
        ),
      ),
      isEmpty,
    );
  });

  test('prenha perto de 220 dias pede secagem e atrasada vem primeiro', () {
    // IA há 210 dias: secar em 10 dias.
    expect(
      labels(
        VisitAnimalEntryModel(
          animalId: 3,
          situacaoReprodutiva: 'prenha',
          situacaoProdutiva: AnimalProductiveSituation.lactating,
          dataUltimaIa: visita.subtract(const Duration(days: 210)),
        ),
      ),
      ['Secar em 10 dias'],
    );
    // IA há 260 dias: secagem atrasada e parto em 22 dias.
    expect(
      labels(
        VisitAnimalEntryModel(
          animalId: 4,
          situacaoReprodutiva: 'prenha',
          situacaoProdutiva: AnimalProductiveSituation.lactating,
          dataUltimaIa: visita.subtract(const Duration(days: 260)),
        ),
      ),
      ['Secagem atrasada 40 dias', 'Pré-parto · parto em 22 dias'],
    );
  });

  test('vaca seca prenha perto do parto só pede pré-parto', () {
    expect(
      labels(
        VisitAnimalEntryModel(
          animalId: 5,
          situacaoReprodutiva: 'prenha',
          situacaoProdutiva: AnimalProductiveSituation.dry,
          dataUltimaIa: visita.subtract(const Duration(days: 270)),
        ),
      ),
      ['Pré-parto · parto em 12 dias'],
    );
  });

  test('vazia com DEL alto sem IA aparece', () {
    expect(
      labels(
        VisitAnimalEntryModel(
          animalId: 6,
          situacaoReprodutiva: AnimalReproductiveStatus.empty.apiValue,
          situacaoProdutiva: AnimalProductiveSituation.lactating,
          dataUltimoParto: visita.subtract(const Duration(days: 90)),
        ),
      ),
      ['Sem IA · DEL 90'],
    );
  });

  test('prenha muito além da previsão pede confirmar o parto', () {
    // IA há 282 + 15 dias: ainda dentro da tolerância, segue "parto previsto".
    expect(
      labels(
        VisitAnimalEntryModel(
          animalId: 10,
          situacaoReprodutiva: 'prenha',
          situacaoProdutiva: AnimalProductiveSituation.dry,
          dataUltimaIa: visita.subtract(const Duration(days: 297)),
        ),
      ),
      ['Parto previsto há 15 dias'],
    );
    // 522 dias de prenhez, em pré-parto: antes não gerava aviso nenhum.
    expect(
      labels(
        VisitAnimalEntryModel(
          animalId: 11,
          situacaoReprodutiva: 'prenha',
          situacaoProdutiva: AnimalProductiveSituation.prepartum,
          dataUltimaIa: visita.subtract(const Duration(days: 522)),
        ),
      ),
      ['Confirmar parto · previsto há 240 dias'],
    );
  });
}
