import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';

/// Tipos de perda gestacional aceitos pelo servidor, com o rótulo da tela.
const gestationalLossTypes = <String, String>{
  'reabsorcao': 'Reabsorção',
  'aborto': 'Aborto',
  'mumificacao': 'Mumificação',
  'natimorto': 'Natimorto',
};

/// Até este dia de gestação a perda é reabsorção embrionária; depois, aborto.
const diasLimiteReabsorcao = 45;

/// Métodos de DG: o servidor só registra o DG a partir de 28 dias da IA por
/// ultrassom e 45 por palpação.
const metodosDiagnostico = <String, String>{
  'ultrassom': 'Ultrassom',
  'palpacao': 'Palpação',
};

/// Tipo sugerido pela idade da gestação perdida.
String suggestedLossType(int? diasGestacao) {
  return diasGestacao != null && diasGestacao < diasLimiteReabsorcao
      ? 'reabsorcao'
      : 'aborto';
}

/// Troca a situação reprodutiva. Prenha que passa a vazia na visita sugere
/// perda gestacional (o veterinário pode trocar o tipo ou dizer que não houve);
/// sair de "vazia" desfaz a perda.
VisitAnimalEntryModel withReproductiveStatus(
  VisitAnimalEntryModel entry,
  String? value,
) {
  final before = AnimalReproductiveStatus.fromApiValue(entry.situacaoReprodutiva);
  final after = AnimalReproductiveStatus.fromApiValue(value);
  if (after != AnimalReproductiveStatus.empty) {
    return entry.copyWith(
      situacaoReprodutiva: value,
      tipoPerda: null,
      causaPerda: null,
    );
  }
  if (before == AnimalReproductiveStatus.pregnant) {
    return entry.copyWith(
      situacaoReprodutiva: value,
      tipoPerda: suggestedLossType(entry.diasPrenhez),
    );
  }
  return entry.copyWith(situacaoReprodutiva: value);
}
