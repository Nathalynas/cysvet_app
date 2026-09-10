import 'package:cysvet_app/app/theme.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../app/app_shell.dart';
import '../../../core/presentation/async_value_view.dart';
import '../../../core/utils/formatters.dart';
import '../../indicators/indicador_reprodutivo_calculator.dart';
import '../../properties/application/properties_provider.dart';
import '../../properties/domain/property_summary_model.dart';
import '../application/animals_provider.dart';
import '../domain/animal_summary_model.dart';
import 'animal_dialog.dart';
import 'animal_excel_import_dialog.dart';
import 'animal_history_dialog.dart';

final animalsSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

final animalsStatusFilterProvider =
    StateProvider.autoDispose<AnimalStatusFilter>((ref) {
      return AnimalStatusFilter.active;
    });

final animalsReproductiveStatusFilterProvider =
    StateProvider.autoDispose<AnimalReproductiveStatus?>((ref) => null);

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
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              PageTitle(
                title: 'Animais',
                subtitle:
                    'Consulte e organize os animais vinculados às propriedades.',
                headerButton: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    AppButton(
                      text: 'Importar Excel',
                      outlined: true,
                      height: 40,
                      borderRadius: 10,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.surface,
                      borderColor: theme.colorScheme.outline.withValues(
                        alpha: 0.75,
                      ),
                      icon: const Icon(Icons.table_chart_outlined, size: 18),
                      onPressed: () =>
                          _importAnimalsExcel(context, ref, propertyOptions),
                    ),
                    AppButton(
                      text: 'Novo animal',
                      height: 40,
                      borderRadius: 10,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () => AnimalDialog.show(
                        context,
                        properties: propertyOptions,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: PageTitle.contentPadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AnimalsToolbar(
                      properties: propertyOptions,
                      searchQuery: searchQuery,
                      selectedPropertyId: selectedPropertyId,
                      statusFilter: statusFilter,
                      reproductiveStatusFilter: reproductiveStatusFilter,
                      onSearchChanged: (value) {
                        ref.read(animalsSearchQueryProvider.notifier).state =
                            value;
                      },
                      onPropertyChanged: (value) {
                        ref
                            .read(animalsPropertyFilterProvider.notifier)
                            .set(value);
                      },
                      onStatusChanged: (value) {
                        ref.read(animalsStatusFilterProvider.notifier).state =
                            value ?? AnimalStatusFilter.all;
                      },
                      onReproductiveStatusChanged: (value) {
                        ref
                                .read(
                                  animalsReproductiveStatusFilterProvider
                                      .notifier,
                                )
                                .state =
                            value;
                      },
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
                                  return propertyById[animal.idPropriedade]
                                          ?.nome ??
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
                                onShowHistory: (animal) =>
                                    AnimalHistoryDialog.show(
                                      context: context,
                                      animal: animal,
                                      propertyName:
                                          propertyById[animal.idPropriedade]
                                              ?.nome ??
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
            ...AnimalReproductiveStatus.editableValues.map((item) {
              return AppDropdownOption(
                label: item.label,
                value: item,
                suffix: _ReproductiveStatusDot(status: item),
              );
            }),
          ],
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
        '${animal.codigo} ${animal.idExterno} ${animal.touroIa ?? ''} '
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
          label: 'Touro IA',
          flex: 2,
          alignment: Alignment.center,
          cellBuilder: (context, animal) {
            return Center(child: _AnimalIaBullCell(animal: animal));
          },
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Status\nreprodutivo',
          mobileLabel: 'Status reprodutivo',
          flex: 1,
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
          flex: 2,
          alignment: Alignment.center,
          cellBuilder: (context, animal) {
            return Center(child: _LastEventCell(animal: animal));
          },
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Ações',
          flex: 2,
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
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        hoverColor: colorScheme.primary.withValues(alpha: 0.045),
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        child: AppCard(
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.all(12),
          borderRadius: 16,
          borderColor: colorScheme.outlineVariant.withValues(alpha: 0.8),
          shadow: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.primary2Color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      MdiIcons.cow,
                      size: 24,
                      color: AppTheme.primary2Color,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _animalCodeLabel(animal.codigo),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                          ),
                        ),

                        const SizedBox(height: 3),

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
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  SizedBox(
                    height: 48,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _ReproductiveStatusPill(status: reproductiveStatus),

                        const SizedBox(width: 2),

                        _AnimalActionsMenu(
                          animal: animal,
                          onEdit: onEdit,
                          onInactivate: onInactivate,
                          onActivate: onActivate,
                          onDelete: onDelete,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _AnimalIaBullCell(animal: animal)),

                  const SizedBox(width: 16),

                  Expanded(child: _LastEventCell(animal: animal)),
                ],
              ),
            ],
          ),
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
    final primary2 = AppTheme.primary2Color;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary2.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(MdiIcons.cow, size: 25, color: primary2),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _animalCodeLabel(animal.codigo),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                propertyName.isEmpty
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
      ],
    );
  }
}

