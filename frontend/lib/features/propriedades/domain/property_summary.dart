class PropertySummary {
  const PropertySummary({
    required this.id,
    required this.idExterno,
    required this.nome,
    required this.nomeProprietario,
    required this.cidade,
    required this.estado,
    required this.observacoes,
  });

  final int id;
  final String idExterno;
  final String nome;
  final String nomeProprietario;
  final String? cidade;
  final String? estado;
  final String? observacoes;

  factory PropertySummary.fromJson(Map<String, dynamic> json) {
    return PropertySummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      idExterno: json['idExterno'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      nomeProprietario: json['nomeProprietario'] as String? ?? '',
      cidade: json['cidade'] as String?,
      estado: json['estado'] as String?,
      observacoes: json['observacoes'] as String?,
    );
  }

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
