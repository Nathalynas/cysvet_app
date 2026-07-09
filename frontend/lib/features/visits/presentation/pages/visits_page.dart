import 'package:cysvet_app/core/constants/app_constants.dart';
import 'package:cysvet_app/core/widgets/property_filter_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_shell.dart';
import '../../../../core/presentation/app_scaffold_messenger.dart';
import '../../../../core/presentation/async_value_view.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/search_card.dart';
import '../../../properties/application/properties_provider.dart';
import '../../../properties/domain/property_summary_model.dart';
import '../../application/visits_provider.dart';
import '../../domain/visit_summary_model.dart';
import 'visit_report_page.dart';

final visitsSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

class VisitsPage extends ConsumerWidget {
  const VisitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visits = ref.watch(visitsProvider);
    final properties = ref.watch(propertiesProvider);
    final selectedPropertyId = ref.watch(visitsPropertyFilterProvider);
    final searchQuery = ref.watch(visitsSearchQueryProvider);
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
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const PageTitle(
                title: 'Visitas',
                subtitle:
                    'Registre atendimentos, acompanhe visitas e gere relatórios técnicos.',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _VisitsToolbar(
                      searchQuery: searchQuery,
                      properties: propertyOptions,
                      selectedPropertyId: selectedPropertyId,
                      onSearchChanged: (value) {
                        ref.read(visitsSearchQueryProvider.notifier).state =
                            value;
                      },
                      onPropertyChanged: (value) {
                        ref
                            .read(visitsPropertyFilterProvider.notifier)
                            .set(value);
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
                    const SizedBox(height: 28),
                    AsyncValueView<List<VisitSummaryModel>>(
                      value: visits,
                      loadingMessage: 'Buscando visitas...',
                      emptyMessage:
                          'Nenhuma visita encontrada para o filtro atual.',
                      isEmpty: (items) => items.isEmpty,
                      onRetry: () => ref.invalidate(visitsProvider),
                      builder: (items) {
                        final filteredItems = _filterVisits(
                          items,
                          searchQuery,
                          propertyById,
                        );

                        if (filteredItems.isEmpty) {
                          return const _VisitsEmptyState();
                        }

                        return _VisitsGrid(
                          visits: filteredItems,
                          propertyById: propertyById,
                          onOpen: (visit) {
                            final property = propertyById[visit.idPropriedade];
                            final propertyName =
                                property?.nome ?? visit.idExternoPropriedade;

                            context.go(
                              '/visitas/${visit.id}/detalhes',
                              extra: VisitReportRouteData(
                                visit: visit,
                                propertyName: propertyName,
                                property: property,
                              ),
                            );
                          },
                        );
                      },
                    ),
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
    required this.searchQuery,
    required this.properties,
    required this.selectedPropertyId,
    required this.onSearchChanged,
    required this.onPropertyChanged,
    required this.onCreate,
  });

  final String searchQuery;
  final List<PropertySummaryModel> properties;
  final int? selectedPropertyId;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int?> onPropertyChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 760;
        final search = SearchCard(
          value: searchQuery,
          labelText: 'Pesquisar visitas',
          onChanged: onSearchChanged,
        );
        final propertyFilter = PropertyFilterCard(
          properties: properties,
          selectedPropertyId: selectedPropertyId,
          labelText: 'Propriedade',
          allPropertiesText: 'Todas',
          onChanged: onPropertyChanged,
        );
        final createButton = AppButton(
          text: 'Nova visita',
          icon: const Icon(Icons.add, size: 18),
          height: 42,
          borderRadius: 16,
          onPressed: onCreate,
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 10),
              propertyFilter,
              const SizedBox(height: 10),
              createButton,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: search),
            const SizedBox(width: 14),
            SizedBox(width: 230, child: propertyFilter),
            const SizedBox(width: 14),
            createButton,
          ],
        );
      },
    );
  }
}

class _VisitsGrid extends StatelessWidget {
  const _VisitsGrid({
    required this.visits,
    required this.propertyById,
    required this.onOpen,
  });

