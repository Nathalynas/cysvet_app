class AnimalHistoryEventModel {
  const AnimalHistoryEventModel({
    required this.id,
    required this.idExterno,
    required this.idAnimal,
    required this.idExternoAnimal,
    required this.tipo,
    required this.dataEvento,
    this.dataPrevistaParto,
    this.prenhezConfirmada,
    this.observacoes,
    this.detalhes = const {},
  });

  final int id;
  final String idExterno;
  final int idAnimal;
  final String idExternoAnimal;
  final String tipo;
  final DateTime? dataEvento;
  final DateTime? dataPrevistaParto;
  final bool? prenhezConfirmada;
  final String? observacoes;
  final Map<String, dynamic> detalhes;

  factory AnimalHistoryEventModel.fromMap(Map<String, dynamic> map) {
    return AnimalHistoryEventModel(
      id: _asInt(map['id']),
      idExterno: _asString(map['idExterno']),
      idAnimal: _asInt(map['idAnimal']),
      idExternoAnimal: _asString(map['idExternoAnimal']),
      tipo: _asString(map['tipo']),
      dataEvento: _asDate(map['dataEvento']),
      dataPrevistaParto: _asDate(map['dataPrevistaParto']),
      prenhezConfirmada: _asBool(map['prenhezConfirmada']),
      observacoes: _asNullableString(map['observacoes']),
      detalhes: _asMap(map['detalhes']),
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, item) => MapEntry(key.toString(), item));
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String _asString(Object? value) {
  return value?.toString().trim() ?? '';
}

String? _asNullableString(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

bool? _asBool(Object? value) {
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return null;
}

DateTime? _asDate(Object? value) {
  if (value is DateTime) return value;
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
