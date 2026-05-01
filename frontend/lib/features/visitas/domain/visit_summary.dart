import 'package:dart_mappable/dart_mappable.dart';

part 'visit_summary.mapper.dart';

@MappableClass()
class VisitSummary with VisitSummaryMappable {
  const VisitSummary({
    this.id = 0,
    this.idExterno = '',
    this.idPropriedade = 0,
    this.idExternoPropriedade = '',
    this.dataVisita,
    this.observacoes,
  });

  final int id;
  final String idExterno;
  final int idPropriedade;
  final String idExternoPropriedade;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataVisita;
  final String? observacoes;
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
