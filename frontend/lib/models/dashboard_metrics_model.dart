import 'package:dart_mappable/dart_mappable.dart';

part 'dashboard_metrics_model.mapper.dart';

/// Indicadores calculados no servidor (ciclos de 21 dias). O app só exibe.
@MappableClass()
class DashboardMetricsModel with DashboardMetricsModelMappable {
  const DashboardMetricsModel({
    this.totalPropriedades = 0,
    this.totalAnimais = 0,
    this.totalEventos = 0,
    this.taxaPrenhez = 0.0,
    this.taxaServico = 0.0,
    this.mediaInseminacoes = 0.0,
    this.intervaloMedioPartos = 0.0,
    this.taxaConcepcao,
    this.taxaConcepcaoIa,
    this.ciclos = 0,
    this.aptas = 0,
    this.servidas = 0,
    this.concebidas = 0,
    this.serieMensal = const [],
    this.perdasGestacionais = 0,
    this.taxaPerdaGestacional,
  });

  final int totalPropriedades;
  final int totalAnimais;
  final int totalEventos;

  /// Concebidas / aptas por ciclo de 21 dias.
  final double taxaPrenhez;

  /// Servidas / aptas por ciclo de 21 dias.
  final double taxaServico;
  final double mediaInseminacoes;
  final double intervaloMedioPartos;

  /// Concebidas / servidas por ciclo de 21 dias (nulo sem dados).
  final double? taxaConcepcao;

  /// IAs seguidas de prenhez / IAs do período (nulo sem IAs).
  final double? taxaConcepcaoIa;
  final int ciclos;
  final int aptas;
  final int servidas;
  final int concebidas;
  final List<DashboardMonthlyRateModel> serieMensal;

  /// Perdas gestacionais do período e perdas / prenhezes (nulo sem prenhez).
  final int perdasGestacionais;
  final double? taxaPerdaGestacional;
}

@MappableClass()
class DashboardMonthlyRateModel with DashboardMonthlyRateModelMappable {
  const DashboardMonthlyRateModel({
    this.mes = '',
    this.taxaServico,
    this.taxaConcepcao,
    this.taxaPrenhez,
  });

  /// `AAAA-MM`.
  final String mes;
  final double? taxaServico;
  final double? taxaConcepcao;
  final double? taxaPrenhez;
}
