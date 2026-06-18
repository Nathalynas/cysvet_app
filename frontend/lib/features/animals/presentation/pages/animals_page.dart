import 'dart:convert';

import 'package:cysvet_app/core/constants/app_constants.dart';
import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/core/presentation/app_scaffold_messenger.dart';
import 'package:cysvet_app/core/widgets/app_button.dart';
import 'package:cysvet_app/core/widgets/app_card.dart';
import 'package:cysvet_app/core/widgets/app_dialog.dart';
import 'package:cysvet_app/core/widgets/app_dropdown.dart';
import 'package:cysvet_app/core/widgets/app_table.dart';
import 'package:cysvet_app/core/widgets/property_filter_card.dart';
import 'package:cysvet_app/core/widgets/search_card.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/presentation/async_value_view.dart';
import '../../../../core/utils/formatters.dart';
import '../../../properties/application/properties_provider.dart';
import '../../../properties/domain/property_summary_model.dart';
import '../../../visits/application/visits_provider.dart';
import '../../../visits/data/visits_repository.dart';
import '../../../visits/domain/visit_summary_model.dart';
import '../../application/animals_csv_importer.dart';
import '../../application/animals_provider.dart';
import '../../data/animals_repository.dart';
import '../../domain/animal_history_event_model.dart';
import '../../domain/animal_summary_model.dart';
import '../widgets/animal_dialog.dart';

final animalsSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

final animalsStatusFilterProvider =
    StateProvider.autoDispose<AnimalStatusFilter>((ref) {
      return AnimalStatusFilter.active;
    });

final animalsReproductiveStatusFilterProvider =
    StateProvider.autoDispose<AnimalReproductiveStatus?>((ref) => null);

final _animalHistoryProvider = FutureProvider.autoDispose
    .family<_AnimalHistoryData, AnimalSummaryModel>((ref, animal) async {
      // TODO(api): substituir esta composicao front-end por um endpoint
      // consolidado, por exemplo GET /api/animals/{id}/history, retornando
      // historico produtivo, eventos, visitas, movimentacoes e alteracoes.
      // Temporario: eventos vêm de /api/events?idAnimal; visitas vêm de
      // /api/visits?idPropriedade e sao filtradas no front. Movimentacoes e
      // alteracoes ainda usam somente o estado atual de AnimalSummaryModel.
      final eventsFuture = animal.id > 0
          ? ref
                .watch(animalsRepositoryProvider)
                .listHistoryEvents(animalId: animal.id)
          : Future.value(const <AnimalHistoryEventModel>[]);
      final remoteVisitsFuture = ref
          .watch(visitsRepositoryProvider)
          .list(
            propertyId: animal.idPropriedade > 0 ? animal.idPropriedade : null,
          );
      final localVisits = ref.watch(localVisitsProvider).values;

      final results = await Future.wait<Object>([
        eventsFuture,
        remoteVisitsFuture,
      ]);
      final events = [...(results[0] as List<AnimalHistoryEventModel>)]
        ..sort(_compareHistoryEventsDesc);
      final remoteVisits = results[1] as List<VisitSummaryModel>;
      final visitsById = {
        for (final visit in remoteVisits) visit.id: visit,
        for (final visit in localVisits)
          if (_visitBelongsToAnimalProperty(visit, animal)) visit.id: visit,
      };
      final visitRecords =
          visitsById.values
              .expand((visit) => _visitRecordsForAnimal(visit, animal))
              .toList()
            ..sort(_compareVisitRecordsDesc);

      return _AnimalHistoryData(
        animal: animal,
        events: events,
        visits: visitRecords,
      );
    });

