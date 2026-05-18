import 'package:cysvet_app/core/widgets/property_filter_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/async_value_view.dart';
import '../../../../core/presentation/app_scaffold_messenger.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../properties/application/properties_provider.dart';
import '../../../properties/domain/property_summary_model.dart';
import '../../application/visits_provider.dart';
import '../../domain/visit_summary_model.dart';
import '../widgets/visit_detail_dialog.dart';

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
    final theme = Theme.of(context);

    ref.listen<VisitSummaryModel?>(savedVisitProvider, (previous, next) {
      if (next == null) return;

      final currentFilter = ref.read(visitsPropertyFilterProvider);
      if (currentFilter != null && currentFilter != next.idPropriedade) {
        ref.read(visitsPropertyFilterProvider.notifier).set(next.idPropriedade);
        return;
      }

      ref.invalidate(visitsProvider);
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(visitsProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _VisitsToolbar(
                properties: propertyOptions,
                selectedPropertyId: selectedPropertyId,
                onPropertyChanged: (value) {
                  ref.read(visitsPropertyFilterProvider.notifier).set(value);
                },
                onCreate: () {
                  if (propertyOptions.isEmpty) {
                    showAppWarning(
                      'Carregue ou cadastre uma propriedade antes da visita.',
                    );
                    return;
                  }

                  final query = selectedPropertyId == null
                      ? ''
                      : '?propriedade=$selectedPropertyId';
                  context.go('/visitas/nova$query');
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
                        onTap: () => VisitDetailDialog.show(
                          context,
                          visit: visit,
                          propertyName:
                              propertyById[visit.idPropriedade]?.nome ??
                              visit.idExternoPropriedade,
                          property: propertyById[visit.idPropriedade],
                        ),
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

class _VisitsToolbar extends StatelessWidget {
  const _VisitsToolbar({
    required this.properties,
    required this.selectedPropertyId,
    required this.onPropertyChanged,
    required this.onCreate,
  });

  final List<PropertySummaryModel> properties;
  final int? selectedPropertyId;
  final ValueChanged<int?> onPropertyChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 640;
        final propertyFilter = PropertyFilterCard(
          properties: properties,
          selectedPropertyId: selectedPropertyId,
          onChanged: onPropertyChanged,
        );
        final createButton = AppButton(
          text: 'Nova visita',
          icon: const Icon(Icons.add),
          onPressed: onCreate,
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              propertyFilter,
              const SizedBox(height: 10),
              createButton,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: propertyFilter),
            const SizedBox(width: 12),
            createButton,
          ],
        );
      },
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.visit,
    required this.propertyName,
    required this.onTap,
  });

  final VisitSummaryModel visit;
  final String propertyName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Propriedade: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: propertyName,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'ID externo: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: visit.idExterno,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (visit.observacoes != null &&
                  visit.observacoes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  visit.observacoes!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                '${visit.animais.length} animal(is) com coleta registrada',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
