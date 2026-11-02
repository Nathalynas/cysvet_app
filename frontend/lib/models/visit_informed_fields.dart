import 'package:cysvet_app/models/visit_summary_model.dart';

/// Campos da coleta que podem virar evento no servidor. Os nomes são os do
/// `VisitaAnimalItemDto`.
const informableVisitFields = <String>[
  'situacaoReprodutiva',
  'situacaoProdutiva',
  'dataUltimaIa',
  'dataUltimoParto',
  'dataSecagemEfetiva',
  'entradaPreParto',
  'diagnostico',
  'decisao',
  'controleLeiteiro',
  'numeroIaRecebida',
];

Object? _fieldValue(VisitAnimalEntryModel entry, String field) {
  return switch (field) {
    'situacaoReprodutiva' => entry.situacaoReprodutiva,
    'situacaoProdutiva' => entry.situacaoProdutiva,
    'dataUltimaIa' => entry.dataUltimaIa,
    'dataUltimoParto' => entry.dataUltimoParto,
    'dataSecagemEfetiva' => entry.dataSecagemEfetiva,
    'entradaPreParto' => entry.entradaPreParto,
    'diagnostico' => entry.diagnostico,
    'decisao' => entry.decisao,
    'controleLeiteiro' => entry.controleLeiteiro,
    'numeroIaRecebida' => entry.numeroIaRecebida,
    _ => null,
  };
}

/// Junta em [updated] os campos que mudaram desde [previous] aos que já
/// estavam marcados. Lista nula (visita de versão antiga) continua nula: o
/// servidor trata como "todos informados", como antes.
VisitAnimalEntryModel withInformedChanges(
  VisitAnimalEntryModel previous,
  VisitAnimalEntryModel updated,
) {
  if (previous.camposInformados == null) {
    return updated.copyWith(camposInformados: null);
  }
  final campos = <String>{
    ...previous.camposInformados!,
    ...?updated.camposInformados,
    for (final field in informableVisitFields)
      if (_fieldValue(previous, field) != _fieldValue(updated, field)) field,
  };
  return updated.copyWith(camposInformados: _ordered(campos));
}

/// "Confirmar animal" sem mudar nada: a situação vista vale como observada.
VisitAnimalEntryModel withConfirmedSituation(VisitAnimalEntryModel entry) {
  final atual = entry.camposInformados;
  if (atual == null) return entry;
  return entry.copyWith(
    camposInformados: _ordered({
      ...atual,
      'situacaoReprodutiva',
      'situacaoProdutiva',
    }),
  );
}

List<String> _ordered(Set<String> campos) => [
  for (final field in informableVisitFields)
    if (campos.contains(field)) field,
];
