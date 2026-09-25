class IbgeUfModel {
  const IbgeUfModel({
    required this.id,
    required this.sigla,
    required this.nome,
    this.capital,
  });

  factory IbgeUfModel.fromMap(Map<String, dynamic> map) {
    return IbgeUfModel(
      id: _intFrom(map['id']),
      sigla: map['sigla']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      capital: map['capital']?.toString(),
    );
  }

  final int id;
  final String sigla;
  final String nome;
  final String? capital;

  String get label => '$nome ($sigla)';

  bool matches(String? value) {
    if (value == null) return false;
    final normalizedValue = value.trim().toUpperCase();

    return normalizedValue == sigla.trim().toUpperCase() ||
        normalizedValue == nome.trim().toUpperCase();
  }

  static int _intFrom(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
