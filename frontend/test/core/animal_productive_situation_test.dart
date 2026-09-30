import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final secagem = DateTime(2025, 12, 16);

  test('informar a secagem troca lactante ou vazia por seca', () {
    expect(
      AnimalProductiveSituation.afterDryOff(
        AnimalProductiveSituation.lactating,
        secagem,
      ),
      AnimalProductiveSituation.dry,
    );
    expect(
      AnimalProductiveSituation.afterDryOff(null, secagem),
      AnimalProductiveSituation.dry,
    );
  });

  test('pré-parto e novilha não mudam com a secagem', () {
    expect(
      AnimalProductiveSituation.afterDryOff(
        AnimalProductiveSituation.prepartum,
        secagem,
      ),
      AnimalProductiveSituation.prepartum,
    );
    expect(
      AnimalProductiveSituation.afterDryOff(
        AnimalProductiveSituation.heifer,
        secagem,
      ),
      AnimalProductiveSituation.heifer,
    );
  });

  test('apagar a data de secagem mantém a situação escolhida', () {
    expect(
      AnimalProductiveSituation.afterDryOff(AnimalProductiveSituation.dry, null),
      AnimalProductiveSituation.dry,
    );
  });
}
