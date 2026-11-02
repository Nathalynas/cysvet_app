import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/models/gestational_loss.dart';
import 'package:cysvet_app/models/indicador_reprodutivo_calculator.dart';
import 'package:cysvet_app/models/visit_action_hint.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final visita = DateTime(2026, 11, 1);

  VisitAnimalEntryModel prenhaHa(int dias) =>
      IndicadorReprodutivoCalculator.applyAutomaticCalculations(
        entry: VisitAnimalEntryModel(
          animalId: 1,
          situacaoReprodutiva: 'prenha',
          situacaoProdutiva: AnimalProductiveSituation.lactating,
          dataUltimaIa: visita.subtract(Duration(days: dias)),
        ),
        dataAtual: visita,
      );

  test('prenha que vira vazia sugere reabsorção antes de 45 dias', () {
    final entry = withReproductiveStatus(prenhaHa(40), 'vazia');
    expect(entry.situacaoReprodutiva, 'vazia');
    expect(entry.tipoPerda, 'reabsorcao');
  });

  test('prenha que vira vazia com 45 dias ou mais sugere aborto', () {
    expect(withReproductiveStatus(prenhaHa(80), 'vazia').tipoPerda, 'aborto');
  });

  test('voltar a prenha desfaz a perda', () {
    final vazia = withReproductiveStatus(
      prenhaHa(80),
      'vazia',
    ).copyWith(causaPerda: 'BVD');
    final denovo = withReproductiveStatus(vazia, 'prenha');
    expect(denovo.tipoPerda, isNull);
    expect(denovo.causaPerda, isNull);
  });

  test('vazia que continua vazia não inventa perda', () {
    const entry = VisitAnimalEntryModel(animalId: 2, situacaoReprodutiva: 'pev');
    expect(withReproductiveStatus(entry, 'vazia').tipoPerda, isNull);
  });

  test('prenhez entre 60 e 75 dias lembra de reconfirmar', () {
    List<String> hints(int dias) => visitActionHints(
      prenhaHa(dias),
      dataVisita: visita,
    ).map((hint) => hint.label).toList();

    expect(hints(62), contains('Reconfirmar prenhez · 62 dias'));
    expect(hints(50).where((h) => h.startsWith('Reconfirmar')), isEmpty);
    expect(hints(80).where((h) => h.startsWith('Reconfirmar')), isEmpty);
  });
}
