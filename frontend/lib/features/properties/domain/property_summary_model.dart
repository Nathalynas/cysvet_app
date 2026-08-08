import 'package:dart_mappable/dart_mappable.dart';

import '../../../core/enums/property_status.dart';

part 'property_summary_model.mapper.dart';

@MappableClass()
class PropertySummaryModel with PropertySummaryModelMappable {
  const PropertySummaryModel({
    this.id = 0,
    this.idExterno = '',
    this.nome = '',
    this.nomeProprietario = '',
    this.contato,
    this.cidade,
    this.estado,
    this.observacoes,
    this.status = PropertyStatus.active,
  });

  final int id;
  final String idExterno;
  final String nome;
  final String nomeProprietario;
  final String? contato;
  final String? cidade;
  final String? estado;
  final String? observacoes;
  @MappableField(hook: _PropertyStatusHook())
  final PropertyStatus status;

  String get localizacao {
    final parts = [
      if (cidade != null && cidade!.isNotEmpty) cidade!,
      if (estado != null && estado!.isNotEmpty) estado!,
    ];

    if (parts.isEmpty) {
      return 'Localizacao nao informada';
    }

    return parts.join(' - ');
  }
}

class _PropertyStatusHook extends MappingHook {
  const _PropertyStatusHook();

  @override
  Object? beforeDecode(Object? value) {
    return PropertyStatus.fromApi(value?.toString());
  }

  @override
  Object? beforeEncode(Object? value) {
    return value is PropertyStatus ? value.apiValue : value;
  }
}
