class DashboardMetrics {
  const DashboardMetrics({
    required this.totalPropriedades,
    required this.totalAnimais,
    required this.totalEventos,
    required this.taxaPrenhez,
    required this.taxaServico,
    required this.mediaInseminacoes,
    required this.intervaloMedioPartos,
  });

  final int totalPropriedades;
  final int totalAnimais;
  final int totalEventos;
  final double taxaPrenhez;
  final double taxaServico;
  final double mediaInseminacoes;
  final double intervaloMedioPartos;

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      totalPropriedades: (json['totalPropriedades'] as num?)?.toInt() ?? 0,
      totalAnimais: (json['totalAnimais'] as num?)?.toInt() ?? 0,
      totalEventos: (json['totalEventos'] as num?)?.toInt() ?? 0,
      taxaPrenhez: (json['taxaPrenhez'] as num?)?.toDouble() ?? 0,
      taxaServico: (json['taxaServico'] as num?)?.toDouble() ?? 0,
      mediaInseminacoes: (json['mediaInseminacoes'] as num?)?.toDouble() ?? 0,
      intervaloMedioPartos:
          (json['intervaloMedioPartos'] as num?)?.toDouble() ?? 0,
    );
  }
}
