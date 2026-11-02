import 'package:flutter/material.dart';

import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/models/animal_forecast.dart';
import 'package:cysvet_app/models/animal_summary_model.dart';
import 'package:cysvet_app/models/indicador_reprodutivo_calculator.dart';
import 'package:cysvet_app/models/visit_action_hint.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';

/// Janela do bloco "Próximos dias" da tela Hoje.
const diasProximosEventos = 30;

/// Um animal e o motivo pelo qual precisa de atenção.
class TodayAction {
  const TodayAction({required this.animal, required this.hint});

  final AnimalSummaryModel animal;
  final VisitActionHint hint;
}

/// O que fazer numa fazenda, com as mesmas regras do "o que fazer hoje" da
/// visita (`visitActionHints`), calculado só com os dados do aparelho.
class TodaySummary {
  const TodaySummary({
    required this.byKind,
    required this.animalsNeedingAttention,
    required this.totalAnimals,
    required this.upcomingCalvings,
    required this.upcomingDryOffs,
    required this.upcomingPrepartum,
  });

  final Map<VisitActionKind, List<TodayAction>> byKind;

  /// Animais distintos com alguma ação (um animal pode ter mais de uma).
  final int animalsNeedingAttention;
  final int totalAnimals;
  final int upcomingCalvings;
  final int upcomingDryOffs;
  final int upcomingPrepartum;

  static TodaySummary build(
    Iterable<AnimalSummaryModel> animals,
    DateTime hoje,
  ) {
    final dia = DateUtils.dateOnly(hoje);
    final byKind = {
      for (final kind in VisitActionKind.values) kind: <TodayAction>[],
    };
    final attention = <int>{};
    var total = 0;
    var calvings = 0;
    var dryOffs = 0;
    var prepartum = 0;

    bool nosProximosDias(DateTime data) {
      final dias = DateUtils.dateOnly(data).difference(dia).inDays;
      return dias >= 0 && dias <= diasProximosEventos;
    }

    for (final animal in animals) {
      if (animal.status != AnimalStatus.active) continue;
      total++;

      final entry = IndicadorReprodutivoCalculator.applyAutomaticCalculations(
        entry: entryFromAnimal(animal),
        dataAtual: dia,
      );
      for (final hint in visitActionHints(entry, dataVisita: dia)) {
        byKind[hint.kind]!.add(TodayAction(animal: animal, hint: hint));
        attention.add(animal.id);
      }

      final forecast = AnimalForecast.of(animal, dia);
      if (forecast != null) {
        if (nosProximosDias(forecast.parto)) calvings++;
        if (!forecast.jaSeca && nosProximosDias(forecast.secagem)) dryOffs++;
        if (nosProximosDias(forecast.preParto)) prepartum++;
      }
    }

    for (final list in byKind.values) {
      // Atrasados primeiro; depois pelo brinco.
      list.sort((a, b) {
        final urgency = (b.hint.urgent ? 1 : 0) - (a.hint.urgent ? 1 : 0);
        return urgency != 0
            ? urgency
            : a.animal.codigo.compareTo(b.animal.codigo);
      });
    }

    return TodaySummary(
      byKind: byKind,
      animalsNeedingAttention: attention.length,
      totalAnimals: total,
      upcomingCalvings: calvings,
      upcomingDryOffs: dryOffs,
      upcomingPrepartum: prepartum,
    );
  }
}

/// Coleta "vazia" da visita com o que o cadastro do aparelho sabe do animal.
VisitAnimalEntryModel entryFromAnimal(AnimalSummaryModel animal) {
  return VisitAnimalEntryModel(
    animalId: animal.id,
    animalIdExterno: animal.idExterno,
    animalCodigo: animal.codigo,
    dataNascimento: animal.dataNascimento,
    situacaoReprodutiva: animal.statusReprodutivo?.apiValue,
    situacaoProdutiva: animal.situacaoProdutiva,
    dataUltimaIa: animal.dataInseminacao,
    dataUltimoParto: animal.dataUltimoParto,
  );
}
