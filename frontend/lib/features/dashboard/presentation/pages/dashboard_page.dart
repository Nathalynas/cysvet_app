import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/presentation/async_value_view.dart';
import '../../../../core/utils/formatters.dart';
import '../../../propriedades/application/properties_provider.dart';
import '../../../propriedades/domain/property_summary_model.dart';
import '../../application/dashboard_provider.dart';
import '../../domain/dashboard_metrics_model.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final properties = ref.watch(propertiesProvider);
    final selectedPropertyId = ref.watch(dashboardPropertyFilterProvider);
    final propertyOptions =
        properties.asData?.value ?? const <PropertySummaryModel>[];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _PropertyFilterCard(
                properties: propertyOptions,
                selectedPropertyId: selectedPropertyId,
                onChanged: (value) {
                  ref.read(dashboardPropertyFilterProvider.notifier).set(value);
                },
              ),
              const SizedBox(height: 16),
              AsyncValueView<DashboardMetricsModel>(
                value: dashboard,
                loadingMessage: 'Buscando indicadores do backend...',
                onRetry: () => ref.invalidate(dashboardProvider),
                builder: (data) => _DashboardContent(metrics: data),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyFilterCard extends StatelessWidget {
  const _PropertyFilterCard({
    required this.properties,
    required this.selectedPropertyId,
    required this.onChanged,
  });

  final List<PropertySummaryModel> properties;
  final int? selectedPropertyId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtro do dashboard',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: selectedPropertyId,
              decoration: const InputDecoration(labelText: 'Propriedade'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Todas as propriedades'),
                ),
                ...properties.map(
                  (property) => DropdownMenuItem<int?>(
                    value: property.id,
                    child: Text(property.nome),
                  ),
                ),
              ],
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.metrics});

  final DashboardMetricsModel metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final cardWidth = isWide
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _MetricCard(
                  width: cardWidth,
                  title: 'Propriedades',
                  value: metrics.totalPropriedades.toString(),
                  subtitle: 'Cadastradas para o usuario autenticado',
                  icon: Icons.agriculture,
                ),
                _MetricCard(
                  width: cardWidth,
                  title: 'Animais',
                  value: metrics.totalAnimais.toString(),
                  subtitle: 'Animais considerados no recorte atual',
                  icon: Icons.pets,
                ),
                _MetricCard(
                  width: cardWidth,
                  title: 'Eventos',
                  value: metrics.totalEventos.toString(),
                  subtitle: 'Eventos reprodutivos carregados',
                  icon: Icons.event_note,
                ),
                _MetricCard(
                  width: cardWidth,
                  title: 'Taxa de prenhez',
                  value: formatPercent(metrics.taxaPrenhez),
                  subtitle: 'Confirmacoes positivas por inseminacao',
                  icon: Icons.monitor_heart_outlined,
                ),
                _MetricCard(
                  width: cardWidth,
                  title: 'Taxa de servico',
                  value: formatPercent(metrics.taxaServico),
                  subtitle: 'Animais inseminados sobre total de animais',
                  icon: Icons.show_chart,
                ),
                _MetricCard(
                  width: cardWidth,
                  title: 'Media de inseminacoes',
                  value: formatDecimal(metrics.mediaInseminacoes),
                  subtitle: 'Inseminacoes por animal inseminado',
                  icon: Icons.science_outlined,
                ),
                _MetricCard(
                  width: cardWidth,
                  title: 'Intervalo medio entre partos',
                  value: '${formatDecimal(metrics.intervaloMedioPartos)} dias',
                  subtitle: 'Calculado a partir dos eventos de parto',
                  icon: Icons.schedule,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final double width;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: AppTheme.mutedTextColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
