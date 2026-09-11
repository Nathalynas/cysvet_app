class IbgeMunicipioModel {
  const IbgeMunicipioModel({required this.nome, required this.codigoIbge});

  factory IbgeMunicipioModel.fromMap(Map<String, dynamic> map) {
    return IbgeMunicipioModel(
      nome: map['nome']?.toString() ?? '',
      codigoIbge: map['codigo_ibge']?.toString() ?? '',
    );
  }

  final String nome;
  final String codigoIbge;

  bool matches(String? value) {
    return value != null &&
        value.trim().toUpperCase() == nome.trim().toUpperCase();
  }
}
