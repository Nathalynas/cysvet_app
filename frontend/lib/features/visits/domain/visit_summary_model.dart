import 'package:dart_mappable/dart_mappable.dart';

part 'visit_summary_model.mapper.dart';

@MappableClass()
class VisitSummaryModel with VisitSummaryModelMappable {
  const VisitSummaryModel({
    this.id = 0,
    this.idExterno = '',
    this.idPropriedade = 0,
    this.idExternoPropriedade = '',
    this.dataVisita,
    this.observacoes,
    this.animais = const [],
  });

  final int id;
  final String idExterno;
  final int idPropriedade;
  final String idExternoPropriedade;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataVisita;
  final String? observacoes;
  final List<VisitAnimalEntryModel> animais;
}

@MappableClass()
class VisitAnimalEntryModel with VisitAnimalEntryModelMappable {
  const VisitAnimalEntryModel({
    this.animalId = 0,
    this.animalIdExterno = '',
    this.animalCodigo = '',
    this.animalCategoria = '',
    this.idadeMeses,
    this.situacaoProdutiva,
    this.situacaoReprodutiva,
    this.decisao,
    this.dataUltimaIa,
    this.numeroIaRecebida,
    this.diasPrenhez,
    this.diagnostico,
    this.del,
    this.diasParaSecar,
    this.previsaoSecagem,
    this.dataPreParto,
    this.previsaoParto,
  });

  final int animalId;
  final String animalIdExterno;
  final String animalCodigo;
  final String animalCategoria;
  final int? idadeMeses;
  final String? situacaoProdutiva;
  final String? situacaoReprodutiva;
  final String? decisao;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataUltimaIa;
  final int? numeroIaRecebida;
  final int? diasPrenhez;
  final String? diagnostico;
  final int? del;
  final int? diasParaSecar;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? previsaoSecagem;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataPreParto;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? previsaoParto;

  bool get hasCollectedData {
    return (situacaoProdutiva?.trim().isNotEmpty == true) ||
        (situacaoReprodutiva?.trim().isNotEmpty == true) ||
        (decisao?.trim().isNotEmpty == true) ||
        dataUltimaIa != null ||
        numeroIaRecebida != null ||
        diasPrenhez != null ||
        (diagnostico?.trim().isNotEmpty == true) ||
        del != null ||
        diasParaSecar != null ||
        previsaoSecagem != null ||
        dataPreParto != null ||
        previsaoParto != null;
  }
}

class _NullableDateTimeHook extends MappingHook {
  const _NullableDateTimeHook();

  @override
  Object? beforeDecode(Object? value) {
    if (value is String) {
      if (value.isEmpty) {
        return null;
      }

      return DateTime.tryParse(value);
    }

    return value;
  }
}
