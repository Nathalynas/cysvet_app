enum ClientCompanyStatus {
  ativa('ATIVA'),
  aguardandoPrimeiroAcesso('AGUARDANDO_PRIMEIRO_ACESSO'),
  desativada('DESATIVADA');

  const ClientCompanyStatus(this.apiValue);

  final String apiValue;

  static ClientCompanyStatus fromApi(String? value) {
    return ClientCompanyStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => ClientCompanyStatus.ativa,
    );
  }
}

class ClientCompanyModel {
  const ClientCompanyModel({
    required this.id,
    required this.name,
    required this.responsibleName,
    required this.responsibleEmail,
    required this.status,
    this.createdAt,
  });

  final int id;
  final String name;
  final String responsibleName;
  final String responsibleEmail;
  final ClientCompanyStatus status;
  final DateTime? createdAt;

  bool get isActive => status != ClientCompanyStatus.desativada;

  factory ClientCompanyModel.fromMap(Map<String, dynamic> map) {
    return ClientCompanyModel(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: map['name']?.toString() ?? '',
      responsibleName: map['responsibleName']?.toString() ?? '',
      responsibleEmail: map['responsibleEmail']?.toString() ?? '',
      status: ClientCompanyStatus.fromApi(map['status']?.toString()),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? ''),
    );
  }
}
