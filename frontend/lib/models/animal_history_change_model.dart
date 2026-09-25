class AnimalHistoryChangeModel {
  const AnimalHistoryChangeModel({
    required this.tipo,
    required this.descricao,
    this.nomeUsuario,
    this.data,
  });

  final String tipo;
  final String descricao;
  final String? nomeUsuario;
  final DateTime? data;

  factory AnimalHistoryChangeModel.fromMap(Map<String, dynamic> map) {
    final user = map['nomeUsuario']?.toString().trim();
    final date = map['data']?.toString().trim();
    return AnimalHistoryChangeModel(
      tipo: map['tipo']?.toString().trim() ?? '',
      descricao: map['descricao']?.toString().trim() ?? '',
      nomeUsuario: user == null || user.isEmpty ? null : user,
      data: date == null || date.isEmpty ? null : DateTime.tryParse(date),
    );
  }
}
