import 'package:cysvet_app/core/constants/app_constants.dart';
import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/core/enums/property_status.dart';
import 'package:cysvet_app/core/utils/formatters.dart';
import 'package:cysvet_app/core/widgets/app_button.dart';
import 'package:cysvet_app/core/widgets/app_card.dart';
import 'package:cysvet_app/core/widgets/app_dropdown.dart';
import 'package:cysvet_app/core/widgets/search_card.dart';
import 'package:cysvet_app/core/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cysvet_app/app/app_shell.dart';
import 'package:cysvet_app/app/theme.dart';
import 'package:cysvet_app/core/presentation/async_value_view.dart';
import 'package:cysvet_app/providers/animals_provider.dart';
import 'package:cysvet_app/api/animals_api.dart';
import 'package:cysvet_app/models/animal_summary_model.dart';
import 'package:cysvet_app/providers/auth_state.dart';
import 'package:cysvet_app/providers/visits_provider.dart';
import 'package:cysvet_app/api/visits_api.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';
import 'package:cysvet_app/filters/property_filter.dart';
import 'package:cysvet_app/providers/properties_provider.dart';
import 'package:cysvet_app/models/property_summary_model.dart';
import 'property_dialog.dart';

final propertiesRelatedDataProvider =
    FutureProvider.autoDispose<_PropertiesRelatedData>((ref) async {
      final session = ref.watch(authSessionProvider);
      final localAnimals = ref.watch(localAnimalsProvider);
      final deletedAnimalIds = ref.watch(deletedAnimalsProvider);
      final localVisits = ref.watch(localVisitsProvider);

      if (session == null) {
        throw StateError('Sessao indisponivel.');
      }

      final animalsRepository = ref.watch(animalsRepositoryProvider);
      final visitsRepository = ref.watch(visitsRepositoryProvider);
      var remoteAnimals = <AnimalSummaryModel>[];
      var remoteVisits = <VisitSummaryModel>[];

      await Future.wait<void>([
        animalsRepository.list().then((items) => remoteAnimals = items),
        visitsRepository.list().then((items) => remoteVisits = items),
      ]);

      final animals =
          {
            for (final animal in remoteAnimals)
              animal.id: localAnimals[animal.id] ?? animal,
            ...localAnimals,
          }.values.where((animal) {
            return !deletedAnimalIds.contains(animal.id);
          }).toList();
      animals.sort((a, b) => a.codigo.compareTo(b.codigo));

      final visits = {
        for (final visit in remoteVisits)
          visit.id: localVisits[visit.id] ?? visit,
        ...localVisits,
      }.values.toList();
      visits.sort(_compareVisitsByDateDesc);

      return _PropertiesRelatedData(animals: animals, visits: visits);
    });