  final List<VisitSummaryModel> visits;
  final Map<int, PropertySummaryModel> propertyById;
  final ValueChanged<VisitSummaryModel> onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1060
            ? 3
            : width >= 700
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visits.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 22,
            mainAxisSpacing: 22,
            mainAxisExtent: 372,
          ),
          itemBuilder: (context, index) {
            final visit = visits[index];
            final property = propertyById[visit.idPropriedade];

            return _VisitCard(
              visit: visit,
              propertyName: property?.nome ?? visit.idExternoPropriedade,
              onTap: () => onOpen(visit),
            );
          },
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
    final pregnantCount = visit.animais.where(_isPregnant).length;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AppCard(
          borderRadius: 12,
          padding: const EdgeInsets.all(18),
          borderColor: colorScheme.outline.withValues(alpha: 0.28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _dashIfBlank(propertyName),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 18),
              _VisitInfoLine(
                icon: Icons.calendar_today_outlined,
                text: formatDate(visit.dataVisita),
              ),
              const SizedBox(height: 10),
              _VisitInfoLine(
                icon: Icons.person_pin_outlined,
                text: 'Veterinário: ${_dashIfBlank(visit.nomeUsuario)}',
              ),
              const SizedBox(height: 10),
              _VisitInfoLine(
                icon: Icons.menu_book_outlined,
                text: 'Protocolo: ${_protocolLabel(visit)}',
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _VisitMetricTile(
                      icon: MdiIcons.cow,
                      label: 'Animais',
                      value: visit.animais.length.toString(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _VisitMetricTile(
                      icon: MdiIcons.cow,
                      label: 'Prenhas',
                      value: pregnantCount == 0 ? '--' : '$pregnantCount',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _VisitMetricTile(
                      icon: Icons.percent_outlined,
                      label: 'Taxa de Prenhez',
                      value: _pregnancyRateLabel(visit),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _NextStepPreview(text: _nextStepText(visit)),
              const Spacer(),
              AppButton(
                text: 'Ver relatório',
                height: 40,
                expanded: true,
                borderRadius: 8,
                icon: const Icon(Icons.description_outlined, size: 18),
                trailingIcon: const Icon(Icons.chevron_right, size: 22),
                onPressed: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisitInfoLine extends StatelessWidget {
  const _VisitInfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _VisitMetricTile extends StatelessWidget {
  const _VisitMetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      borderRadius: 9,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      shadow: false,
      borderColor: colorScheme.outline.withValues(alpha: 0.35),
      child: SizedBox(
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextStepPreview extends StatelessWidget {
  const _NextStepPreview({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Próximo passo',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _VisitsEmptyState extends StatelessWidget {
  const _VisitsEmptyState();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 12,
      shadow: false,
      child: Text(
        'Nenhuma visita encontrada para os filtros atuais.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

List<VisitSummaryModel> _filterVisits(
  List<VisitSummaryModel> visits,
  String query,
  Map<int, PropertySummaryModel> propertyById,
) {
  final normalizedQuery = query.trim().normalize();
  if (normalizedQuery.isEmpty) return visits;

  return visits
      .where((visit) {
        final propertyName =
            propertyById[visit.idPropriedade]?.nome ??
            visit.idExternoPropriedade;
        final searchableText = [
          propertyName,
          visit.idExterno,
          visit.nomeUsuario ?? '',
          visit.observacoes ?? '',
          formatDate(visit.dataVisita),
          _protocolLabel(visit),
        ].join(' ').normalize();

        return searchableText.contains(normalizedQuery);
      })
      .toList(growable: false);
}

String _protocolLabel(VisitSummaryModel visit) {
  final animals = visit.animais;
  if (animals.isEmpty) return 'Visita técnica';

  final hasDiagnosis = animals.any(
    (animal) =>
        _cleanText(animal.diagnostico) != null ||
        _isPregnant(animal) ||
        _isEmptyReproductive(animal),
  );
  final hasProtocol = animals.any(
    (animal) =>
        _cleanText(animal.decisao) != null ||
        animal.dataUltimaIa != null ||
        animal.numeroIaRecebida != null,
  );

  if (hasProtocol && hasDiagnosis) return 'IATF + Diagnóstico';
  if (hasProtocol) return 'IATF / Protocolo reprodutivo';
  if (hasDiagnosis) return 'Diagnóstico reprodutivo';
  return 'Conferência técnica';
}

String _nextStepText(VisitSummaryModel visit) {
  final steps = <_VisitNextStep>[];

  for (final animal in visit.animais) {
    final identification =
        _cleanText(animal.animalCodigo) ??
        _cleanText(animal.animalIdExterno) ??
        'animal';

    if (animal.previsaoSecagem != null) {
      steps.add(
        _VisitNextStep(
          date: animal.previsaoSecagem!,
          text: 'Secagem prevista para $identification.',
        ),
      );
    }

    if (animal.dataPreParto != null) {
      steps.add(
        _VisitNextStep(
          date: animal.dataPreParto!,
          text: 'Pré-parto previsto para $identification.',
        ),
      );
    }

    if (animal.previsaoParto != null) {
      steps.add(
        _VisitNextStep(
          date: animal.previsaoParto!,
          text: 'Parto previsto para $identification.',
        ),
      );
    }
  }

  steps.sort((a, b) => a.date.compareTo(b.date));

  if (steps.isEmpty) {
    return _cleanText(visit.observacoes) ?? 'Próximos passos pendentes.';
  }

  final first = steps.first;
  return '${formatDate(first.date)} - ${first.text}';
}

String _pregnancyRateLabel(VisitSummaryModel visit) {
  final pregnant = visit.animais.where(_isPregnant).length;
  final empty = visit.animais.where(_isEmptyReproductive).length;
  final denominator = pregnant + empty;
  if (denominator == 0) return '--';

  return formatPercent(pregnant / denominator);
}

bool _isPregnant(VisitAnimalEntryModel entry) {
  if (_isEmptyReproductive(entry)) return false;
  if (entry.diasPrenhez != null) return true;

  return _containsAny(_reproductiveText(entry), const [
    'prenhe',
    'prenha',
    'prenhez',
    'positivo',
    'gestante',
  ]);
}

bool _isEmptyReproductive(VisitAnimalEntryModel entry) {
  return _containsAny(_reproductiveText(entry), const [
    'vazia',
    'vazio',
    'negativo',
    'nao prenha',
    'nao gestante',
  ]);
}

String _reproductiveText(VisitAnimalEntryModel entry) {
  return [
    entry.situacaoReprodutiva,
    entry.decisao,
    entry.diagnostico,
  ].whereType<String>().join(' ');
}

bool _containsAny(String value, List<String> terms) {
  final normalized = value.normalize();
  return terms.any((term) => normalized.contains(term.normalize()));
}

String? _cleanText(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

String _dashIfBlank(String? value) {
  return _cleanText(value) ?? '--';
}

class _VisitNextStep {
  const _VisitNextStep({required this.date, required this.text});

  final DateTime date;
  final String text;
}
