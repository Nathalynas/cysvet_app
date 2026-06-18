import 'package:dart_mappable/dart_mappable.dart';

import '../../../core/enums/animal_status.dart';

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
    this.sexo,
    this.dataNascimento,
    this.numeroLactacao = 0,
    this.dataUltimoParto,
    this.dataInseminacao,
    this.diasEmLactacao,
    this.historicoReprodutivo,
    this.statusReprodutivo,
    this.status = AnimalStatus.active,
  });

  final int id;
  final String idExterno;
  final int idPropriedade;
  final String idExternoPropriedade;
  final String codigo;
  final String categoria;
  final String? sexo;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataNascimento;
  final int numeroLactacao;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataUltimoParto;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataInseminacao;
  final int? diasEmLactacao;
  final String? historicoReprodutivo;
  @MappableField(hook: _AnimalReproductiveStatusHook())
  final AnimalReproductiveStatus? statusReprodutivo;
  @MappableField(hook: _AnimalStatusHook())
  final AnimalStatus status;
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

class _AnimalStatusHook extends MappingHook {
  const _AnimalStatusHook();

  @override
  Object? beforeDecode(Object? value) {
    return AnimalStatus.fromApi(value?.toString());
  }

  @override
  Object? beforeEncode(Object? value) {
    return value is AnimalStatus ? value.apiValue : value;
  }
}

class _AnimalReproductiveStatusHook extends MappingHook {
  const _AnimalReproductiveStatusHook();

  @override
  Object? beforeDecode(Object? value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return AnimalReproductiveStatus.fromApiValue(raw);
  }

  @override
  Object? beforeEncode(Object? value) {
    return value is AnimalReproductiveStatus ? value.apiValue : value;
  }
}