class PropertiesPage extends ConsumerWidget {
  const PropertiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(propertiesProvider);
    final relatedData = ref.watch(propertiesRelatedDataProvider);
    final searchQuery = ref.watch(propertiesSearchQueryProvider);
    final statusFilter = ref.watch(propertiesStatusFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait<void>([
              ref.refresh(propertiesProvider.future).then((_) {}),
              ref.refresh(propertiesRelatedDataProvider.future).then((_) {}),
            ]);
          },
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              PageTitle(
                title: 'Propriedades',
                subtitle:
                    'Gerencie as fazendas atendidas e suas informações cadastrais.',
                headerButton: AppButton(
                  text: 'Nova propriedade',
                  icon: const Icon(Icons.add),
                  onPressed: () => PropertyDialog.show(context),
                ),
              ),
              Padding(
                padding: PageTitle.contentPadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: _PropertiesToolbar(
                        searchQuery: searchQuery,
                        statusFilter: statusFilter,
                        onSearchChanged: (value) {
                          ref
                                  .read(propertiesSearchQueryProvider.notifier)
                                  .state =
                              value;
                        },
                        onStatusChanged: (value) {
                          ref
                                  .read(propertiesStatusFilterProvider.notifier)
                                  .state =
                              value ?? PropertyStatusFilter.all;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    AsyncValueView<List<PropertySummaryModel>>(
                      value: properties,
                      loadingMessage: 'Buscando propriedades...',
                      emptyMessage: 'Nenhuma propriedade cadastrada.',
                      isEmpty: (items) => items.isEmpty,
                      onRetry: () => ref.invalidate(propertiesProvider),
                      builder: (items) {
                        final filteredItems = _filterProperties(
                          items,
                          searchQuery,
                          statusFilter,
                        );

                        if (filteredItems.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Center(
                              child: Text(
                                'Nenhuma propriedade encontrada para os filtros atuais.',
                                style: theme.textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        final related = relatedData.asData?.value;

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final columns = width >= 1060
                                ? 3
                                : width >= 700
                                ? 2
                                : 1;
                            const spacing = 22.0;
                            final cardWidth =
                                (width - (spacing * (columns - 1))) / columns;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: [
                                for (final property in filteredItems)
                                  SizedBox(
                                    width: cardWidth,
                                    child: _PropertyCard(
                                      property: property,
                                      insights: related == null
                                          ? null
                                          : _PropertyInsights.from(
                                              property,
                                              related,
                                            ),
                                      insightsLoading: relatedData.isLoading,
                                      onTap: () => context.go(
                                        '/propriedades/${property.id}',
                                      ),
                                    ),
                                  ),
                              ],
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

class _PropertiesToolbar extends StatefulWidget {
  const _PropertiesToolbar({
    required this.searchQuery,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
  });

  final String searchQuery;
  final PropertyStatusFilter statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<PropertyStatusFilter?> onStatusChanged;

  @override
  State<_PropertiesToolbar> createState() => _PropertiesToolbarState();
}

class _PropertiesToolbarState extends State<_PropertiesToolbar> {
  bool _filtersOpen = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.sizeOf(context).width < MOBILE_WIDTH;
        final stacked = constraints.maxWidth < 720;
        final search = SearchCard(
          value: widget.searchQuery,
          labelText: 'Pesquisar propriedades',
          onChanged: widget.onSearchChanged,
        );
        final status = AppDropdown<PropertyStatusFilter>(
          value: widget.statusFilter,
          labelText: 'Status',
          onChanged: widget.onStatusChanged,
          options: PropertyStatusFilter.values
              .map((item) => AppDropdownOption(label: item.label, value: item))
              .toList(growable: false),
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
              if (_filtersOpen) ...[const SizedBox(height: 10), status],
            ],
          );
        }

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [search, const SizedBox(height: 10), status],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: search),
            const SizedBox(width: 12),
            SizedBox(width: 200, child: status),
          ],
        );
      },
    );
  }
}

List<PropertySummaryModel> _filterProperties(
  List<PropertySummaryModel> items,
  String query,
  PropertyStatusFilter statusFilter,
) {
  final normalizedQuery = query.trim().normalize();

  return items.where((property) {
    final matchesStatus = switch (statusFilter) {
      PropertyStatusFilter.all => true,
      PropertyStatusFilter.active => property.status == PropertyStatus.active,
      PropertyStatusFilter.inactive =>
        property.status == PropertyStatus.inactive,
    };
    final searchableText = [
      property.nome,
      property.nomeProprietario,
      property.contato ?? '',
      property.localizacao,
      property.idExterno,
      property.observacoes ?? '',
    ].join(' ').normalize();
    return matchesStatus &&
        (normalizedQuery.isEmpty || searchableText.contains(normalizedQuery));
  }).toList();
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.property,
    required this.insights,
    required this.insightsLoading,
    required this.onTap,
  });

  final PropertySummaryModel property;
  final _PropertyInsights? insights;
  final bool insightsLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lastVisit = insights?.lastVisit;
    final loadingLabel = insightsLoading && insights == null ? '...' : '--';
    final lastVisitText = lastVisit == null
        ? loadingLabel
        : '${formatDate(lastVisit.dataVisita)} • ${_dashIfBlank(lastVisit.veterinarioResponsavel)}';

    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: 18,
      shadow: false,
      borderColor: colorScheme.outline.withValues(alpha: 0.22),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _PropertyInitialsBadge(name: property.nome),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.nome,
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
                            _dashIfBlank(property.idExterno),
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
                    const SizedBox(width: 10),
                    _PropertyStatusBadge(status: property.status),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoLine(
                  icon: Icons.person_outline,
                  value: _dashIfBlank(property.nomeProprietario),
                ),
                const SizedBox(height: 8),
                _InfoLine(
                  icon: Icons.phone_outlined,
                  value: _dashIfBlank(property.contato),
                ),
                const SizedBox(height: 8),
                _InfoLine(
                  icon: Icons.location_on_outlined,
                  value: _dashIfBlank(property.localizacao),
                ),
                const SizedBox(height: 16),
                _PropertyMetricRow(
                  totalHerd: insights?.herdTotal,
                  reproductionCount: insights?.reproductionCount,
                  loadingLabel: loadingLabel,
                ),
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.outline.withValues(alpha: 0.22),
                ),
                const SizedBox(height: 12),
                _LastVisitPreview(text: lastVisitText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PropertyInitialsBadge extends StatelessWidget {
  const _PropertyInitialsBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary2 = AppTheme.primary2Color;

    return Container(
      width: 56,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primary2.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        _propertyInitials(name),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          color: primary2,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _PropertyStatusBadge extends StatelessWidget {
  const _PropertyStatusBadge({required this.status});

  final PropertyStatus status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == PropertyStatus.active;

    return StatusBadge(
      label: status.label,
      type: isActive ? StatusBadgeType.success : StatusBadgeType.neutral,
      backgroundColor: isActive
          ? Theme.of(context).brightness == Brightness.dark
                ? AppTheme.syncBadgeDarkBackgroundColor
                : AppTheme.syncBadgeBackgroundColor
          : null,
      foregroundColor: isActive
          ? Theme.of(context).brightness == Brightness.dark
                ? AppTheme.syncBadgeDarkForegroundColor
                : AppTheme.syncBadgeForegroundColor
          : null,
      borderColor: isActive ? Colors.transparent : null,
    );
  }
}

class _PropertyMetricRow extends StatelessWidget {
  const _PropertyMetricRow({
    required this.totalHerd,
    required this.reproductionCount,
    required this.loadingLabel,
  });

  final int? totalHerd;
  final int? reproductionCount;
  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canFitSideBySide = constraints.maxWidth >= 310;

        final total = _PropertyMetricTile(
          label: 'REBANHO TOTAL',
          value: totalHerd == null ? loadingLabel : _formatCount(totalHerd!),
        );
        final reproduction = _PropertyMetricTile(
          label: 'EM PRODUÇÃO',
          value: reproductionCount == null
              ? loadingLabel
              : _formatCount(reproductionCount!),
          highlighted: true,
        );

        if (!canFitSideBySide) {
          return Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [total, const SizedBox(height: 8), reproduction],
            ),
          );
        }

        return Row(
          children: [
            Expanded(child: total),
            const SizedBox(width: 10),
            Expanded(child: reproduction),
          ],
        );
      },
    );
  }
}

