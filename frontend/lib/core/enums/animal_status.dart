import 'package:flutter/material.dart';

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

enum AnimalReproductiveStatus {
  pregnant('pregnant', 'Prenha'),
  empty('empty', 'Vazia'),
  inseminated('inseminated', 'Inseminada'),
  dry('dry', 'Seca'),
  pending('pending', 'Pendente');

  const AnimalReproductiveStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static AnimalReproductiveStatus fromApiValue(String? value) {
    return AnimalReproductiveStatus.values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => AnimalReproductiveStatus.pending,
    );
  }
}

extension AnimalReproductiveStatusIcon on AnimalReproductiveStatus {
  IconData get icon {
    return switch (this) {
      AnimalReproductiveStatus.pregnant => Icons.check_circle_outline,
      AnimalReproductiveStatus.empty => Icons.radio_button_unchecked,
      AnimalReproductiveStatus.inseminated => Icons.science_outlined,
      AnimalReproductiveStatus.dry => Icons.water_drop_outlined,
      AnimalReproductiveStatus.pending => Icons.schedule_outlined,
    };
  }
}