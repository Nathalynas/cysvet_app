enum UserStatus {
  active('ATIVO', 'Ativo'),
  inactive('INATIVO', 'Inativo');

  const UserStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static UserStatus fromApi(String? value) {
    return UserStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => UserStatus.active,
    );
  }
}

enum UserStatusFilter {
  all('Todos'),
  active('Ativos'),
  inactive('Arquivados/Inativos');

  const UserStatusFilter(this.label);

  final String label;
}