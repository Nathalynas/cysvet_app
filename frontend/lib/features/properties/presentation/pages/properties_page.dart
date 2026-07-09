import 'package:cysvet_app/core/constants/app_constants.dart';
import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/core/enums/property_status.dart';
import 'package:cysvet_app/core/utils/formatters.dart';
import 'package:cysvet_app/core/widgets/app_button.dart';
import 'package:cysvet_app/core/widgets/app_card.dart';
import 'package:cysvet_app/core/widgets/app_dialog.dart';
import 'package:cysvet_app/core/widgets/app_dropdown.dart';
import 'package:cysvet_app/core/widgets/app_table.dart';
import 'package:cysvet_app/core/widgets/search_card.dart';
import 'package:cysvet_app/core/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../app/app_shell.dart';
import '../../../../core/presentation/async_value_view.dart';
import '../../../../core/presentation/app_scaffold_messenger.dart';
import '../../../animals/application/animals_provider.dart';
import '../../../animals/data/animals_repository.dart';
import '../../../animals/domain/animal_summary_model.dart';
import '../../../auth/application/auth_state.dart';
import '../../../visits/application/visits_provider.dart';
import '../../../visits/data/visits_repository.dart';
import '../../../visits/domain/visit_summary_model.dart';
import '../../application/properties_provider.dart';
import '../../domain/property_summary_model.dart';
import '../widgets/property_dialog.dart';

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
              const PageTitle(
                title: 'Propriedades',
                subtitle:
                    'Gerencie as fazendas atendidas e suas informações cadastrais.',
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
                        onCreate: () => PropertyDialog.show(context),
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
                                      onTap: () => _showPropertyDetails(
                                        context,
                                        ref,
                                        property,
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

class _PropertiesToolbar extends StatelessWidget {
  const _PropertiesToolbar({
    required this.searchQuery,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onCreate,
  });

  final String searchQuery;
  final PropertyStatusFilter statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<PropertyStatusFilter?> onStatusChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 720;
        final search = SearchCard(
          value: searchQuery,
          labelText: 'Pesquisar propriedades',
          onChanged: onSearchChanged,
        );
        final status = AppDropdown<PropertyStatusFilter>(
          value: statusFilter,
          labelText: 'Status',
          onChanged: onStatusChanged,
          options: PropertyStatusFilter.values
              .map((item) => AppDropdownOption(label: item.label, value: item))
              .toList(growable: false),
        );
        final button = AppButton(
          text: 'Nova propriedade',
          icon: const Icon(Icons.add),
          onPressed: onCreate,
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 10),
              status,
              const SizedBox(height: 10),
              button,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: search),
            const SizedBox(width: 12),
            SizedBox(width: 200, child: status),
            const SizedBox(width: 12),
            button,
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

Future<void> _showPropertyDetails(
  BuildContext context,
  WidgetRef ref,
  PropertySummaryModel property,
) {
  Future<void> closeDetailsAndRun(Future<void> Function() action) async {
    await Navigator.of(context, rootNavigator: true).maybePop();
    if (context.mounted) {
      await action();
    }
  }

  return AppDialog.show<void>(
    context: context,
    title: property.nome.isEmpty ? 'Detalhes da propriedade' : property.nome,
    width: 920,
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
    fullscreenBodyPadding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
    headerIndent: 16,
    useInternalScroll: true,
    fullscreenOnMobile: true,
    headerActions: [
      _PropertyDialogHeaderActions(
        property: property,
        onEdit: () =>
            PropertyDialog.show(context, property: property, fromDetails: true),
        onToggleStatus: () => closeDetailsAndRun(() {
          return property.status == PropertyStatus.inactive
              ? _confirmActivate(context, ref, property)
              : _confirmInactivate(context, ref, property);
        }),
        onDelete: () =>
            closeDetailsAndRun(() => _confirmDelete(context, ref, property)),
      ),
    ],
    content: _PropertyDetailsContent(property: property),
  );
}

class _PropertyDialogHeaderActions extends StatelessWidget {
  const _PropertyDialogHeaderActions({
    required this.property,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final PropertySummaryModel property;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < MOBILE_WIDTH;
    final toggleText = property.status == PropertyStatus.inactive
        ? 'Ativar'
        : 'Inativar';
    final toggleIcon = property.status == PropertyStatus.inactive
        ? Icons.unarchive_outlined
        : Icons.archive_outlined;

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: toggleText,
            icon: Icon(toggleIcon),
            onPressed: onToggleStatus,
          ),
          IconButton(
            tooltip: 'Excluir',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        AppButton(
          text: 'Editar',
          outlined: true,
          height: 36,
          fontSize: 13,
          icon: const Icon(Icons.edit_outlined, size: 17),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          onPressed: onEdit,
        ),
        AppButton(
          text: toggleText,
          outlined: true,
          height: 36,
          fontSize: 13,
          icon: Icon(toggleIcon, size: 17),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          onPressed: onToggleStatus,
        ),
        AppButton(
          text: 'Excluir',
          outlined: true,
          height: 36,
          fontSize: 13,
          color: colorScheme.error,
          textColor: colorScheme.error,
          borderColor: colorScheme.error,
          icon: const Icon(Icons.delete_outline, size: 17),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          onPressed: onDelete,
        ),
      ],
    );
  }
}

class _PropertyDetailsContent extends ConsumerWidget {
  const _PropertyDetailsContent({required this.property});

  final PropertySummaryModel property;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final relatedData = ref.watch(propertiesRelatedDataProvider);
    final data = relatedData.asData?.value;
    final insights = data == null
        ? null
        : _PropertyInsights.from(property, data);
    final hasLoadedData = insights != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _PropertyDetailsCard(
          property: property,
          insights: insights,
          loading: relatedData.isLoading && !hasLoadedData,
        ),
        const SizedBox(height: 16),
        Text(
          'Animais vinculados',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (relatedData.isLoading && !hasLoadedData)
          const _DetailsFeedbackPanel(
            message: 'Carregando animais da propriedade...',
            loading: true,
          )
        else if (relatedData.hasError && !hasLoadedData)
          const _DetailsFeedbackPanel(
            message: 'Nao foi possivel carregar os animais desta propriedade.',
          )
        else
          _PropertyAnimalsTable(animals: insights?.animals ?? const []),
      ],
    );
  }
}

