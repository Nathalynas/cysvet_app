enum PropertyStatus {
  active('ATIVO', 'Ativo'),
  inactive('INATIVO', 'Inativo');

  const PropertyStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PropertyStatus fromApi(String? value) {
    return PropertyStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => PropertyStatus.active,
    );
  }
}

enum PropertyStatusFilter {
  all('Todos'),
  active('Ativos'),
  inactive('Arquivados/Inativos');

  const PropertyStatusFilter(this.label);

  final String label;
}
