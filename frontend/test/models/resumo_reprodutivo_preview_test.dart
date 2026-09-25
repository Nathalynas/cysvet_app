import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/models/animal_summary_model.dart';
import 'package:cysvet_app/models/resumo_reprodutivo_preview.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final animal = AnimalSummaryModel(
    id: 1,
    idExterno: 'animal-1',
    codigo: 'A-01',
    numeroLactacao: 1,
    dataUltimoParto: DateTime(2025, 1, 10),
    dataInseminacao: DateTime(2024, 4, 5),
    statusReprodutivo: AnimalReproductiveStatus.pregnant,
  );

  test('nova IA informada na visita atualiza IA e situação', () {
    final preview = previewAnimalAfterVisit(
      animal,
      VisitAnimalEntryModel(
        animalId: 1,
        dataUltimaIa: DateTime(2025, 3, 1),
        situacaoReprodutiva: 'inseminada st',
      ),
    );

    expect(preview.dataInseminacao, DateTime(2025, 3, 1));
    expect(preview.statusReprodutivo, AnimalReproductiveStatus.inseminatedSt);
    expect(preview.numeroLactacao, 1);
  });

  test('parto novo soma lactação e descarta IA da lactação anterior', () {
    final preview = previewAnimalAfterVisit(
      animal.copyWith(dataInseminacao: DateTime(2025, 4, 1)),
      VisitAnimalEntryModel(animalId: 1, dataUltimoParto: DateTime(2026, 1, 5)),
    );

    expect(preview.numeroLactacao, 2);
    expect(preview.dataUltimoParto, DateTime(2026, 1, 5));
    expect(preview.dataInseminacao, isNull);
    expect(preview.statusReprodutivo, AnimalReproductiveStatus.pending);
  });

  test('parto já conhecido não soma lactação de novo', () {
    final preview = previewAnimalAfterVisit(
      animal,
      VisitAnimalEntryModel(
        animalId: 1,
        dataUltimoParto: DateTime(2025, 1, 10),
      ),
    );

    expect(preview.numeroLactacao, 1);
    expect(preview.statusReprodutivo, AnimalReproductiveStatus.pregnant);
  });

  test('situação fora da lista mantém a situação atual', () {
    final preview = previewAnimalAfterVisit(
      animal,
      VisitAnimalEntryModel(
        animalId: 1,
        situacaoReprodutiva: 'abortou 52 dias',
      ),
    );

    expect(preview.statusReprodutivo, AnimalReproductiveStatus.pregnant);
  });
}
