import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/presentation/async_value_view.dart';
import '../../../../core/utils/formatters.dart';
import '../../../propriedades/application/properties_provider.dart';
import '../../../propriedades/domain/property_summary_model.dart';
import '../../application/visits_provider.dart';
import '../../domain/visit_summary_model.dart';

class VisitsPage extends ConsumerWidget {
  const VisitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visits = ref.watch(visitsProvider);
    final properties = ref.watch(propertiesProvider);
    final selectedPropertyId = ref.watch(visitsPropertyFilterProvider);
    final propertyOptions =
        properties.asData?.value ?? const <PropertySummaryModel>[];
    final propertyById = {
      for (final property in propertyOptions) property.id: property,
    };

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(visitsProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _VisitsFilterCard(
                properties: propertyOptions,
                selectedPropertyId: selectedPropertyId,
                onChanged: (value) {
                  ref.read(visitsPropertyFilterProvider.notifier).set(value);
                },
              ),
              const SizedBox(height: 16),
              AsyncValueView<List<VisitSummaryModel>>(
                value: visits,
                loadingMessage: 'Buscando visitas...',
                emptyMessage: 'Nenhuma visita encontrada para o filtro atual.',
                isEmpty: (items) => items.isEmpty,
                onRetry: () => ref.invalidate(visitsProvider),
                builder: (items) => Column(
                  children: [
                    for (final visit in items) ...[
                      _VisitCard(
                        visit: visit,
                        propertyName:
                            propertyById[visit.idPropriedade]?.nome ??
                            visit.idExternoPropriedade,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisitsFilterCard extends StatelessWidget {
  const _VisitsFilterCard({
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
        child: DropdownButtonFormField<int?>(
          initialValue: selectedPropertyId,
          decoration: const InputDecoration(
            labelText: 'Filtrar por propriedade',
          ),
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
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit, required this.propertyName});

  final VisitSummaryModel visit;
  final String propertyName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    formatDate(visit.dataVisita),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Propriedade: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor,
                    ),
                  ),
                  TextSpan(
                    text: propertyName,
                    style: const TextStyle(color: AppTheme.bodyTextColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'ID externo: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor,
                    ),
                  ),
                  TextSpan(
                    text: visit.idExterno,
                    style: const TextStyle(color: AppTheme.bodyTextColor),
                  ),
                ],
              ),
            ),
            if (visit.observacoes != null && visit.observacoes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                visit.observacoes!,
                style: const TextStyle(color: AppTheme.bodyTextColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
