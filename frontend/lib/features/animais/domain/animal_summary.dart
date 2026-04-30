class AnimalSummary {
  const AnimalSummary({
    required this.id,
    required this.idExterno,
    required this.idPropriedade,
    required this.idExternoPropriedade,
    required this.codigo,
    required this.categoria,
    required this.dataNascimento,
    required this.numeroLactacao,
    required this.dataUltimoParto,
    required this.diasEmLactacao,
    required this.historicoReprodutivo,
  });

  final int id;
  final String idExterno;
  final int idPropriedade;
  final String idExternoPropriedade;
  final String codigo;
  final String categoria;
  final DateTime? dataNascimento;
  final int numeroLactacao;
  final DateTime? dataUltimoParto;
  final int? diasEmLactacao;
  final String? historicoReprodutivo;

  factory AnimalSummary.fromJson(Map<String, dynamic> json) {
    return AnimalSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      idExterno: json['idExterno'] as String? ?? '',
      idPropriedade: (json['idPropriedade'] as num?)?.toInt() ?? 0,
      idExternoPropriedade: json['idExternoPropriedade'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
      categoria: json['categoria'] as String? ?? '',
      dataNascimento: _parseDate(json['dataNascimento'] as String?),
      numeroLactacao: (json['numeroLactacao'] as num?)?.toInt() ?? 0,
      dataUltimoParto: _parseDate(json['dataUltimoParto'] as String?),
      diasEmLactacao: (json['diasEmLactacao'] as num?)?.toInt(),
      historicoReprodutivo: json['historicoReprodutivo'] as String?,
    );
  }
}

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}
