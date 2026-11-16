import 'package:flutter/material.dart';

import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/models/animal_summary_model.dart';

/// Prazos a partir da IA, os mesmos da visita e da planilha de campo.
const diasAteSecagem = 220;
const diasAtePreParto = 252;
const diasAteParto = 282;

/// Prenhe que passou deste tanto da data prevista do parto: a gestação não
/// dura isso, então o parto (ou a perda) provavelmente não foi lançado e o
/// veterinário precisa confirmar.
const toleranciaPartoAtrasado = 15;

/// Previsões de uma vaca prenhe, calculadas no aparelho (funciona offline).
class AnimalForecast {
  const AnimalForecast({
    required this.diasGestacao,
    required this.secagem,
    required this.preParto,
    required this.parto,
    required this.jaSeca,
  });

  final int diasGestacao;
  final DateTime secagem;
  final DateTime preParto;
  final DateTime parto;

  /// Já seca ou no pré-parto: a secagem não é mais pendência.
  final bool jaSeca;

  int diasAte(DateTime data, DateTime hoje) =>
      DateUtils.dateOnly(data).difference(DateUtils.dateOnly(hoje)).inDays;

  /// Passou da previsão do parto além da tolerância: confirmar se pariu.
  bool partoAtrasado(DateTime hoje) =>
      -diasAte(parto, hoje) > toleranciaPartoAtrasado;

  /// Nulo quando o animal não está prenhe ou não tem data da IA.
  static AnimalForecast? of(AnimalSummaryModel animal, DateTime hoje) {
    final ia = animal.dataInseminacao;
    if (animal.statusReprodutivo != AnimalReproductiveStatus.pregnant ||
        ia == null) {
      return null;
    }
    final inicio = DateUtils.dateOnly(ia);
    final dias = DateUtils.dateOnly(hoje).difference(inicio).inDays;
    if (dias < 0) return null;
    final produtiva = animal.situacaoProdutiva;
    return AnimalForecast(
      diasGestacao: dias,
      secagem: inicio.add(const Duration(days: diasAteSecagem)),
      preParto: inicio.add(const Duration(days: diasAtePreParto)),
      parto: inicio.add(const Duration(days: diasAteParto)),
      jaSeca:
          produtiva == AnimalProductiveSituation.dry ||
          produtiva == AnimalProductiveSituation.prepartum,
    );
  }
}
