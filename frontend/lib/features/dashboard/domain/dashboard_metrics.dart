import 'package:dart_mappable/dart_mappable.dart';

part 'dashboard_metrics.mapper.dart';

@MappableClass()
class DashboardMetrics with DashboardMetricsMappable {
  const DashboardMetrics({
    this.totalPropriedades = 0,
    this.totalAnimais = 0,
    this.totalEventos = 0,
    this.taxaPrenhez = 0.0,
    this.taxaServico = 0.0,
    this.mediaInseminacoes = 0.0,
    this.intervaloMedioPartos = 0.0,
  });

  final int totalPropriedades;
  final int totalAnimais;
  final int totalEventos;
  final double taxaPrenhez;
  final double taxaServico;
  final double mediaInseminacoes;
  final double intervaloMedioPartos;
}
