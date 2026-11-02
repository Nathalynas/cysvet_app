import 'package:cysvet_app/models/dashboard_metrics_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lê as taxas e a série mensal no formato do backend', () {
    final metrics = DashboardMetricsModelMapper.fromMap({
      'totalPropriedades': 1,
      'totalAnimais': 10,
      'totalEventos': 30,
      'taxaPrenhez': 0.2857,
      'taxaServico': 0.4286,
      'mediaInseminacoes': 1.5,
      'intervaloMedioPartos': 400.0,
      'taxaConcepcao': 0.6667,
      'taxaConcepcaoIa': null,
      'ciclos': 3,
      'aptas': 7,
      'servidas': 3,
      'concebidas': 2,
      'periodoInicio': '2026-01-01',
      'periodoFim': '2026-03-04',
      'serieMensal': [
        {'mes': '2026-02', 'taxaServico': 0.5, 'taxaConcepcao': null, 'taxaPrenhez': null},
      ],
    });

    expect(metrics.taxaConcepcao, closeTo(0.6667, 1e-9));
    expect(metrics.taxaConcepcaoIa, isNull);
    expect(metrics.aptas, 7);
    expect(metrics.serieMensal.single.mes, '2026-02');
    expect(metrics.serieMensal.single.taxaConcepcao, isNull);
  });
}
