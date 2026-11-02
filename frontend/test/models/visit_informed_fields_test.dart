import 'package:cysvet_app/models/visit_informed_fields.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const doCache = VisitAnimalEntryModel(
    animalId: 1,
    situacaoReprodutiva: 'vazia',
    camposInformados: [],
  );

  test('só o campo alterado entra; a situação do cache fica de fora', () {
    final editado = withInformedChanges(
      doCache,
      doCache.copyWith(controleLeiteiro: 28.5),
    );
    expect(editado.camposInformados, ['controleLeiteiro']);

    final prenha = withInformedChanges(
      editado,
      editado.copyWith(situacaoReprodutiva: 'prenha'),
    );
    expect(prenha.camposInformados, ['situacaoReprodutiva', 'controleLeiteiro']);
  });

  test('voltar ao valor original continua marcado (foi uma escolha)', () {
    final prenha = withInformedChanges(
      doCache,
      doCache.copyWith(situacaoReprodutiva: 'prenha'),
    );
    final deVolta = withInformedChanges(
      prenha,
      prenha.copyWith(situacaoReprodutiva: 'vazia'),
    );
    expect(deVolta.camposInformados, ['situacaoReprodutiva']);
  });

  test('visita de versão antiga (lista nula) continua com todos', () {
    const antiga = VisitAnimalEntryModel(animalId: 2, situacaoReprodutiva: 'vazia');
    final editada = withInformedChanges(
      antiga,
      antiga.copyWith(situacaoReprodutiva: 'prenha'),
    );
    expect(editada.camposInformados, isNull);
  });

  test('confirmar o animal marca as situações como observadas', () {
    expect(
      withConfirmedSituation(doCache).camposInformados,
      ['situacaoReprodutiva', 'situacaoProdutiva'],
    );
  });
}