class AnimalsPage extends ConsumerWidget {
  const AnimalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animals = ref.watch(animalsProvider);
    final properties = ref.watch(propertiesProvider);
    final selectedPropertyId = ref.watch(animalsPropertyFilterProvider);
    final searchQuery = ref.watch(animalsSearchQueryProvider);
    final statusFilter = ref.watch(animalsStatusFilterProvider);
    final reproductiveStatusFilter = ref.watch(
      animalsReproductiveStatusFilterProvider,
    );
    final propertyOptions =
        properties.asData?.value ?? const <PropertySummaryModel>[];
    final propertyById = {
      for (final property in propertyOptions) property.id: property,
    };
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(animalsProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _AnimalsToolbar(
                properties: propertyOptions,
                searchQuery: searchQuery,
                selectedPropertyId: selectedPropertyId,
                statusFilter: statusFilter,
                reproductiveStatusFilter: reproductiveStatusFilter,
                onSearchChanged: (value) {
                  ref.read(animalsSearchQueryProvider.notifier).state = value;
                },
                onPropertyChanged: (value) {
                  ref.read(animalsPropertyFilterProvider.notifier).set(value);
                },
                onStatusChanged: (value) {
                  ref.read(animalsStatusFilterProvider.notifier).state =
                      value ?? AnimalStatusFilter.all;
                },
                onReproductiveStatusChanged: (value) {
                  ref
                          .read(
                            animalsReproductiveStatusFilterProvider.notifier,
                          )
                          .state =
                      value;
                },
                onImport: () =>
                    _importAnimalsCsv(context, ref, propertyOptions),
                onCreate: () =>
                    AnimalDialog.show(context, properties: propertyOptions),
              ),
              const SizedBox(height: 12),
              AsyncValueView<List<AnimalSummaryModel>>(
                value: animals,
                loadingMessage: 'Buscando animais...',
                emptyMessage: 'Nenhum animal cadastrado.',
                isEmpty: (items) => items.isEmpty,
                onRetry: () => ref.invalidate(animalsProvider),
                builder: (items) {
                  final filteredItems = _filterAnimals(
                    items,
                    searchQuery,
                    statusFilter,
                    reproductiveStatusFilter,
                  );

                  final activeAnimals = filteredItems.where((animal) {
                    return animal.status == AnimalStatus.active;
                  }).length;

                  final propertyContext = _propertyFilterContext(
                    selectedPropertyId: selectedPropertyId,
                    propertyById: propertyById,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AnimalsCountSummary(
                        activeAnimals: activeAnimals,
                        propertyContext: propertyContext,
                      ),
                      const SizedBox(height: 8),
                      if (filteredItems.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Center(
                            child: Text(
                              'Nenhum animal encontrado para os filtros atuais.',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        _AnimalsMainContent(
                          animals: filteredItems,
                          propertyNameFor: (animal) {
                            return propertyById[animal.idPropriedade]?.nome ??
                                animal.idExternoPropriedade;
                          },
                          onEdit: (animal) => AnimalDialog.show(
                            context,
                            properties: propertyOptions,
                            animal: animal,
                          ),
                          onInactivate: (animal) =>
                              _confirmInactivate(context, ref, animal),
                          onActivate: (animal) =>
                              _confirmActivate(context, ref, animal),
                          onDelete: (animal) =>
                              _confirmDelete(context, ref, animal),
                          onShowHistory: (animal) => _showAnimalHistory(
                            context,
                            animal,
                            propertyById[animal.idPropriedade]?.nome ??
                                animal.idExternoPropriedade,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimalsToolbar extends StatefulWidget {
  const _AnimalsToolbar({
    required this.properties,
    required this.searchQuery,
    required this.selectedPropertyId,
    required this.statusFilter,
    required this.reproductiveStatusFilter,
    required this.onSearchChanged,
    required this.onPropertyChanged,
    required this.onStatusChanged,
    required this.onReproductiveStatusChanged,
    required this.onImport,
    required this.onCreate,
  });

  final List<PropertySummaryModel> properties;
  final String searchQuery;
  final int? selectedPropertyId;
  final AnimalStatusFilter statusFilter;
  final AnimalReproductiveStatus? reproductiveStatusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int?> onPropertyChanged;
  final ValueChanged<AnimalStatusFilter?> onStatusChanged;
  final ValueChanged<AnimalReproductiveStatus?> onReproductiveStatusChanged;
  final VoidCallback onImport;
  final VoidCallback onCreate;

  @override
  State<_AnimalsToolbar> createState() => _AnimalsToolbarState();
}

class _AnimalsToolbarState extends State<_AnimalsToolbar> {
  bool _filtersOpen = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 700;
        final stacked = constraints.maxWidth < 1120;

        final search = SearchCard(
          value: widget.searchQuery,
          labelText: 'Pesquisar por brinco/ID',
          onChanged: widget.onSearchChanged,
        );

        final propertyFilter = PropertyFilterCard(
          properties: widget.properties,
          selectedPropertyId: widget.selectedPropertyId,
          onChanged: widget.onPropertyChanged,
        );

        final status = AppDropdown<AnimalStatusFilter>(
          value: widget.statusFilter,
          labelText: 'Status',
          onChanged: widget.onStatusChanged,
          options: AnimalStatusFilter.values
              .map((item) => AppDropdownOption(label: item.label, value: item))
              .toList(growable: false),
        );

        final reproductiveStatus = AppDropdown<AnimalReproductiveStatus>(
          value: widget.reproductiveStatusFilter,
          labelText: 'Status reprodutivo',
          nullLabel: 'Todos',
          onChanged: widget.onReproductiveStatusChanged,
          options: [
            const AppDropdownOption<AnimalReproductiveStatus>(
              label: 'Todos',
              value: null,
            ),
            ...AnimalReproductiveStatus.values.map((item) {
              return AppDropdownOption(
                label: item.label,
                value: item,
                suffix: _ReproductiveStatusDot(status: item),
              );
            }),
          ],
        );

        final importButton = Tooltip(
          message: 'Importar CSV',
          child: AppButton(
            outlined: true,
            onPressed: widget.onImport,
            child: const Icon(Icons.upload_file_outlined),
          ),
        );

        final createButton = AppButton(
          text: 'Novo animal',
          icon: const Icon(Icons.add),
          onPressed: widget.onCreate,
        );

        final filterButton = Tooltip(
          message: _filtersOpen ? 'Ocultar filtros' : 'Mostrar filtros',
          child: AppButton(
            outlined: !_filtersOpen,
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

        if (mobile) {
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
              if (_filtersOpen) ...[
                const SizedBox(height: 10),
                propertyFilter,
                const SizedBox(height: 10),
                status,
                const SizedBox(height: 10),
                reproductiveStatus,
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  importButton,
                  const SizedBox(width: 10),
                  Expanded(child: createButton),
                ],
              ),
            ],
          );
        }

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 10),
              propertyFilter,
              const SizedBox(height: 10),
              status,
              const SizedBox(height: 10),
              reproductiveStatus,
              const SizedBox(height: 10),
              Row(
                children: [
                  importButton,
                  const SizedBox(width: 10),
                  Expanded(child: createButton),
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: search),
            const SizedBox(width: 12),
            SizedBox(width: 250, child: propertyFilter),
            const SizedBox(width: 12),
            SizedBox(width: 150, child: status),
            const SizedBox(width: 12),
            SizedBox(width: 190, child: reproductiveStatus),
            const SizedBox(width: 12),
            importButton,
            const SizedBox(width: 12),
            createButton,
          ],
        );
      },
    );
  }
}

List<AnimalSummaryModel> _filterAnimals(
  List<AnimalSummaryModel> items,
  String query,
  AnimalStatusFilter statusFilter,
  AnimalReproductiveStatus? reproductiveStatusFilter,
) {
  final normalizedQuery = query.trim().normalize();

  return items.where((animal) {
    final matchesStatus = switch (statusFilter) {
      AnimalStatusFilter.all => true,
      AnimalStatusFilter.active => animal.status == AnimalStatus.active,
      AnimalStatusFilter.inactive => animal.status != AnimalStatus.active,
    };

    final animalReproductiveStatus = reproductiveStatusFor(animal);

    final matchesReproductiveStatus =
        reproductiveStatusFilter == null ||
        animalReproductiveStatus == reproductiveStatusFilter;

    final searchable =
        '${animal.codigo} ${animal.idExterno} ${animal.categoria} ${animal.sexo ?? ''} '
                '${animalReproductiveStatus.label} ${animal.historicoReprodutivo ?? ''} '
                '${formatDate(animal.dataInseminacao)}'
            .normalize();

    return matchesStatus &&
        matchesReproductiveStatus &&
        (normalizedQuery.isEmpty || searchable.contains(normalizedQuery));
  }).toList();
}

typedef _AnimalCallback = void Function(AnimalSummaryModel animal);
typedef _AnimalPropertyNameFor = String Function(AnimalSummaryModel animal);

enum _AnimalAction { edit, toggleActive, delete }

class _AnimalsCountSummary extends StatelessWidget {
  const _AnimalsCountSummary({
    required this.activeAnimals,
    required this.propertyContext,
  });

  final int activeAnimals;
  final String propertyContext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$activeAnimals ${activeAnimals == 1 ? 'animal ativo' : 'animais ativos'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'em $propertyContext',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimalsMainContent extends StatelessWidget {
  const _AnimalsMainContent({
    required this.animals,
    required this.propertyNameFor,
    required this.onEdit,
    required this.onInactivate,
    required this.onActivate,
    required this.onDelete,
    required this.onShowHistory,
  });

  final List<AnimalSummaryModel> animals;
  final _AnimalPropertyNameFor propertyNameFor;
  final _AnimalCallback onEdit;
  final _AnimalCallback onInactivate;
  final _AnimalCallback onActivate;
  final _AnimalCallback onDelete;
  final _AnimalCallback onShowHistory;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < MOBILE_WIDTH;

    final animalsContent = isMobile
        ? _AnimalsMobileList(
            animals: animals,
            propertyNameFor: propertyNameFor,
            onEdit: onEdit,
            onInactivate: onInactivate,
            onActivate: onActivate,
            onDelete: onDelete,
            onShowHistory: onShowHistory,
          )
        : _AnimalsTable(
            animals: animals,
            propertyNameFor: propertyNameFor,
            onEdit: onEdit,
            onInactivate: onInactivate,
            onActivate: onActivate,
            onDelete: onDelete,
            onShowHistory: onShowHistory,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HerdIndicators(animals: animals),
        const SizedBox(height: 16),
        animalsContent,
      ],
    );
  }
}

class _AnimalsTable extends StatelessWidget {
  const _AnimalsTable({
    required this.animals,
    required this.propertyNameFor,
    required this.onEdit,
    required this.onInactivate,
    required this.onActivate,
    required this.onDelete,
    required this.onShowHistory,
  });

  final List<AnimalSummaryModel> animals;
  final _AnimalPropertyNameFor propertyNameFor;
  final _AnimalCallback onEdit;
  final _AnimalCallback onInactivate;
  final _AnimalCallback onActivate;
  final _AnimalCallback onDelete;
  final _AnimalCallback onShowHistory;

  @override
  Widget build(BuildContext context) {
    return AppTable<AnimalSummaryModel>(
      rows: animals,
      footerLabel: _recordsLabel(animals.length),
      onRowTap: onShowHistory,
      columns: [
        AppTableColumn<AnimalSummaryModel>(
          label: 'Identificação\n(Brinco)',
          mobileLabel: 'Identificação/Brinco',
          flex: 2,
          alignment: Alignment.centerLeft,
          cellBuilder: (context, animal) {
            return _AnimalIdentityHeader(
              animal: animal,
              propertyName: propertyNameFor(animal),
            );
          },
        ),

        AppTableColumn<AnimalSummaryModel>(
          label: 'Raça',
          flex: 3,
          alignment: Alignment.center,
          cellBuilder: (context, animal) {
            return Center(child: _AnimalBreedCell(animal: animal));
          },
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Status\nreprodutivo',
          mobileLabel: 'Status reprodutivo',
          flex: 2,
          alignment: Alignment.center,
          cellBuilder: (context, animal) {
            return Center(
              child: _ReproductiveStatusPill(
                status: reproductiveStatusFor(animal),
              ),
            );
          },
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Último evento',
          flex: 3,
          alignment: Alignment.center,
          cellBuilder: (context, animal) {
            return Center(child: _LastEventCell(animal: animal));
          },
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Ações',
          flex: 1,
          alignment: Alignment.center,
          cellBuilder: (context, animal) {
            return Center(
              child: _AnimalActions(
                animal: animal,
                onEdit: () => onEdit(animal),
                onInactivate: () => onInactivate(animal),
                onActivate: () => onActivate(animal),
                onDelete: () => onDelete(animal),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AnimalsMobileList extends StatelessWidget {
  const _AnimalsMobileList({
    required this.animals,
    required this.propertyNameFor,
    required this.onEdit,
    required this.onInactivate,
    required this.onActivate,
    required this.onDelete,
    required this.onShowHistory,
  });

  final List<AnimalSummaryModel> animals;
  final _AnimalPropertyNameFor propertyNameFor;
  final _AnimalCallback onEdit;
  final _AnimalCallback onInactivate;
  final _AnimalCallback onActivate;
  final _AnimalCallback onDelete;
  final _AnimalCallback onShowHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final animal in animals) ...[
          _AnimalMobileCard(
            animal: animal,
            propertyName: propertyNameFor(animal),
            onEdit: () => onEdit(animal),
            onInactivate: () => onInactivate(animal),
            onActivate: () => onActivate(animal),
            onDelete: () => onDelete(animal),
            onTap: () => onShowHistory(animal),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AnimalMobileCard extends StatelessWidget {
  const _AnimalMobileCard({
    required this.animal,
    required this.propertyName,
    required this.onEdit,
    required this.onInactivate,
    required this.onActivate,
    required this.onDelete,
    required this.onTap,
  });

  final AnimalSummaryModel animal;
  final String propertyName;
  final VoidCallback onEdit;
  final VoidCallback onInactivate;
  final VoidCallback onActivate;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final reproductiveStatus = reproductiveStatusFor(animal);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AppCard(
          padding: const EdgeInsets.all(12),
          borderRadius: 16,
          borderColor: colorScheme.outlineVariant.withValues(alpha: 0.8),
          shadow: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _animalCodeLabel(animal.codigo),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _ReproductiveStatusPill(
                              status: reproductiveStatus,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _AnimalActions(
                          animal: animal,
                          onEdit: onEdit,
                          onInactivate: onInactivate,
                          onActivate: onActivate,
                          onDelete: onDelete,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MiniBadge(
                          label: animal.categoria.isEmpty
                              ? 'Categoria --'
                              : animal.categoria,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      propertyName.isEmpty
                          ? 'Propriedade não informada'
                          : propertyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lactação: ${animal.numeroLactacao}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (animal.dataInseminacao != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Inseminação: ${formatDate(animal.dataInseminacao)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (animal.historicoReprodutivo?.trim().isNotEmpty ==
                        true) ...[
                      const SizedBox(height: 4),
                      Text(
                        animal.historicoReprodutivo!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
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

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AnimalIdentityHeader extends StatelessWidget {
  const _AnimalIdentityHeader({
    required this.animal,
    required this.propertyName,
  });

  final AnimalSummaryModel animal;
  final String propertyName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          animal.codigo.isEmpty ? '--' : animal.codigo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          propertyName.isEmpty ? 'Propriedade não informada' : propertyName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AnimalBreedCell extends StatelessWidget {
  const _AnimalBreedCell({required this.animal});

  final AnimalSummaryModel animal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          animal.categoria.isEmpty ? '--' : animal.categoria,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sexo: ${animal.sexo ?? '--'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          'Nascimento: ${formatDate(animal.dataNascimento)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          'Lactação: ${animal.numeroLactacao}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ReproductiveStatusDot extends StatelessWidget {
  const _ReproductiveStatusDot({required this.status});

  final AnimalReproductiveStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = _reproductiveStatusColors(context, status);

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: colors.foreground,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _ReproductiveStatusPill extends StatelessWidget {
  const _ReproductiveStatusPill({required this.status});

  final AnimalReproductiveStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = _reproductiveStatusColors(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: colors.foreground),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              status.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LastEventCell extends StatelessWidget {
  const _LastEventCell({required this.animal});

  final AnimalSummaryModel animal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lastBirth = animal.dataUltimoParto;
    final inseminationDate = animal.dataInseminacao;

    if (lastBirth == null && inseminationDate == null) {
      return Text(
        animal.historicoReprodutivo?.trim().isNotEmpty == true
            ? 'Histórico informado'
            : 'Sem evento',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lastBirth != null)
          Text(
            'Parto em ${formatDate(lastBirth)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        if (inseminationDate != null) ...[
          if (lastBirth != null) const SizedBox(height: 4),
          Text(
            'IA em ${formatDate(inseminationDate)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (animal.diasEmLactacao != null) ...[
          const SizedBox(height: 4),
          Text(
            '${animal.diasEmLactacao} dias em lactação',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _AnimalActions extends StatelessWidget {
  const _AnimalActions({
    required this.animal,
    required this.onEdit,
    required this.onInactivate,
    required this.onActivate,
    required this.onDelete,
  });

  final AnimalSummaryModel animal;
  final VoidCallback onEdit;
  final VoidCallback onInactivate;
  final VoidCallback onActivate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isInactive = animal.status == AnimalStatus.inactive;
    final archiveTooltip = isInactive ? 'Ativar' : 'Inativar';
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<_AnimalAction>(
      tooltip: 'Ações',
      icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
      onSelected: (action) {
        switch (action) {
          case _AnimalAction.edit:
            onEdit();
          case _AnimalAction.toggleActive:
            isInactive ? onActivate() : onInactivate();
          case _AnimalAction.delete:
            onDelete();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _AnimalAction.edit,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_outlined),
            title: Text('Editar'),
          ),
        ),
        PopupMenuItem(
          value: _AnimalAction.toggleActive,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isInactive ? Icons.unarchive_outlined : Icons.archive_outlined,
            ),
            title: Text(archiveTooltip),
          ),
        ),
        PopupMenuItem(
          value: _AnimalAction.delete,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline, color: colorScheme.error),
            title: Text('Excluir', style: TextStyle(color: colorScheme.error)),
          ),
        ),
      ],
    );
  }
}

Future<void> _showAnimalHistory(
  BuildContext context,
  AnimalSummaryModel animal,
  String propertyName,
) {
  return AppDialog.show<void>(
    context: context,
    title: 'Histórico do animal',
    subtitle: _animalCodeLabel(animal.codigo),
    width: 900,
    fullscreenOnMobile: true,
    useInternalScroll: true,
    content: _AnimalHistoryDialogContent(
      animal: animal,
      propertyName: propertyName,
    ),
  );
}

class _AnimalHistoryDialogContent extends ConsumerWidget {
  const _AnimalHistoryDialogContent({
    required this.animal,
    required this.propertyName,
  });

  final AnimalSummaryModel animal;
  final String propertyName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyProvider = _animalHistoryProvider(animal);
    final history = ref.watch(historyProvider);

    return history.when(
      data: (data) =>
          _AnimalHistoryBody(data: data, propertyName: propertyName),
      loading: () => const _AnimalHistoryLoading(),
      error: (error, stackTrace) {
        return _AnimalHistoryLoadError(
          onRetry: () => ref.invalidate(historyProvider),
        );
      },
    );
  }
}

class _AnimalHistoryBody extends StatelessWidget {
  const _AnimalHistoryBody({required this.data, required this.propertyName});

  final _AnimalHistoryData data;
  final String propertyName;

  @override
  Widget build(BuildContext context) {
    final animal = data.animal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _AnimalHistoryHeader(animal: animal, propertyName: propertyName),
        const SizedBox(height: 12),
        _AnimalHistoryMetricGrid(animal: animal),
        const SizedBox(height: 18),
        _AnimalHistorySection(
          icon: Icons.insights_outlined,
          title: 'Histórico produtivo',
          child: _ProductiveHistoryPanel(animal: animal),
        ),
        const SizedBox(height: 18),
        _AnimalHistorySection(
          icon: Icons.event_available_outlined,
          title: 'Eventos registrados',
          count: data.events.length,
          child: _AnimalEventHistoryList(events: data.events),
        ),
        const SizedBox(height: 18),
        _AnimalHistorySection(
          icon: Icons.assignment_outlined,
          title: 'Visitas',
          count: data.visits.length,
          child: _AnimalVisitHistoryList(records: data.visits),
        ),
        const SizedBox(height: 18),
        _AnimalHistorySection(
          icon: Icons.sync_alt_outlined,
          title: 'Alterações e movimentações',
          child: _AnimalMovementHistoryPanel(
            animal: animal,
            propertyName: propertyName,
          ),
        ),
      ],
    );
  }
}

class _AnimalHistoryHeader extends StatelessWidget {
  const _AnimalHistoryHeader({
    required this.animal,
    required this.propertyName,
  });

  final AnimalSummaryModel animal;
  final String propertyName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      shadow: false,
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.42,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.pets_outlined, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _animalCodeLabel(animal.codigo),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  propertyName.trim().isEmpty
                      ? 'Propriedade não informada'
                      : propertyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _ReproductiveStatusPill(status: reproductiveStatusFor(animal)),
        ],
      ),
    );
  }
}

class _AnimalHistoryMetricGrid extends StatelessWidget {
  const _AnimalHistoryMetricGrid({required this.animal});

  final AnimalSummaryModel animal;

  @override
  Widget build(BuildContext context) {
    final items = [
      _HistoryInfoItem(
        label: 'Categoria',
        value: _valueOrDash(animal.categoria),
      ),
      _HistoryInfoItem(
        label: 'Lactações',
        value: formatInteger(animal.numeroLactacao),
      ),
      _HistoryInfoItem(
        label: 'Último parto',
        value: formatDate(animal.dataUltimoParto),
      ),
      _HistoryInfoItem(
        label: 'Última IA',
        value: formatDate(animal.dataInseminacao),
      ),
      _HistoryInfoItem(
        label: 'DEL',
        value: animal.diasEmLactacao == null
            ? '--'
            : '${formatInteger(animal.diasEmLactacao!)} dias',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 620 ? 2 : 4;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _HistoryInfoTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _HistoryInfoTile extends StatelessWidget {
  const _HistoryInfoTile({required this.item});

  final _HistoryInfoItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimalHistorySection extends StatelessWidget {
  const _AnimalHistorySection({
    required this.icon,
    required this.title,
    required this.child,
    this.count,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (count != null) _MiniBadge(label: formatInteger(count!)),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _ProductiveHistoryPanel extends StatelessWidget {
  const _ProductiveHistoryPanel({required this.animal});

  final AnimalSummaryModel animal;

  @override
  Widget build(BuildContext context) {
    final history = animal.historicoReprodutivo?.trim();
    final details = [
      _HistoryDetail(
        label: 'Nascimento',
        value: formatDate(animal.dataNascimento),
      ),
      _HistoryDetail(label: 'Sexo', value: _valueOrDash(animal.sexo)),
      _HistoryDetail(label: 'Status atual', value: animal.status.label),
      _HistoryDetail(
        label: 'Status reprodutivo',
        value: reproductiveStatusFor(animal).label,
      ),
    ];

    return _HistoryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < details.length; index++) ...[
            _HistoryDetailRow(detail: details[index]),
            if (index < details.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          Divider(color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            history?.isNotEmpty == true
                ? history!
                : 'Sem histórico produtivo ou reprodutivo resumido.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimalEventHistoryList extends StatelessWidget {
  const _AnimalEventHistoryList({required this.events});

  final List<AnimalHistoryEventModel> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const _HistoryEmptyPanel(
        message: 'Nenhum evento registrado para este animal.',
      );
    }

    return Column(
      children: [
        for (var index = 0; index < events.length; index++) ...[
          _HistoryTimelineItem(
            icon: _eventTypeIcon(events[index].tipo),
            title: _eventTypeLabel(events[index].tipo),
            date: events[index].dataEvento,
            details: _eventDetails(events[index]),
          ),
          if (index < events.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AnimalVisitHistoryList extends StatelessWidget {
  const _AnimalVisitHistoryList({required this.records});

  final List<_AnimalVisitHistoryRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const _HistoryEmptyPanel(
        message: 'Nenhuma visita com dados deste animal.',
      );
    }

    return Column(
      children: [
        for (var index = 0; index < records.length; index++) ...[
          _HistoryTimelineItem(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Visita técnica',
            date: records[index].visit.dataVisita,
            subtitle: records[index].visit.observacoes,
            details: _visitDetails(records[index].entry),
          ),
          if (index < records.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AnimalMovementHistoryPanel extends StatelessWidget {
  const _AnimalMovementHistoryPanel({
    required this.animal,
    required this.propertyName,
  });

  final AnimalSummaryModel animal;
  final String propertyName;

  @override
  Widget build(BuildContext context) {
    // TODO(api): quando o endpoint/model de historico completo existir,
    // renderizar aqui movimentacoes reais de propriedade/lote, alteracoes de
    // status e auditoria. Hoje estes dados estao temporariamente derivados do
    // estado atual do AnimalSummaryModel.
    return _HistoryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HistoryDetailRow(
            detail: _HistoryDetail(
              label: 'Propriedade atual',
              value: propertyName.trim().isEmpty
                  ? 'Não informada'
                  : propertyName,
            ),
          ),
          const SizedBox(height: 10),
          _HistoryDetailRow(
            detail: _HistoryDetail(
              label: 'Status atual',
              value: animal.status.label,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sem movimentações históricas registradas para este animal.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTimelineItem extends StatelessWidget {
  const _HistoryTimelineItem({
    required this.icon,
    required this.title,
    required this.date,
    required this.details,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final DateTime? date;
  final String? subtitle;
  final List<_HistoryDetail> details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cleanSubtitle = subtitle?.trim();

    return _HistoryPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      formatDate(date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (cleanSubtitle?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    cleanSubtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final detail in details)
                        _HistoryDetailChip(detail: detail),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.28)),
      ),
      child: child,
    );
  }
}

class _HistoryDetailRow extends StatelessWidget {
  const _HistoryDetailRow({required this.detail});

  final _HistoryDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            detail.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            detail.value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryDetailChip extends StatelessWidget {
  const _HistoryDetailChip({required this.detail});

  final _HistoryDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.15,
          ),
          children: [
            TextSpan(
              text: '${detail.label}: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(
              text: detail.value,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryEmptyPanel extends StatelessWidget {
  const _HistoryEmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _HistoryPanel(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _AnimalHistoryLoading extends StatelessWidget {
  const _AnimalHistoryLoading();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            'Carregando histórico...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimalHistoryLoadError extends StatelessWidget {
  const _AnimalHistoryLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _HistoryPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Não foi possível carregar o histórico do animal.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          AppButton(
            text: 'Tentar novamente',
            outlined: true,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _HerdIndicators extends StatelessWidget {
  const _HerdIndicators({required this.animals});

  final List<AnimalSummaryModel> animals;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < MOBILE_WIDTH;

    final statusCounts = _reproductiveStatusCounts(animals);
    final knownStatusCount = statusCounts.entries
        .where((entry) => entry.key != AnimalReproductiveStatus.pending)
        .fold<int>(0, (total, entry) => total + entry.value);

    final pregnancyRate = knownStatusCount == 0
        ? null
        : statusCounts[AnimalReproductiveStatus.pregnant]! / knownStatusCount;

    final pregnancyCard = _HerdMetricCard(
      title: 'Taxa de prenhez',
      value: pregnancyRate == null ? '--' : formatPercent(pregnancyRate),
      subtitle: pregnancyRate == null ? 'Aguardando' : 'Status visual',
      icon: Icons.monitor_heart_outlined,
      status: AnimalReproductiveStatus.pregnant,
    );

    const birthIntervalCard = _HerdMetricCard(
      title: 'Intervalo partos',
      value: '--',
      subtitle: 'Sem dados',
      icon: Icons.event_repeat_outlined,
      status: AnimalReproductiveStatus.pending,
      muted: true,
    );

    final pendingCard = _HerdMetricCard(
      title: 'Pendentes',
      value: statusCounts[AnimalReproductiveStatus.pending].toString(),
      subtitle: 'Sem backend',
      icon: Icons.pending_actions_outlined,
      status: AnimalReproductiveStatus.pending,
      muted: true,
    );

    final statusCard = _HerdStatusCard(
      counts: statusCounts,
      total: animals.length,
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: pregnancyCard),
                const SizedBox(width: 8),
                Expanded(child: birthIntervalCard),
                const SizedBox(width: 8),
                Expanded(child: pendingCard),
              ],
            ),
          ),
          const SizedBox(height: 12),
          statusCard,
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 2, child: pregnancyCard),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: birthIntervalCard),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: pendingCard),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: statusCard),
        ],
      ),
    );
  }
}

class _HerdMetricCard extends StatelessWidget {
  const _HerdMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.status,
    this.muted = false,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final AnimalReproductiveStatus status;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColors = _reproductiveStatusColors(context, status);
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < MOBILE_WIDTH;

    final foreground = muted
        ? colorScheme.onSurfaceVariant
        : statusColors.foreground;

    return AppCard(
      borderRadius: 16,
      padding: EdgeInsets.all(compact ? 10 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 26 : 30,
                height: compact ? 26 : 30,
                decoration: BoxDecoration(
                  color: statusColors.background,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: foreground, size: compact ? 15 : 17),
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: compact ? 2 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: compact ? 9.5 : null,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: compact
                      ? theme.textTheme.titleMedium?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                        )
                      : theme.textTheme.titleLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                        ),
                ),
                if (title.toLowerCase().contains('intervalo'))
                  TextSpan(
                    text: ' dias',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: compact ? 2 : 3),
          Text(
            subtitle,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: compact ? 10 : null,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _HerdStatusCard extends StatelessWidget {
  const _HerdStatusCard({required this.counts, required this.total});

  final Map<AnimalReproductiveStatus, int> counts;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STATUS DO REBANHO',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (total == 0)
            Text(
              'Sem registros no filtro atual.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in AnimalReproductiveStatus.values)
                  _StatusCountTile(
                    status: status,
                    count: counts[status] ?? 0,
                    total: total,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatusCountTile extends StatelessWidget {
  const _StatusCountTile({
    required this.status,
    required this.count,
    required this.total,
  });

  final AnimalReproductiveStatus status;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _reproductiveStatusColors(context, status);
    final width = MediaQuery.sizeOf(context).width < 420 ? 78.0 : 70.0;
    final ratio = total == 0 ? 0.0 : count / total;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 4,
              color: colors.foreground,
              backgroundColor: colors.background,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimalHistoryData {
  const _AnimalHistoryData({
    required this.animal,
    required this.events,
    required this.visits,
  });

  final AnimalSummaryModel animal;
  final List<AnimalHistoryEventModel> events;
  final List<_AnimalVisitHistoryRecord> visits;
}

class _AnimalVisitHistoryRecord {
  const _AnimalVisitHistoryRecord({required this.visit, required this.entry});

  final VisitSummaryModel visit;
  final VisitAnimalEntryModel entry;
}

class _HistoryInfoItem {
  const _HistoryInfoItem({required this.label, required this.value});

  final String label;
  final String value;
}

class _HistoryDetail {
  const _HistoryDetail({required this.label, required this.value});

  final String label;
  final String value;
}

bool _visitBelongsToAnimalProperty(
  VisitSummaryModel visit,
  AnimalSummaryModel animal,
) {
  if (animal.idPropriedade > 0 && visit.idPropriedade == animal.idPropriedade) {
    return true;
  }

  final animalExternalProperty = animal.idExternoPropriedade.trim();
  return animalExternalProperty.isNotEmpty &&
      visit.idExternoPropriedade.trim() == animalExternalProperty;
}

Iterable<_AnimalVisitHistoryRecord> _visitRecordsForAnimal(
  VisitSummaryModel visit,
  AnimalSummaryModel animal,
) {
  return visit.animais
      .where((entry) => _visitEntryBelongsToAnimal(entry, animal))
      .map((entry) => _AnimalVisitHistoryRecord(visit: visit, entry: entry));
}

bool _visitEntryBelongsToAnimal(
  VisitAnimalEntryModel entry,
  AnimalSummaryModel animal,
) {
  if (animal.id > 0 && entry.animalId == animal.id) {
    return true;
  }

  final externalId = animal.idExterno.trim();
  if (externalId.isNotEmpty && entry.animalIdExterno.trim() == externalId) {
    return true;
  }

  final code = animal.codigo.trim();
  return code.isNotEmpty && entry.animalCodigo.trim() == code;
}

int _compareVisitRecordsDesc(
  _AnimalVisitHistoryRecord a,
  _AnimalVisitHistoryRecord b,
) {
  return _compareNullableDatesDesc(a.visit.dataVisita, b.visit.dataVisita);
}

int _compareHistoryEventsDesc(
  AnimalHistoryEventModel a,
  AnimalHistoryEventModel b,
) {
  return _compareNullableDatesDesc(a.dataEvento, b.dataEvento);
}

int _compareNullableDatesDesc(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return b.compareTo(a);
}

String _eventTypeLabel(String value) {
  return switch (value) {
    'INSEMINATION' => 'Inseminação',
    'PREGNANCY_DIAGNOSIS' => 'Diagnóstico de prenhez',
    'CALVING' => 'Parto',
    'DRY_OFF' => 'Secagem',
    'GESTATIONAL_LOSS' => 'Perda gestacional',
    _ => _valueOrDash(value),
  };
}

IconData _eventTypeIcon(String value) {
  return switch (value) {
    'INSEMINATION' => Icons.science_outlined,
    'PREGNANCY_DIAGNOSIS' => Icons.monitor_heart_outlined,
    'CALVING' => Icons.child_friendly_outlined,
    'DRY_OFF' => Icons.water_drop_outlined,
    'GESTATIONAL_LOSS' => Icons.warning_amber_outlined,
    _ => Icons.event_outlined,
  };
}

List<_HistoryDetail> _eventDetails(AnimalHistoryEventModel event) {
  final details = <_HistoryDetail>[];

  if (event.dataPrevistaParto != null) {
    details.add(
      _HistoryDetail(
        label: 'Previsão parto',
        value: formatDate(event.dataPrevistaParto),
      ),
    );
  }

  if (event.prenhezConfirmada != null) {
    details.add(
      _HistoryDetail(
        label: 'Prenhez',
        value: event.prenhezConfirmada! ? 'Confirmada' : 'Não confirmada',
      ),
    );
  }

  _addTextDetail(details, 'Observação', event.observacoes);
  return details;
}

List<_HistoryDetail> _visitDetails(VisitAnimalEntryModel entry) {
  final details = <_HistoryDetail>[];

  _addTextDetail(details, 'Produtiva', entry.situacaoProdutiva);
  _addTextDetail(details, 'Reprodutiva', entry.situacaoReprodutiva);
  _addTextDetail(details, 'Decisão', entry.decisao);
  _addTextDetail(details, 'Diagnóstico', entry.diagnostico);

  if (entry.dataUltimaIa != null) {
    details.add(
      _HistoryDetail(label: 'Última IA', value: formatDate(entry.dataUltimaIa)),
    );
  }

  if (entry.numeroIaRecebida != null) {
    details.add(
      _HistoryDetail(
        label: 'IAs',
        value: formatInteger(entry.numeroIaRecebida!),
      ),
    );
  }

  if (entry.diasPrenhez != null) {
    details.add(
      _HistoryDetail(
        label: 'Prenhez',
        value: '${formatInteger(entry.diasPrenhez!)} dias',
      ),
    );
  }

  if (entry.del != null) {
    details.add(
      _HistoryDetail(label: 'DEL', value: '${formatInteger(entry.del!)} dias'),
    );
  }

  if (entry.previsaoSecagem != null) {
    details.add(
      _HistoryDetail(
        label: 'Prev. secagem',
        value: formatDate(entry.previsaoSecagem),
      ),
    );
  }

  if (entry.previsaoParto != null) {
    details.add(
      _HistoryDetail(
        label: 'Prev. parto',
        value: formatDate(entry.previsaoParto),
      ),
    );
  }

  return details;
}

void _addTextDetail(List<_HistoryDetail> details, String label, String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return;
  details.add(_HistoryDetail(label: label, value: text));
}

String _valueOrDash(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return '--';
  return text;
}

String _propertyFilterContext({
  required int? selectedPropertyId,
  required Map<int, PropertySummaryModel> propertyById,
}) {
  if (selectedPropertyId == null) return 'todas as propriedades';

  final propertyName = propertyById[selectedPropertyId]?.nome.trim();

  if (propertyName == null || propertyName.isEmpty) {
    return 'propriedade selecionada';
  }

  return propertyName;
}

String _recordsLabel(int count) {
  return '$count ${count == 1 ? 'registro' : 'registros'} no filtro atual';
}

String _animalCodeLabel(String code) {
  if (code.trim().isEmpty) return '--';
  if (code.trim().startsWith('#')) return code.trim();
  return '#${code.trim()}';
}

AnimalReproductiveStatus reproductiveStatusFor(AnimalSummaryModel animal) {
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

Map<AnimalReproductiveStatus, int> _reproductiveStatusCounts(
  List<AnimalSummaryModel> animals,
) {
  final counts = {
    for (final status in AnimalReproductiveStatus.values) status: 0,
  };

  for (final animal in animals) {
    final status = reproductiveStatusFor(animal);
    counts[status] = (counts[status] ?? 0) + 1;
  }

  return counts;
}

_ReproductiveStatusColors _reproductiveStatusColors(
  BuildContext context,
  AnimalReproductiveStatus status,
) {
  final colorScheme = Theme.of(context).colorScheme;

  return switch (status) {
    AnimalReproductiveStatus.pregnant => const _ReproductiveStatusColors(
      background: Color(0xFFDFF8EA),
      border: Color(0xFFB9E9CF),
      foreground: Color(0xFF0D6B42),
    ),
    AnimalReproductiveStatus.empty => const _ReproductiveStatusColors(
      background: Color(0xFFFFE3EA),
      border: Color(0xFFF7B8C9),
      foreground: Color(0xFFB4234A),
    ),
    AnimalReproductiveStatus.inseminated => const _ReproductiveStatusColors(
      background: Color(0xFFE0F2FE),
      border: Color(0xFFB9E1FA),
      foreground: Color(0xFF0369A1),
    ),
    AnimalReproductiveStatus.dry => const _ReproductiveStatusColors(
      background: Color(0xFFFFF0C2),
      border: Color(0xFFEFD58C),
      foreground: Color(0xFF8A5C00),
    ),
    AnimalReproductiveStatus.pending => _ReproductiveStatusColors(
      background: colorScheme.surfaceContainerHighest,
      border: colorScheme.outline.withValues(alpha: 0.55),
      foreground: colorScheme.onSurfaceVariant,
    ),
  };
}

class _ReproductiveStatusColors {
  const _ReproductiveStatusColors({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}

Future<void> _importAnimalsCsv(
  BuildContext context,
  WidgetRef ref,
  List<PropertySummaryModel> properties,
) async {
  final navigator = Navigator.of(context);

  if (properties.isEmpty) {
    showAppWarning('Cadastre ou carregue propriedades antes de importar.');
    return;
  }

  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['csv'],
    withData: true,
  );

  if (result == null || result.files.isEmpty) return;

  final bytes = result.files.single.bytes;
  if (bytes == null) {
    if (!context.mounted) return;
    showAppError('Não foi possível ler o arquivo CSV.');
    return;
  }

  final content = utf8.decode(bytes, allowMalformed: true);
  final importResult = const AnimalsCsvImporter().parse(
    content: content,
    properties: properties,
  );

  if (!context.mounted) return;

  await AppDialog.show<void>(
    context: context,
    title: 'Importar animais',
    width: 760,
    useInternalScroll: true,
    content: _CsvPreview(importResult: importResult),
    actions: [
      AppButton(
        text: 'Cancelar',
        outlined: true,
        onPressed: navigator.maybePop,
      ),
      AppButton(
        text: 'Importar ${importResult.animals.length}',
        disabled: importResult.animals.isEmpty,
        onPressed: () async {
          await ref
              .read(animalsControllerProvider)
              .importAnimals(importResult.animals);
          if (!context.mounted) return;
          await navigator.maybePop();
          showAppSuccess(
            '${importResult.animals.length} animais importados localmente.',
          );
        },
      ),
    ],
  );
}

Future<void> _confirmInactivate(
  BuildContext context,
  WidgetRef ref,
  AnimalSummaryModel animal,
) {
  return AppDialog.show<void>(
    context: context,
    title: 'Inativar animal',
    content: Text('Deseja inativar ${animal.codigo}?'),
    confirmText: 'Inativar',
    cancelText: 'Cancelar',
    onConfirm: () async {
      final navigator = Navigator.of(context, rootNavigator: true);
      try {
        await ref.read(animalsControllerProvider).inactivate(animal.id);
        if (context.mounted) {
          await navigator.maybePop();
          showAppSuccess('Animal inativado com sucesso.');
        }
      } catch (error) {
        showAppError(error);
      }
    },
  );
}

Future<void> _confirmActivate(
  BuildContext context,
  WidgetRef ref,
  AnimalSummaryModel animal,
) {
  return AppDialog.show<void>(
    context: context,
    title: 'Ativar animal',
    content: Text('Deseja ativar ${animal.codigo}?'),
    confirmText: 'Ativar',
    cancelText: 'Cancelar',
    onConfirm: () async {
      final navigator = Navigator.of(context, rootNavigator: true);
      try {
        await ref.read(animalsControllerProvider).activate(animal.id);
        if (context.mounted) {
          await navigator.maybePop();
          showAppSuccess('Animal ativado com sucesso.');
        }
      } catch (error) {
        showAppError(error);
      }
    },
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  AnimalSummaryModel animal,
) {
  return AppDialog.show<void>(
    context: context,
    title: 'Excluir animal',
    content: Text('Deseja excluir ${animal.codigo} desta sessão?'),
    confirmText: 'Excluir',
    cancelText: 'Cancelar',
    onConfirm: () async {
      final navigator = Navigator.of(context, rootNavigator: true);
      try {
        await ref.read(animalsControllerProvider).delete(animal.id);
        if (context.mounted) {
          await navigator.maybePop();
          showAppSuccess('Animal excluído com sucesso.');
        }
      } catch (error) {
        showAppError(error);
      }
    },
  );
}

class _CsvPreview extends StatelessWidget {
  const _CsvPreview({required this.importResult});

  final AnimalCsvImportResult importResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final validItems = importResult.animals.take(8).toList(growable: false);
    final errors = importResult.errors.take(8).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${importResult.animals.length} registros válidos encontrados.',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (validItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final animal in validItems)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.pets),
              title: Text(animal.codigo),
              subtitle: Text(
                '${animal.categoria} - ${animal.sexo ?? '--'} - ${animal.status.label}',
              ),
            ),
        ],
        if (importResult.animals.length > validItems.length)
          Text(
            'Mais ${importResult.animals.length - validItems.length} registros válidos.',
            style: theme.textTheme.bodySmall,
          ),
        if (errors.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '${importResult.errors.length} linhas com erro',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          for (final error in errors)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Linha ${error.line}: ${error.message}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
