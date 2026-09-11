import 'package:cysvet_app/app/theme.dart';
import 'package:cysvet_app/core/constants/app_constants.dart';
import 'package:cysvet_app/core/widgets/property_filter_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cysvet_app/app/app_shell.dart';
import 'package:cysvet_app/core/presentation/app_scaffold_messenger.dart';
import 'package:cysvet_app/core/presentation/async_value_view.dart';
import 'package:cysvet_app/core/utils/formatters.dart';
import 'package:cysvet_app/core/widgets/app_button.dart';
import 'package:cysvet_app/core/widgets/app_card.dart';
import 'package:cysvet_app/core/widgets/search_card.dart';
import 'package:cysvet_app/filters/visit_filter.dart';
import 'package:cysvet_app/providers/properties_provider.dart';
import 'package:cysvet_app/models/property_summary_model.dart';
import 'package:cysvet_app/providers/visits_provider.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';
import 'visit_report_page.dart';

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

    void createVisit() {
      if (propertyOptions.isEmpty) {
        showAppWarning('Carregue ou cadastre uma propriedade antes da visita.');
        return;
      }

      final query = selectedPropertyId == null
          ? ''
          : '?propriedade=$selectedPropertyId';
      context.go('/visitas/nova$query');
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(visitsProvider.future),
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              PageTitle(
                title: 'Visitas',
                subtitle:
                    'Registre atendimentos, acompanhe visitas e gere relatórios técnicos.',
                headerButton: AppButton(
                  text: 'Nova visita',
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: createVisit,
                ),
              ),
              Padding(
                padding: PageTitle.contentPadding(context),
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
                                returnRoute: '/visitas',
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

class _VisitsToolbar extends StatefulWidget {
  const _VisitsToolbar({
    required this.searchQuery,
    required this.properties,
    required this.selectedPropertyId,
    required this.onSearchChanged,
    required this.onPropertyChanged,
  });

  final String searchQuery;
  final List<PropertySummaryModel> properties;
  final int? selectedPropertyId;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int?> onPropertyChanged;

  @override
  State<_VisitsToolbar> createState() => _VisitsToolbarState();
}

class _VisitsToolbarState extends State<_VisitsToolbar> {
  bool _filtersOpen = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.sizeOf(context).width < MOBILE_WIDTH;
        final stacked = constraints.maxWidth < 760;
        final search = SearchCard(
          value: widget.searchQuery,
          labelText: 'Pesquisar visitas',
          onChanged: widget.onSearchChanged,
        );
        final propertyFilter = PropertyFilterCard(
          properties: widget.properties,
          selectedPropertyId: widget.selectedPropertyId,
          labelText: 'Propriedade',
          allPropertiesText: 'Todas',
          onChanged: widget.onPropertyChanged,
        );

        final filterButton = Tooltip(
          message: _filtersOpen ? 'Ocultar filtros' : 'Mostrar filtros',
          child: AppButton(
            outlined: _filtersOpen,
            onPressed: () {
              setState(() => _filtersOpen = !_filtersOpen);
            },
            child: Icon(
              _filtersOpen
                  ? Icons.filter_alt_off_outlined
                  : Icons.filter_alt_outlined,
            ),
          ),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: 10),
                  filterButton,
                ],
              ),
              if (_filtersOpen) ...[const SizedBox(height: 10), propertyFilter],
            ],
          );
        }

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [search, const SizedBox(height: 10), propertyFilter],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: search),
            const SizedBox(width: 14),
            SizedBox(width: 230, child: propertyFilter),
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
            mainAxisExtent: 395,
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

    return AppCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(18),
      shadow: false,
      borderColor: colorScheme.outline.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// Cabeçalho
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _VisitDateBadge(date: visit.dataVisita),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dashIfBlank(propertyName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _protocolLabel(visit),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// Veterinário
          _VisitInfoLine(
            icon: Icons.badge_outlined,
            text: _dashIfBlank(visit.nomeUsuario),
          ),

          const SizedBox(height: 8),

          /// Data
          _VisitInfoLine(
            icon: Icons.calendar_today_outlined,
            text: formatDate(visit.dataVisita),
          ),

          const SizedBox(height: 16),

          /// Indicadores
          Row(
            children: [
              Expanded(
                child: _VisitMetricTile(
                  label: 'Animais',
                  value: visit.animais.length.toString(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VisitMetricTile(
                  label: 'Prenhas',
                  value: pregnantCount == 0 ? '--' : pregnantCount.toString(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VisitMetricTile(
                  label: 'Prenhez',
                  value: _pregnancyRateLabel(visit),
                  highlighted: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// Próximo passo
          _NextStepPreview(text: _nextStepText(visit)),

          const SizedBox(height: 16),

          AppButton(
            text: 'Ver relatório',
            height: 46,
            expanded: true,
            outlined: true,
            borderRadius: 10,
            icon: const Icon(Icons.description_outlined, size: 18),
            trailingIcon: const Icon(Icons.chevron_right_rounded, size: 22),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

class _VisitDateBadge extends StatelessWidget {
  const _VisitDateBadge({required this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary2 = AppTheme.primary2Color;

    const months = [
      'JAN',
      'FEV',
      'MAR',
      'ABR',
      'MAI',
      'JUN',
      'JUL',
      'AGO',
      'SET',
      'OUT',
      'NOV',
      'DEZ',
    ];

    final day = date?.day.toString().padLeft(2, '0') ?? '--';
    final month = date != null ? months[date!.month - 1] : '---';

    return Container(
      width: 56,
      height: 58,
      decoration: BoxDecoration(
        color: primary2.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: theme.textTheme.titleLarge?.copyWith(
              color: primary2,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            month,
            style: theme.textTheme.labelSmall?.copyWith(
              color: primary2,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
              height: 1,
            ),
          ),
        ],
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

    final textColor = colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Icon(icon, size: 17, color: textColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _VisitMetricTile extends StatelessWidget {
  const _VisitMetricTile({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary2 = AppTheme.primary2Color;

    final backgroundColor = highlighted
        ? primary2
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.38);

    final valueColor = highlighted ? Colors.white : colorScheme.onSurface;

    final labelColor = highlighted
        ? Colors.white.withValues(alpha: 0.88)
        : colorScheme.onSurfaceVariant;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: highlighted
            ? null
            : Border.all(color: colorScheme.outline.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: labelColor,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
              height: 1,
            ),
          ),
        ],
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
    final primary2 = AppTheme.primary2Color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: primary2.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag_outlined,
                size: 17,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'PRÓXIMO PASSO',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
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
