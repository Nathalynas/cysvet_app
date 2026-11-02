import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/models/animal_forecast.dart';
import 'package:cysvet_app/models/animal_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final hoje = DateTime(2025, 9, 1);

  test('prenha com IA: prazos 220/252/282 do caso do PDF real', () {
    final forecast = AnimalForecast.of(
      AnimalSummaryModel(
        statusReprodutivo: AnimalReproductiveStatus.pregnant,
        dataInseminacao: DateTime(2025, 5, 10),
        situacaoProdutiva: AnimalProductiveSituation.lactating,
      ),
      hoje,
    )!;
    expect(forecast.diasGestacao, 114);
    expect(forecast.secagem, DateTime(2025, 12, 16));
    expect(forecast.preParto, DateTime(2026, 1, 17));
    expect(forecast.parto, DateTime(2026, 2, 16));
    expect(forecast.jaSeca, isFalse);
  });

  test('sem prenhez ou sem IA não há previsão', () {
    expect(
      AnimalForecast.of(
        AnimalSummaryModel(
          statusReprodutivo: AnimalReproductiveStatus.empty,
          dataInseminacao: DateTime(2025, 5, 10),
        ),
        hoje,
      ),
      isNull,
    );
    expect(
      AnimalForecast.of(
        const AnimalSummaryModel(
          statusReprodutivo: AnimalReproductiveStatus.pregnant,
        ),
        hoje,
      ),
      isNull,
    );
  });

  test('vaca seca não tem secagem pendente', () {
    final forecast = AnimalForecast.of(
      AnimalSummaryModel(
        statusReprodutivo: AnimalReproductiveStatus.pregnant,
        dataInseminacao: DateTime(2025, 1, 10),
        situacaoProdutiva: AnimalProductiveSituation.dry,
      ),
      hoje,
    )!;
    expect(forecast.jaSeca, isTrue);
  });
}
