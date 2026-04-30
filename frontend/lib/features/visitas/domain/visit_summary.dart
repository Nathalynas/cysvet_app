class VisitSummary {
  const VisitSummary({
    required this.id,
    required this.idExterno,
    required this.idPropriedade,
    required this.idExternoPropriedade,
    required this.dataVisita,
    required this.observacoes,
  });

  final int id;
  final String idExterno;
  final int idPropriedade;
  final String idExternoPropriedade;
  final DateTime? dataVisita;
  final String? observacoes;

  factory VisitSummary.fromJson(Map<String, dynamic> json) {
    return VisitSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      idExterno: json['idExterno'] as String? ?? '',
      idPropriedade: (json['idPropriedade'] as num?)?.toInt() ?? 0,
      idExternoPropriedade: json['idExternoPropriedade'] as String? ?? '',
      dataVisita: _parseDate(json['dataVisita'] as String?),
      observacoes: json['observacoes'] as String?,
    );
  }
}

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}