class _PropertyMetricTile extends StatelessWidget {
  const _PropertyMetricTile({
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
    final background = highlighted
        ? primary2
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.38);
    final valueColor = highlighted ? Colors.white : colorScheme.onSurface;
    final labelColor = highlighted
        ? Colors.white.withValues(alpha: 0.88)
        : colorScheme.onSurfaceVariant;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: highlighted
            ? null
            : Border.all(color: colorScheme.outline.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: labelColor,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
              height: 1,
            ),
          ),
          const Spacer(),
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
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

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
            value,
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

class _LastVisitPreview extends StatelessWidget {
  const _LastVisitPreview({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ÚLTIMA VISITA',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _PropertiesRelatedData {
  const _PropertiesRelatedData({required this.animals, required this.visits});

  final List<AnimalSummaryModel> animals;
  final List<VisitSummaryModel> visits;
}

class _PropertyInsights {
  const _PropertyInsights({
    required this.animals,
    required this.visits,
    required this.herdTotal,
    required this.reproductionCount,
    required this.lastVisit,
  });

  final List<AnimalSummaryModel> animals;
  final List<VisitSummaryModel> visits;
  final int herdTotal;
  final int reproductionCount;
  final VisitSummaryModel? lastVisit;

  factory _PropertyInsights.from(
    PropertySummaryModel property,
    _PropertiesRelatedData data,
  ) {
    final animals = data.animals
        .where((animal) {
          return _animalBelongsToProperty(animal, property);
        })
        .toList(growable: false);
    final visits = data.visits
        .where((visit) {
          return _visitBelongsToProperty(visit, property);
        })
        .toList(growable: false);
    VisitSummaryModel? lastVisit;

    for (final visit in visits) {
      if (lastVisit == null || _compareVisitsByDateDesc(visit, lastVisit) < 0) {
        lastVisit = visit;
      }
    }

    return _PropertyInsights(
      animals: animals,
      visits: visits,
      herdTotal: animals.length,
      reproductionCount: animals.where((animal) {
        return animal.status == AnimalStatus.active &&
            _isAnimalInReproduction(animal);
      }).length,
      lastVisit: lastVisit,
    );
  }
}

bool _animalBelongsToProperty(
  AnimalSummaryModel animal,
  PropertySummaryModel property,
) {
  if (property.id != 0 && animal.idPropriedade == property.id) {
    return true;
  }

  return property.idExterno.isNotEmpty &&
      animal.idExternoPropriedade == property.idExterno;
}

bool _visitBelongsToProperty(
  VisitSummaryModel visit,
  PropertySummaryModel property,
) {
  if (property.id != 0 && visit.idPropriedade == property.id) {
    return true;
  }

  return property.idExterno.isNotEmpty &&
      visit.idExternoPropriedade == property.idExterno;
}

int _compareVisitsByDateDesc(VisitSummaryModel a, VisitSummaryModel b) {
  final dateA = a.dataVisita;
  final dateB = b.dataVisita;
  if (dateA == null && dateB == null) return b.id.compareTo(a.id);
  if (dateA == null) return 1;
  if (dateB == null) return -1;
  final dateComparison = dateB.compareTo(dateA);
  if (dateComparison != 0) return dateComparison;
  return b.id.compareTo(a.id);
}

bool _isAnimalInReproduction(AnimalSummaryModel animal) {
  final status = _animalReproductiveStatusFor(animal);
  return switch (status) {
    AnimalReproductiveStatus.pregnant ||
    AnimalReproductiveStatus.empty ||
    AnimalReproductiveStatus.inseminated ||
    AnimalReproductiveStatus.inseminatedSt ||
    AnimalReproductiveStatus.protocol ||
    AnimalReproductiveStatus.waitingDiagnosis ||
    AnimalReproductiveStatus.released ||
    AnimalReproductiveStatus.delayed => true,
    AnimalReproductiveStatus.dry ||
    AnimalReproductiveStatus.induction ||
    AnimalReproductiveStatus.discard ||
    AnimalReproductiveStatus.pev ||
    AnimalReproductiveStatus.noAge ||
    AnimalReproductiveStatus.calf ||
    AnimalReproductiveStatus.pending => false,
  };
}

AnimalReproductiveStatus _animalReproductiveStatusFor(
  AnimalSummaryModel animal,
) {
  final savedStatus = animal.statusReprodutivo;
  if (savedStatus != null) {
    return savedStatus;
  }

  if (animal.dataInseminacao != null) {
    return AnimalReproductiveStatus.inseminated;
  }

  final history = (animal.historicoReprodutivo ?? '').normalize();

  if (history.contains('pren') || history.contains('confirm')) {
    return AnimalReproductiveStatus.pregnant;
  }

  if (history.contains('insemin')) {
    return AnimalReproductiveStatus.inseminated;
  }

  if (history.contains('seca') || history.contains('dry')) {
    return AnimalReproductiveStatus.dry;
  }

  if (history.contains('vazia') ||
      history.contains('empty') ||
      history.contains('negativ') ||
      history.contains('toque')) {
    return AnimalReproductiveStatus.empty;
  }

  return AnimalReproductiveStatus.pending;
}

String _formatCount(int value) {
  return formatInteger(value);
}

String _propertyInitials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return '--';
  if (parts.length == 1) {
    final first = parts.first;
    return first.length == 1
        ? first.toUpperCase()
        : first.substring(0, 2).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

String _dashIfBlank(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return '--';
  return text;
}
