import 'package:flutter/material.dart';

import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';

/// Motivo para o veterinário olhar o animal na visita ("o que fazer hoje").
class VisitActionHint {
  const VisitActionHint(this.label, {this.urgent = false});

  final String label;

  /// Atrasado (ex.: secagem passou da data); aparece antes dos demais.
  final bool urgent;
}

/// Dias depois da IA a partir dos quais o diagnóstico de gestação já pode ser
/// feito.
const diasParaDiagnostico = 30;

/// Avisos de secagem e pré-parto aparecem com esta antecedência.
const antecedenciaAviso = 15;
const antecedenciaPreParto = 30;

/// Vazia sem nova IA depois deste DEL merece atenção.
const delSemIa = 60;

/// Calcula o que precisa ser feito com o animal na data da visita. Usa os
/// campos já calculados da coleta (dias para secar, previsão de parto, DEL).
List<VisitActionHint> visitActionHints(
  VisitAnimalEntryModel entry, {
  required DateTime? dataVisita,
}) {
  if (dataVisita == null) return const [];
  final hoje = DateUtils.dateOnly(dataVisita);
  final status = AnimalReproductiveStatus.fromApiValue(
    entry.situacaoReprodutiva,
  );
  final produtiva = entry.situacaoProdutiva;
  final hints = <VisitActionHint>[];

  const aguardandoDiagnostico = {
    AnimalReproductiveStatus.inseminated,
    AnimalReproductiveStatus.inseminatedSt,
    AnimalReproductiveStatus.waitingDiagnosis,
  };
  final ultimaIa = entry.dataUltimaIa;
  if (aguardandoDiagnostico.contains(status) && ultimaIa != null) {
    final dias = hoje.difference(DateUtils.dateOnly(ultimaIa)).inDays;
    if (dias >= diasParaDiagnostico) {
      hints.add(VisitActionHint('Fazer DG · IA há $dias dias'));
    }
  }

  if (status == AnimalReproductiveStatus.pregnant) {
    final paraSecar = entry.diasParaSecar;
    final jaSeca =
        produtiva == AnimalProductiveSituation.dry ||
        produtiva == AnimalProductiveSituation.prepartum ||
        entry.dataSecagemEfetiva != null;
    if (!jaSeca && paraSecar != null && paraSecar <= antecedenciaAviso) {
      hints.add(
        paraSecar < 0
            ? VisitActionHint(
                'Secagem atrasada ${-paraSecar} dias',
                urgent: true,
              )
            : VisitActionHint(
                paraSecar == 0 ? 'Secar hoje' : 'Secar em $paraSecar dias',
              ),
      );
    }

    final parto = entry.previsaoParto;
    if (parto != null && produtiva != AnimalProductiveSituation.prepartum) {
      final dias = DateUtils.dateOnly(parto).difference(hoje).inDays;
      if (dias <= antecedenciaPreParto) {
        hints.add(
          dias < 0
              ? VisitActionHint('Parto previsto há ${-dias} dias', urgent: true)
              : VisitActionHint('Pré-parto · parto em $dias dias'),
        );
      }
    }
  }

  const semServico = {
    AnimalReproductiveStatus.empty,
    AnimalReproductiveStatus.released,
    AnimalReproductiveStatus.pending,
  };
  final del = entry.del;
  if (semServico.contains(status) &&
      produtiva != AnimalProductiveSituation.heifer &&
      del != null &&
      del >= delSemIa) {
    hints.add(VisitActionHint('Sem IA · DEL $del'));
  }

  hints.sort((a, b) => (b.urgent ? 1 : 0) - (a.urgent ? 1 : 0));
  return hints;
}
