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
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_shell.dart';
import '../../../core/presentation/async_value_view.dart';
import '../../animals/application/animals_provider.dart';
import '../../animals/data/animals_repository.dart';
import '../../animals/domain/animal_summary_model.dart';
import '../../auth/application/auth_state.dart';
import '../../visits/application/visits_provider.dart';
import '../../visits/data/visits_repository.dart';
import '../../visits/domain/visit_summary_model.dart';
import '../application/properties_provider.dart';
import '../domain/property_summary_model.dart';
import 'property_dialog.dart';

final propertiesSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);
final propertiesStatusFilterProvider =
    StateProvider.autoDispose<PropertyStatusFilter>((ref) {
      return PropertyStatusFilter.active;
    });

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
                            final size = MediaQuery.sizeOf(context);
                            final isMobile = size.width < MOBILE_WIDTH;
                            final isSmallMobile = size.width < 360;
                            final cardWidth = isSmallMobile
                                ? double.infinity
                                : 360.0;
                            final alignment = isMobile
                                ? WrapAlignment.center
                                : WrapAlignment.start;

                            return Wrap(
                              alignment: alignment,
                              runAlignment: alignment,
                              spacing: 16,
                              runSpacing: 16,
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

    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: 20,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        property.nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    StatusBadge(
                      label: property.status.label,
                      type: property.status == PropertyStatus.active
                          ? StatusBadgeType.success
                          : StatusBadgeType.neutral,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoLine(
                  label: 'Responsável',
                  value: _dashIfBlank(property.nomeProprietario),
                ),
                _InfoLine(
                  label: 'Contato',
                  value: _dashIfBlank(property.contato),
                ),
                _InfoLine(
                  label: 'Localização',
                  value: _dashIfBlank(property.localizacao),
                ),
                const SizedBox(height: 14),
                _PropertyMetricRow(
                  totalHerd: insights?.herdTotal,
                  reproductionCount: insights?.reproductionCount,
                  loadingLabel: loadingLabel,
                ),
                const SizedBox(height: 12),
                _InfoLine(
                  label: 'Última visita',
                  value: lastVisit == null
                      ? loadingLabel
                      : formatDate(lastVisit.dataVisita),
                ),
                _InfoLine(
                  label: 'Veterinário',
                  value: _dashIfBlank(
                    lastVisit?.veterinarioResponsavel ?? loadingLabel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
          icon: Icons.groups_outlined,
        );
        final reproduction = _PropertyMetricTile(
          label: 'EM REPRODUCAO',
          value: reproductionCount == null
              ? loadingLabel
              : _formatCount(reproductionCount!),
          icon: Icons.monitor_heart_outlined,
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
            Flexible(fit: FlexFit.loose, child: total),
            const SizedBox(width: 10),
            Flexible(fit: FlexFit.loose, child: reproduction),
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
    required this.icon,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = highlighted
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest;
    final foreground = highlighted
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final mutedForeground = highlighted
        ? colorScheme.onPrimary.withValues(alpha: 0.74)
        : colorScheme.onSurfaceVariant;

    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: mutedForeground),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: mutedForeground,
                    fontWeight: FontWeight.w800,
                    fontSize: 8,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: foreground,
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
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
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

String _dashIfBlank(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return '--';
  return text;
}