class _AnimalIaBullCell extends StatelessWidget {
  const _AnimalIaBullCell({required this.animal});

  final AnimalSummaryModel animal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          animal.touroIa?.trim().isEmpty ?? true ? '--' : animal.touroIa!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
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

enum _AnimalMobileAction { edit, toggleActive, delete }

class _AnimalActionsMenu extends StatelessWidget {
  const _AnimalActionsMenu({
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
    final colorScheme = Theme.of(context).colorScheme;
    final isInactive = animal.status == AnimalStatus.inactive;

    return PopupMenuButton<_AnimalMobileAction>(
      tooltip: 'Ações',
      padding: EdgeInsets.zero,
      iconSize: 22,
      icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
      onSelected: (action) {
        switch (action) {
          case _AnimalMobileAction.edit:
            onEdit();
            break;

          case _AnimalMobileAction.toggleActive:
            isInactive ? onActivate() : onInactivate();
            break;

          case _AnimalMobileAction.delete:
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _AnimalMobileAction.edit,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_outlined),
            title: Text('Editar'),
          ),
        ),

        PopupMenuItem(
          value: _AnimalMobileAction.toggleActive,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isInactive ? Icons.unarchive_outlined : Icons.archive_outlined,
            ),
            title: Text(isInactive ? 'Ativar' : 'Inativar'),
          ),
        ),

        PopupMenuItem(
          value: _AnimalMobileAction.delete,
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
    final colorScheme = Theme.of(context).colorScheme;
    final isInactive = animal.status == AnimalStatus.inactive;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: [
        _AnimalActionIconButton(
          tooltip: 'Editar',
          icon: Icons.edit_outlined,
          onPressed: onEdit,
        ),

        _AnimalActionIconButton(
          tooltip: isInactive ? 'Ativar' : 'Inativar',
          icon: isInactive ? Icons.unarchive_outlined : Icons.archive_outlined,
          onPressed: isInactive ? onActivate : onInactivate,
        ),

        _AnimalActionIconButton(
          tooltip: 'Excluir',
          icon: Icons.delete_outline,
          color: colorScheme.error,
          onPressed: onDelete,
        ),
      ],
    );
  }
}

class _AnimalActionIconButton extends StatelessWidget {
  const _AnimalActionIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return Tooltip(
      message: tooltip,
      child: AppButton(
        outlined: true,
        width: 36,
        height: 36,
        padding: EdgeInsets.zero,
        color: effectiveColor,
        textColor: effectiveColor,
        borderColor: Colors.transparent,
        shadow: false,
        onPressed: onPressed,
        child: Icon(icon, size: 18),
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
    final pregnancyRate =
        IndicadorReprodutivoCalculator.pregnancyRateFromAnimals(animals);

    final pregnancyCard = _HerdMetricCard(
      title: 'Taxa de prenhez',
      value: pregnancyRate == null ? '--' : formatPercent(pregnancyRate),
      subtitle: pregnancyRate == null ? 'Aguardando' : 'Status visual',
      icon: Icons.monitor_heart_outlined,
      color: AppTheme.primary2Color,
      iconBackgroundColor: AppTheme.primary2Color.withValues(alpha: 0.10),
    );

    const birthIntervalCard = _HerdMetricCard(
      title: 'Intervalo partos',
      value: '--',
      subtitle: 'Sem dados',
      icon: Icons.event_repeat_outlined,
      color: Color(0xFF0369A1),
      iconBackgroundColor: Color(0xFFE0F2FE),
    );

    final pendingCard = _HerdMetricCard(
      title: 'Pendentes',
      value: statusCounts[AnimalReproductiveStatus.pending].toString(),
      subtitle: 'Aguardam definição',
      icon: Icons.pending_actions_outlined,
      color: const Color(0xFF8A5C00),
      iconBackgroundColor: const Color(0xFFFFF0C2),
    );

    final statusCard = _HerdStatusCard(
      counts: statusCounts,
      total: animals.length,
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          pregnancyCard,
          const SizedBox(height: 8),

          birthIntervalCard,
          const SizedBox(height: 8),

          pendingCard,
          const SizedBox(height: 12),

          statusCard,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: pregnancyCard),
              const SizedBox(width: 12),
              Expanded(child: birthIntervalCard),
              const SizedBox(width: 12),
              Expanded(child: pendingCard),
            ],
          ),
        ),
        const SizedBox(height: 12),
        statusCard,
      ],
    );
  }
}

