import 'package:dart_mappable/dart_mappable.dart';

part 'animal_summary_model.mapper.dart';

@MappableClass()
class AnimalSummaryModel with AnimalSummaryModelMappable {
  const AnimalSummaryModel({
    this.id = 0,
    this.idExterno = '',
    this.idPropriedade = 0,
    this.idExternoPropriedade = '',
    this.codigo = '',
    this.categoria = '',
    this.dataNascimento,
    this.numeroLactacao = 0,
    this.dataUltimoParto,
    this.diasEmLactacao,
    this.historicoReprodutivo,
  });

  final int id;
  final String idExterno;
  final int idPropriedade;
  final String idExternoPropriedade;
  final String codigo;
  final String categoria;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataNascimento;
  final int numeroLactacao;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataUltimoParto;
  final int? diasEmLactacao;
  final String? historicoReprodutivo;
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
