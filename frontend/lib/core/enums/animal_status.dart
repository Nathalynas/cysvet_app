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
  protocol('em protocolo', 'Em protocolo'),
  empty('vazia', 'Vazia', aliases: ['empty']),
  released('liberada', 'Liberada'),
  delayed('atrasada', 'Atrasada'),
  waitingDiagnosis('aguardando dg', 'Aguardando DG'),
  inseminatedSt('inseminada st', 'Inseminada ST'),
  pregnant('prenha', 'Prenha', aliases: ['pregnant']),
  induction('inducao', 'Indução', aliases: ['indução']),
  discard('descarte', 'Descarte'),
  pev('pev', 'PEV'),
  noAge('sem idade', 'Sem idade'),
  calf('novilha', 'Novilha', aliases: ['bezerra']),
  inseminated('inseminada', 'Inseminada', aliases: ['inseminated']),
  dry('dry', 'Seca', aliases: ['seca']),
  pending('pending', 'Pendente');

  const AnimalReproductiveStatus(
    this.apiValue,
    this.label, {
    this.aliases = const [],
  });

  final String apiValue;
  final String label;
  final List<String> aliases;

  static const spreadsheetValues = [
    protocol,
    empty,
    released,
    delayed,
    waitingDiagnosis,
    inseminatedSt,
    pregnant,
    induction,
    discard,
    pev,
    noAge,
    calf,
  ];

  static const editableValues = [
    ...spreadsheetValues,
    inseminated,
    dry,
    pending,
  ];

  static AnimalReproductiveStatus fromApiValue(String? value) {
    final normalized = value?.trim().toLowerCase();
    return AnimalReproductiveStatus.values.firstWhere((item) {
      return item.apiValue == normalized ||
          item.aliases.any((alias) => alias.toLowerCase() == normalized);
    }, orElse: () => AnimalReproductiveStatus.pending);
  }
}

extension AnimalReproductiveStatusIcon on AnimalReproductiveStatus {
  IconData get icon {
    return switch (this) {
      AnimalReproductiveStatus.pregnant => Icons.check_circle_outline,
      AnimalReproductiveStatus.empty => Icons.radio_button_unchecked,
      AnimalReproductiveStatus.inseminated ||
      AnimalReproductiveStatus.inseminatedSt ||
      AnimalReproductiveStatus.protocol ||
      AnimalReproductiveStatus.waitingDiagnosis => Icons.science_outlined,
      AnimalReproductiveStatus.dry => Icons.water_drop_outlined,
      AnimalReproductiveStatus.released => Icons.check_circle_outline,
      AnimalReproductiveStatus.delayed => Icons.event_busy_outlined,
      AnimalReproductiveStatus.induction => Icons.medical_services_outlined,
      AnimalReproductiveStatus.discard => Icons.block_outlined,
      AnimalReproductiveStatus.pev => Icons.hourglass_empty_outlined,
      AnimalReproductiveStatus.noAge ||
      AnimalReproductiveStatus.calf ||
      AnimalReproductiveStatus.pending => Icons.schedule_outlined,
    };
  }
}

class AnimalProductiveSituation {
  const AnimalProductiveSituation._();

  static const lactating = 'lactante';
  static const dry = 'seca';
  static const heifer = 'novilha';
  static const prepartum = 'pre parto';
  static const values = [lactating, dry, heifer, prepartum];

  static String label(String value) {
    return switch (value) {
      lactating => 'Lactante',
      dry => 'Seca',
      heifer => 'Novilha',
      prepartum => 'Pre parto',
      _ => value,
    };
  }
}