class _PropertyDetailsCard extends StatelessWidget {
  const _PropertyDetailsCard({
    required this.property,
    required this.insights,
    required this.loading,
  });

  final PropertySummaryModel property;
  final _PropertyInsights? insights;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastVisit = insights?.lastVisit;
    final loadingLabel = loading ? '...' : '--';

    return AppCard(
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Dados da propriedade',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InfoLine(
                      label: 'Nome',
                      value: _dashIfBlank(property.nome),
                    ),
                    _InfoLine(label: 'Status', value: property.status.label),
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
                    _InfoLine(
                      label: 'ID externo',
                      value: _dashIfBlank(property.idExterno),
                    ),
                    _InfoLine(
                      label: 'Rebanho total',
                      value: insights == null
                          ? loadingLabel
                          : _formatCount(insights!.herdTotal),
                    ),
                    _InfoLine(
                      label: 'Em reprodução',
                      value: insights == null
                          ? loadingLabel
                          : _formatCount(insights!.reproductionCount),
                    ),
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
                    if (property.observacoes?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      _InfoLine(
                        label: 'Observações',
                        value: property.observacoes!.trim(),
                      ),
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _InfoLine(
                          label: 'Nome',
                          value: _dashIfBlank(property.nome),
                        ),
                        _InfoLine(
                          label: 'Status',
                          value: property.status.label,
                        ),
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
                        _InfoLine(
                          label: 'ID externo',
                          value: _dashIfBlank(property.idExterno),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _InfoLine(
                          label: 'Rebanho total',
                          value: insights == null
                              ? loadingLabel
                              : _formatCount(insights!.herdTotal),
                        ),
                        _InfoLine(
                          label: 'Em reprodução',
                          value: insights == null
                              ? loadingLabel
                              : _formatCount(insights!.reproductionCount),
                        ),
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
                        if (property.observacoes?.trim().isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 8),
                          _InfoLine(
                            label: 'Observações',
                            value: property.observacoes!.trim(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PropertyAnimalsTable extends StatelessWidget {
  const _PropertyAnimalsTable({required this.animals});

  final List<AnimalSummaryModel> animals;

  @override
  Widget build(BuildContext context) {
    return AppTable<AnimalSummaryModel>(
      rows: animals,
      footerLabel: _recordsLabel(animals.length),
      emptyMessage: 'Nenhum animal vinculado a esta propriedade.',
      mobileTitleBuilder: (context, animal) {
        return Text(
          _animalCodeLabel(animal.codigo),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        );
      },
      columns: [
        AppTableColumn<AnimalSummaryModel>(
          label: 'Animal',
          flex: 3,
          cellBuilder: (context, animal) => _AnimalIdentityCell(animal: animal),
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Categoria',
          flex: 2,
          cellBuilder: (context, animal) => Text(
            [
              _dashIfBlank(animal.categoria),
              if (animal.sexo?.trim().isNotEmpty == true) animal.sexo!.trim(),
            ].join(' / '),
          ),
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Status',
          flex: 2,
          cellBuilder: (context, animal) => StatusBadge(
            label: animal.status.label,
            type: _animalStatusBadgeType(animal.status),
          ),
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Reprodução',
          flex: 2,
          cellBuilder: (context, animal) {
            final status = _animalReproductiveStatusFor(animal);
            return StatusBadge(
              label: status.label,
              type: _reproductiveStatusBadgeType(status),
              icon: status.icon,
            );
          },
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Última IA',
          flex: 2,
          cellBuilder: (context, animal) =>
              Text(formatDate(animal.dataInseminacao)),
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Último parto',
          flex: 2,
          cellBuilder: (context, animal) =>
              Text(formatDate(animal.dataUltimoParto)),
        ),
      ],
    );
  }
}

class _AnimalIdentityCell extends StatelessWidget {
  const _AnimalIdentityCell({required this.animal});

  final AnimalSummaryModel animal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _animalCodeLabel(animal.codigo),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (animal.idExterno.trim().isNotEmpty)
          Text(
            animal.idExterno.trim(),
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

class _DetailsFeedbackPanel extends StatelessWidget {
  const _DetailsFeedbackPanel({required this.message, this.loading = false});

  final String message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      borderRadius: 16,
      child: Row(
        children: [
          if (loading) ...[
            SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
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

StatusBadgeType _animalStatusBadgeType(AnimalStatus status) {
  return switch (status) {
    AnimalStatus.active => StatusBadgeType.success,
    AnimalStatus.sold => StatusBadgeType.info,
    AnimalStatus.death => StatusBadgeType.error,
    AnimalStatus.inactive => StatusBadgeType.neutral,
  };
}

StatusBadgeType _reproductiveStatusBadgeType(AnimalReproductiveStatus status) {
  return switch (status) {
    AnimalReproductiveStatus.pregnant => StatusBadgeType.success,
    AnimalReproductiveStatus.inseminated ||
    AnimalReproductiveStatus.inseminatedSt ||
    AnimalReproductiveStatus.protocol ||
    AnimalReproductiveStatus.waitingDiagnosis => StatusBadgeType.info,
    AnimalReproductiveStatus.empty => StatusBadgeType.warning,
    AnimalReproductiveStatus.released => StatusBadgeType.success,
    AnimalReproductiveStatus.delayed ||
    AnimalReproductiveStatus.induction ||
    AnimalReproductiveStatus.discard ||
    AnimalReproductiveStatus.pev ||
    AnimalReproductiveStatus.noAge ||
    AnimalReproductiveStatus.calf ||
    AnimalReproductiveStatus.dry ||
    AnimalReproductiveStatus.pending => StatusBadgeType.neutral,
  };
}

String _formatCount(int value) {
  return formatInteger(value);
}

String _dashIfBlank(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return '--';
  return text;
}

String _recordsLabel(int count) {
  return '$count ${count == 1 ? 'animal' : 'animais'} vinculados';
}

String _animalCodeLabel(String code) {
  final text = code.trim();
  if (text.isEmpty) return '--';
  if (text.startsWith('#')) return text;
  return '#$text';
}

Future<void> _confirmInactivate(
  BuildContext context,
  WidgetRef ref,
  PropertySummaryModel property,
) {
  return AppDialog.show<void>(
    context: context,
    title: 'Inativar propriedade',
    content: Text('Deseja inativar ${property.nome}?'),
    confirmText: 'Inativar',
    cancelText: 'Cancelar',
    onConfirm: () async {
      final navigator = Navigator.of(context, rootNavigator: true);
      try {
        await ref.read(propertiesControllerProvider).inactivate(property.id);
        if (context.mounted) {
          await navigator.maybePop();
          showAppSuccess('Propriedade inativada com sucesso.');
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
  PropertySummaryModel property,
) {
  return AppDialog.show<void>(
    context: context,
    title: 'Ativar propriedade',
    content: Text('Deseja ativar ${property.nome}?'),
    confirmText: 'Ativar',
    cancelText: 'Cancelar',
    onConfirm: () async {
      final navigator = Navigator.of(context, rootNavigator: true);
      try {
        await ref.read(propertiesControllerProvider).activate(property.id);
        if (context.mounted) {
          await navigator.maybePop();
          showAppSuccess('Propriedade ativada com sucesso.');
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
  PropertySummaryModel property,
) {
  return AppDialog.show<void>(
    context: context,
    title: 'Excluir propriedade',
    content: Text('Deseja excluir ${property.nome} desta sessao?'),
    confirmText: 'Excluir',
    cancelText: 'Cancelar',
    onConfirm: () async {
      final navigator = Navigator.of(context, rootNavigator: true);
      try {
        await ref.read(propertiesControllerProvider).delete(property.id);
        if (context.mounted) {
          await navigator.maybePop();
          showAppSuccess('Propriedade excluída com sucesso.');
        }
      } catch (error) {
        showAppError(error);
      }
    },
  );
}