class _HerdMetricCard extends StatelessWidget {
  const _HerdMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.iconBackgroundColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compact = MediaQuery.sizeOf(context).width < MOBILE_WIDTH;

    return AppCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 42 : 48,
            height: compact ? 42 : 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: compact ? 21 : 24),
          ),

          SizedBox(width: compact ? 10 : 14),

          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: compact ? 9.5 : null,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: compact ? 3 : 4),

                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),

                      if (title.toLowerCase().contains('intervalo') &&
                          value != '--')
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

                SizedBox(height: compact ? 3 : 4),

                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: compact ? 10 : null,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
            LayoutBuilder(
              builder: (context, constraints) {
                final statuses = AnimalReproductiveStatus.editableValues;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0; index < statuses.length; index++) ...[
                      Expanded(
                        child: _StatusCountTile(
                          status: statuses[index],
                          count: counts[statuses[index]] ?? 0,
                          total: total,
                        ),
                      ),
                      if (index < statuses.length - 1)
                        const SizedBox(width: 12),
                    ],
                  ],
                );
              },
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
    final ratio = total == 0 ? 0.0 : count / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
    );
  }
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
  return IndicadorReprodutivoCalculator.resolveAnimalStatus(animal);
}

Map<AnimalReproductiveStatus, int> _reproductiveStatusCounts(
  List<AnimalSummaryModel> animals,
) {
  return IndicadorReprodutivoCalculator.countAnimalStatuses(animals);
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
    AnimalReproductiveStatus.inseminated ||
    AnimalReproductiveStatus.inseminatedSt ||
    AnimalReproductiveStatus.protocol ||
    AnimalReproductiveStatus.waitingDiagnosis =>
      const _ReproductiveStatusColors(
        background: Color(0xFFE0F2FE),
        border: Color(0xFFB9E1FA),
        foreground: Color(0xFF0369A1),
      ),
    AnimalReproductiveStatus.dry => const _ReproductiveStatusColors(
      background: Color(0xFFFFF0C2),
      border: Color(0xFFEFD58C),
      foreground: Color(0xFF8A5C00),
    ),
    AnimalReproductiveStatus.released => const _ReproductiveStatusColors(
      background: Color(0xFFDFF8EA),
      border: Color(0xFFB9E9CF),
      foreground: Color(0xFF0D6B42),
    ),
    AnimalReproductiveStatus.delayed ||
    AnimalReproductiveStatus.induction ||
    AnimalReproductiveStatus.discard ||
    AnimalReproductiveStatus.pev ||
    AnimalReproductiveStatus.noAge ||
    AnimalReproductiveStatus.calf ||
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

Future<void> _importAnimalsExcel(
  BuildContext context,
  WidgetRef ref,
  List<PropertySummaryModel> properties,
) async {
  if (properties.isEmpty) {
    showAppWarning('Cadastre ou carregue propriedades antes de importar.');
    return;
  }

  final result = await AnimalExcelImportDialog.show(
    context,
    properties: properties,
  );

  if (result == null || result.importedRows == 0) return;

  try {
    ref.invalidate(animalsProvider);
    if (!context.mounted) return;
    showAppSuccess('${result.importedRows} animais importados com sucesso.');
  } catch (error) {
    showAppError(error);
  }
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
