import 'package:dart_mappable/dart_mappable.dart';

part 'property_summary_model.mapper.dart';

@MappableClass()
class PropertySummaryModel with PropertySummaryModelMappable {
  const PropertySummaryModel({
    this.id = 0,
    this.idExterno = '',
    this.nome = '',
    this.nomeProprietario = '',
    this.cidade,
    this.estado,
    this.observacoes,
  });

  final int id;
  final String idExterno;
  final String nome;
  final String nomeProprietario;
  final String? cidade;
  final String? estado;
  final String? observacoes;

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
