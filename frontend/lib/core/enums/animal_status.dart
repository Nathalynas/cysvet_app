enum AnimalStatus {
  active('ATIVO', 'Ativo'),
  sold('VENDIDO', 'Vendido'),
  death('OBITO', 'Obito'),
  inactive('INATIVO', 'Inativo');

  const AnimalStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static AnimalStatus fromApi(String? value) {
    return AnimalStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => AnimalStatus.active,
    );
  }
}

enum AnimalStatusFilter {
  all('Todos'),
  active('Ativos'),
  inactive('Arquivados/Inativos');

  const AnimalStatusFilter(this.label);

  final String label;
}
