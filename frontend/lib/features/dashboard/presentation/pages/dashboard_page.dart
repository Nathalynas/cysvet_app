import 'dart:math' as math;

import 'package:cysvet_app/core/constants/app_constants.dart';
import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/core/enums/user_status.dart';
import 'package:cysvet_app/core/widgets/app_card.dart';
import 'package:cysvet_app/core/widgets/app_dropdown.dart';
import 'package:cysvet_app/core/widgets/app_table.dart';
import 'package:cysvet_app/core/widgets/loading_state.dart';
import 'package:cysvet_app/core/widgets/property_filter_card.dart';
import 'package:cysvet_app/core/widgets/status_badge.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_shell.dart';
import '../../../../core/presentation/async_value_view.dart';
import '../../../../core/utils/formatters.dart';
import '../../../animals/application/animals_provider.dart';
import '../../../animals/data/animals_repository.dart';
import '../../../animals/domain/animal_summary_model.dart';
import '../../../auth/application/auth_state.dart';
import '../../../auth/domain/auth_session_model.dart';
import '../../../indicators/domain/indicador_reprodutivo_calculator.dart';
import '../../../properties/application/properties_provider.dart';
import '../../../properties/domain/property_summary_model.dart';
import '../../../users/application/users_provider.dart';
import '../../../users/domain/user_summary_model.dart';
import '../../../visits/application/visits_provider.dart';
import '../../../visits/data/visits_repository.dart';
import '../../../visits/domain/visit_summary_model.dart';
import '../../application/dashboard_provider.dart';
import '../../domain/dashboard_metrics_model.dart';

final dashboardPeriodFilterProvider =
    NotifierProvider<DashboardPeriodFilterNotifier, DashboardPeriodFilter>(
      DashboardPeriodFilterNotifier.new,
    );

final dashboardRelatedDataProvider = FutureProvider.autoDispose
    .family<_DashboardRelatedData, int?>((ref, propertyId) async {
      final session = ref.watch(authSessionProvider);
      final localAnimals = ref.watch(localAnimalsProvider);
      final deletedAnimalIds = ref.watch(deletedAnimalsProvider);
      final localVisits = ref.watch(localVisitsProvider);

      if (session == null) {
        throw StateError('Sessão indisponível.');
      }

      // Dados integrados ao back-end: animais e visitas listados pelas APIs.
      // Dados apenas front-end: merge com itens locais ainda nao sincronizados.
      final animalsRepository = ref.watch(animalsRepositoryProvider);
      final visitsRepository = ref.watch(visitsRepositoryProvider);
      var remoteAnimals = <AnimalSummaryModel>[];
      var remoteVisits = <VisitSummaryModel>[];

      await Future.wait<void>([
        animalsRepository.list(propertyId: propertyId).then<void>((items) {
          remoteAnimals = items;
        }),
        visitsRepository.list(propertyId: propertyId).then<void>((items) {
          remoteVisits = items;
        }),
      ]);

      final animals =
          {
            for (final animal in remoteAnimals)
              animal.id: localAnimals[animal.id] ?? animal,
            ...localAnimals,
          }.values.where((animal) {
            return !deletedAnimalIds.contains(animal.id) &&
                _animalMatchesPropertyId(animal, propertyId);
          }).toList();
      animals.sort((a, b) => a.codigo.compareTo(b.codigo));

      final visits =
          {
            for (final visit in remoteVisits)
              visit.id: localVisits[visit.id] ?? visit,
            ...localVisits,
          }.values.where((visit) {
            return _visitMatchesPropertyId(visit, propertyId);
          }).toList();
      visits.sort(_compareVisitsByDateDesc);

      return _DashboardRelatedData(animals: animals, visits: visits);
    });

enum DashboardPeriodFilter {
  last30('Últimos 30 dias'),
  last90('Últimos 90 dias'),
  currentMonth('Este mês'),
  currentYear('Este ano'),
  all('Todo o histórico');

  const DashboardPeriodFilter(this.label);

  final String label;
}

class DashboardPeriodFilterNotifier extends Notifier<DashboardPeriodFilter> {
  @override
  DashboardPeriodFilter build() => DashboardPeriodFilter.last30;

  void set(DashboardPeriodFilter? value) {
    if (value == null) return;
    state = value;
  }
}

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPropertyId = ref.watch(dashboardPropertyFilterProvider);
    final period = ref.watch(dashboardPeriodFilterProvider);
    final dashboard = ref.watch(dashboardProvider);
    final relatedData = ref.watch(
      dashboardRelatedDataProvider(selectedPropertyId),
    );
    final properties = ref.watch(propertiesProvider);
    final users = ref.watch(usersProvider);
    final propertyOptions =
        properties.asData?.value ?? const <PropertySummaryModel>[];
    final propertyById = {
      for (final property in propertyOptions) property.id: property,
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait<void>([
              ref.refresh(dashboardProvider.future).then((_) {}),
              ref.refresh(propertiesProvider.future).then((_) {}),
              ref.refresh(usersProvider.future).then((_) {}),
              ref
                  .refresh(
                    dashboardRelatedDataProvider(selectedPropertyId).future,
                  )
                  .then((_) {}),
            ]);
          },
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              PageTitle(
                title: 'Dashboard',
                subtitle:
                    'Acompanhe os principais indicadores e atividades do rebanho.',
                headerFilter: _DashboardToolbar(
                  properties: propertyOptions,
                  selectedPropertyId: selectedPropertyId,
                  period: period,
                  onPropertyChanged: (value) {
                    ref
                        .read(dashboardPropertyFilterProvider.notifier)
                        .set(value);
                  },
                  onPeriodChanged: (value) {
                    ref.read(dashboardPeriodFilterProvider.notifier).set(value);
                  },
                ),
              ),
              Padding(
                padding: PageTitle.contentPadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AsyncValueView<DashboardMetricsModel>(
                      value: dashboard,
                      loadingMessage: 'Buscando indicadores...',
                      onRetry: () => ref.invalidate(dashboardProvider),
                      builder: (metrics) {
                        return _DashboardContent(
                          metrics: metrics,
                          relatedData: relatedData,
                          users: users.asData?.value,
                          usersLoading: users.isLoading,
                          usersError: users.hasError,
                          properties: propertyOptions,
                          selectedProperty: propertyById[selectedPropertyId],
                          period: period,
                          onRetryRelated: () {
                            ref.invalidate(
                              dashboardRelatedDataProvider(selectedPropertyId),
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

class _DashboardToolbar extends StatelessWidget {
  const _DashboardToolbar({
    required this.properties,
    required this.selectedPropertyId,
    required this.period,
    required this.onPropertyChanged,
    required this.onPeriodChanged,
  });

  final List<PropertySummaryModel> properties;
  final int? selectedPropertyId;
  final DashboardPeriodFilter period;
  final ValueChanged<int?> onPropertyChanged;
  final ValueChanged<DashboardPeriodFilter?> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 720;

        final propertyFilter = PropertySegmentedFilter(
          properties: properties,
          selectedPropertyId: selectedPropertyId,
          generalText: 'Geral',
          propertyText: 'Por propriedade',
          onChanged: onPropertyChanged,
        );

        final periodFilter = AppDropdown<DashboardPeriodFilter>(
          value: period,
          labelText: 'Período',
          onChanged: onPeriodChanged,
          options: DashboardPeriodFilter.values
              .map(
                (item) => AppDropdownOption<DashboardPeriodFilter>(
                  label: item.label,
                  value: item,
                ),
              )
              .toList(growable: false),
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              propertyFilter,
              const SizedBox(height: 10),
              periodFilter,
            ],
          );
        }

        return Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              propertyFilter,
              const SizedBox(width: 12),
              SizedBox(width: 230, child: periodFilter),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.metrics,
    required this.relatedData,
    required this.users,
    required this.usersLoading,
    required this.usersError,
    required this.properties,
    required this.selectedProperty,
    required this.period,
    required this.onRetryRelated,
  });

  final DashboardMetricsModel metrics;
  final AsyncValue<_DashboardRelatedData> relatedData;
  final List<UserSummaryModel>? users;
  final bool usersLoading;
  final bool usersError;
  final List<PropertySummaryModel> properties;
  final PropertySummaryModel? selectedProperty;
  final DashboardPeriodFilter period;
  final VoidCallback onRetryRelated;

  bool get isPropertyView => selectedProperty != null;

  @override
  Widget build(BuildContext context) {
    final data = relatedData.asData?.value;
    final insights = _DashboardInsights.from(
      metrics: metrics,
      data: data ?? const _DashboardRelatedData.empty(),
      users: users,
      usersLoading: usersLoading,
      usersError: usersError,
      properties: properties,
      selectedProperty: selectedProperty,
      period: period,
      now: DateTime.now(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DashboardHeader(insights: insights),
        const SizedBox(height: 14),
        _TopDashboardSection(insights: insights),
        if (relatedData.isLoading && data == null) ...[
          const SizedBox(height: 16),
          const LoadingState(message: 'Carregando animais e visitas...'),
        ] else if (relatedData.hasError && data == null) ...[
          const SizedBox(height: 16),
          _FeedbackCard(onRetry: onRetryRelated),
        ] else ...[
          const SizedBox(height: 22),
          _AgendaSection(
            items: insights.agendaItems,
            showProperty: !isPropertyView,
          ),
          const SizedBox(height: 22),
          _ChartsSection(insights: insights),
          const SizedBox(height: 22),
          _MonthlyCalendarSection(rows: insights.monthlySchedule),
          if (isPropertyView) ...[
            const SizedBox(height: 22),
            _AnimalDetailsSection(rows: insights.animalRows),
            const SizedBox(height: 22),
            _VisitObservationsSection(items: insights.observations),
          ],
          const SizedBox(height: 22),
          _VisitHistorySection(
            rows: insights.visitHistoryRows,
            showProperty: !isPropertyView,
          ),
        ],
      ],
    );
  }
}

class _DashboardHeader extends ConsumerWidget {
  const _DashboardHeader({required this.insights});

  final _DashboardInsights insights;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final property = insights.selectedProperty;
    final isMobile = MediaQuery.sizeOf(context).width < MOBILE_WIDTH;

    final rawCompanyName = ref
        .watch(authSessionProvider)
        ?.activeCompany
        ?.name
        .trim();
    final companyName = rawCompanyName == null || rawCompanyName.isEmpty
        ? 'Empresa não informada'
        : rawCompanyName;

    return AppCard(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      shadow: false,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.92),
                      colorScheme.primary.withValues(alpha: 0.78),
                    ],
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: isMobile ? 0.62 : 0.52,
                  heightFactor: 1,
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: [0.0, 0.22, 1.0],
                        colors: [
                          Colors.transparent,
                          Colors.black87,
                          Colors.black,
                        ],
                      ).createShader(bounds);
                    },
                    child: Image.asset(
                      'assets/images/cow2.jfif',
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0.0, 0.48, 1.0],
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.96),
                      colorScheme.primary.withValues(alpha: 0.70),
                      colorScheme.primary.withValues(alpha: 0.08),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 18 : 22,
                isMobile ? 18 : 22,
                isMobile ? 18 : 280,
                isMobile ? 18 : 22,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property?.nome ?? companyName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),

                    if (property != null) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 18,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (property.nomeProprietario.trim().isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 16,
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  property.nomeProprietario.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),

                          if (property.localizacao.trim().isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  property.localizacao.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 6),

                    Text(
                      property == null
                          ? '${insights.period.label} - ${formatDate(insights.now)}'
                          : 'Relatório da fazenda - ${formatDate(insights.now)} - ${insights.period.label}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopDashboardSection extends StatelessWidget {
  const _TopDashboardSection({required this.insights});

  final _DashboardInsights insights;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < MOBILE_WIDTH;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricSummaryCard(items: insights.mainMetrics),
          const SizedBox(height: 12),
          _RateLineChart(items: insights.rateItems),
        ],
      );
    }

    // Nao use IntrinsicHeight aqui.
    // O grafico usa LayoutBuilder internamente, e LayoutBuilder nao pode ser
    // medido por dimensoes intrinsecas. Por isso, no desktop a altura e
    // controlada pelo container pai, mantendo os cards alinhados sem quebrar o
    // layout do Flutter.
    final sectionHeight = math.max(
      348.0,
      insights.mainMetrics.length * 44.0 + 96.0,
    );

    return SizedBox(
      height: sectionHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 360,
            child: _MetricSummaryCard(items: insights.mainMetrics),
          ),
          const SizedBox(width: 12),
          Expanded(child: _RateLineChart(items: insights.rateItems)),
        ],
      ),
    );
  }
}

class _MetricSummaryCard extends StatelessWidget {
  const _MetricSummaryCard({required this.items});

  final List<_MetricItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = MediaQuery.sizeOf(context).width < MOBILE_WIDTH;

    final header = [
      Text(
        'Resumo do Rebanho',
        style: theme.textTheme.titleSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Principais totais acompanhados no filtro atual.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    ];

    final compactRows = <Widget>[
      for (var index = 0; index < items.length; index++) ...[
        if (index > 0)
          Divider(
            height: 12,
            color: colorScheme.outline.withValues(alpha: 0.18),
          ),
        _MetricSummaryRow(item: items[index]),
      ],
    ];

    final expandedRows = Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items) _MetricSummaryRow(item: item),
      ],
    );

    return AppCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...header,
          SizedBox(height: isMobile ? 10 : 6),
          if (isMobile) ...compactRows else Expanded(child: expandedRows),
        ],
      ),
    );
  }
}

class _MetricSummaryRow extends StatelessWidget {
  const _MetricSummaryRow({required this.item});

  final _MetricItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = item.color ?? colorScheme.primary;

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_metricIcon(item.label), size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          item.value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _EqualHeightCardGrid extends StatelessWidget {
  const _EqualHeightCardGrid({
    required this.children,
    required this.columns,
    this.desktopRowHeight,
  });

  static const double _spacing = 12;

  final List<Widget> children;
  final int columns;
  final double? desktopRowHeight;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    if (columns <= 1 || MediaQuery.sizeOf(context).width < MOBILE_WIDTH) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) SizedBox(height: _spacing),
            children[index],
          ],
        ],
      );
    }

    final rows = <Widget>[];

    for (var rowStart = 0; rowStart < children.length; rowStart += columns) {
      if (rows.isNotEmpty) {
        rows.add(SizedBox(height: _spacing));
      }

      final row = Row(
        crossAxisAlignment: desktopRowHeight == null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.stretch,
        children: [
          for (var column = 0; column < columns; column++) ...[
            if (column > 0) SizedBox(width: _spacing),
            Expanded(
              child: rowStart + column < children.length
                  ? children[rowStart + column]
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      );

      rows.add(
        desktopRowHeight == null
            ? row
            : SizedBox(height: desktopRowHeight, child: row),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

IconData _metricIcon(String label) {
  final text = label.normalize();
  if (text.contains('propriedade')) return Icons.home_work_rounded;
  if (text.contains('animal')) return Icons.pets_rounded;
  if (text.contains('lact')) return Icons.water_drop_rounded;
  if (text.contains('seca')) return Icons.grass_rounded;
  if (text.contains('novilha')) return Icons.spa_rounded;
  return Icons.analytics_rounded;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _AgendaSection extends StatelessWidget {
  const _AgendaSection({required this.items, required this.showProperty});

  final List<_AgendaItem> items;
  final bool showProperty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          'Agenda Reprodutiva',
          subtitle: 'Próximas visitas, eventos previstos e pendências.',
        ),
        const SizedBox(height: 10),
        _AgendaTable(items: items, showProperty: showProperty),
      ],
    );
  }
}

class _AgendaTable extends StatelessWidget {
  const _AgendaTable({required this.items, required this.showProperty});

  final List<_AgendaItem> items;
  final bool showProperty;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < MOBILE_WIDTH) {
      return _CompactAgendaCard(items: items, showProperty: showProperty);
    }

    return AppTable<_AgendaItem>(
      rows: items,
      emptyMessage: 'Nenhuma ação reprodutiva encontrada.',
      footerLabel: _recordsLabel(
        items.length,
        singular: 'ação',
        plural: 'ações',
      ),
      mobileBreakpoint: 760,
      mobileTitleBuilder: (context, item) {
        return Text(
          item.type,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        );
      },
      columns: [
        AppTableColumn<_AgendaItem>(
          label: 'Data',
          flex: 2,
          alignment: Alignment.center,
          cellBuilder: (context, item) => Text(formatDate(item.date)),
        ),
        AppTableColumn<_AgendaItem>(
          label: 'Tipo',
          flex: 3,
          alignment: Alignment.center,
          cellBuilder: (context, item) => Text(item.type),
        ),
        if (showProperty)
          AppTableColumn<_AgendaItem>(
            label: 'Propriedade',
            flex: 3,
            alignment: Alignment.center,
            cellBuilder: (context, item) => Text(_dashIfBlank(item.property)),
          )
        else
          AppTableColumn<_AgendaItem>(
            label: 'Animal',
            flex: 2,
            alignment: Alignment.center,
            cellBuilder: (context, item) => Text(_dashIfBlank(item.animalCode)),
          ),
      ],
    );
  }
}

class _CompactAgendaCard extends StatelessWidget {
  const _CompactAgendaCard({required this.items, required this.showProperty});

  final List<_AgendaItem> items;
  final bool showProperty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (items.isEmpty)
            Text(
              'Nenhuma ação reprodutiva encontrada.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0)
                Divider(
                  height: 18,
                  color: colorScheme.outline.withValues(alpha: 0.18),
                ),
              _CompactAgendaRow(
                item: items[index],
                showProperty: showProperty,
              ),
            ],
          ],
          Divider(
            height: 20,
            color: colorScheme.outline.withValues(alpha: 0.22),
          ),
          _CompactTableFooter(
            label: _recordsLabel(
              items.length,
              singular: 'ação',
              plural: 'ações',
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactAgendaRow extends StatelessWidget {
  const _CompactAgendaRow({required this.item, required this.showProperty});

  final _AgendaItem item;
  final bool showProperty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final related = showProperty ? item.property : item.animalCode;

    return Row(
      children: [
        _CompactListIcon(icon: Icons.event_available_rounded),
        const SizedBox(width: 10),
        Text(
          formatDate(item.date),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.type,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            _dashIfBlank(related),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactTableFooter extends StatelessWidget {
  const _CompactTableFooter({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        textAlign: TextAlign.left,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ChartsSection extends StatelessWidget {
  const _ChartsSection({required this.insights});

  final _DashboardInsights insights;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          insights.selectedProperty == null
              ? 'Gráficos Principais'
              : 'Gráficos da Fazenda',
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 1140
                ? 3
                : width >= 760
                ? 2
                : 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EqualHeightCardGrid(
                  columns: columns,
                  desktopRowHeight: 370,
                  children: [
                    _LactationThirdChart(items: insights.lactationThirds),
                    _ParityDonutChart(items: insights.parityChartItems),
                    _ReproductiveDonutChart(
                      items: insights.reproductiveChartItems,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _RateGaugeChart(items: insights.rateItems),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReproductiveDonutChart extends StatelessWidget {
  const _ReproductiveDonutChart({required this.items});

  final List<_ChartCountItem> items;

  @override
  Widget build(BuildContext context) {
    final hasData = items.any((item) => item.value > 0);

    return _ChartCard(
      title: 'Distribuição Reprodutiva',
      child: hasData
          ? LayoutBuilder(
              builder: (context, constraints) {
                final chartDimension = math.min(220.0, constraints.maxWidth);
                final total = items.fold<int>(0, (sum, item) {
                  return sum + item.value;
                });
                final chart = SizedBox.square(
                  dimension: chartDimension,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: chartDimension * 0.30,
                      sectionsSpace: 2,
                      startDegreeOffset: -90,
                      pieTouchData: PieTouchData(enabled: false),
                      sections: [
                        for (final item in items)
                          if (item.value > 0)
                            PieChartSectionData(
                              value: item.value.toDouble(),
                              color: item.color,
                              radius: chartDimension * 0.17,
                              title: _percentLabel(item.value, total),
                              titleStyle: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                      ],
                    ),
                  ),
                );

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(alignment: Alignment.center, child: chart),
                    const SizedBox(height: 12),
                    _ChartLegend(items: items, organizeOnDesktop: true),
                  ],
                );
              },
            )
          : const _EmptyChart(message: 'Sem registros reprodutivos.'),
    );
  }
}

class _LactationThirdChart extends StatelessWidget {
  const _LactationThirdChart({required this.items});

  final List<_ChartCountItem> items;

  @override
  Widget build(BuildContext context) {
    final hasData = items.any((item) => item.value > 0);

    return _ChartCard(
      title: 'Terço de Lactação',
      centerContent: true,
      child: hasData
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PercentBar(item: item, total: _chartTotal(items)),
                  ),
                const SizedBox(height: 2),
                _ChartLegend(items: items),
              ],
            )
          : const _EmptyChart(message: 'Sem dados de DEL.'),
    );
  }
}

class _ParityDonutChart extends StatelessWidget {
  const _ParityDonutChart({required this.items});

  final List<_ChartCountItem> items;

  @override
  Widget build(BuildContext context) {
    final hasData = items.any((item) => item.value > 0);

    return _ChartCard(
      title: 'Multíparas e Novilhas',
      centerContent: true,
      child: hasData
          ? LayoutBuilder(
              builder: (context, constraints) {
                final chartDimension = math.min(214.0, constraints.maxWidth);
                final total = _chartTotal(items);
                final chart = SizedBox.square(
                  dimension: chartDimension,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: chartDimension * 0.30,
                      sectionsSpace: 2,
                      pieTouchData: PieTouchData(enabled: false),
                      sections: [
                        for (final item in items)
                          if (item.value > 0)
                            PieChartSectionData(
                              value: item.value.toDouble(),
                              color: item.color,
                              radius: chartDimension * 0.19,
                              title: _percentLabel(item.value, total),
                              titleStyle: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                      ],
                    ),
                  ),
                );

                return Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: chartDimension,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        chart,
                        const SizedBox(height: 12),
                        _ChartLegend(items: items),
                      ],
                    ),
                  ),
                );
              },
            )
          : const _EmptyChart(message: 'Sem dados de categoria do rebanho.'),
    );
  }
}

class _RateLineChart extends StatelessWidget {
  const _RateLineChart({required this.items});

  final List<_RateItem> items;

  @override
  Widget build(BuildContext context) {
    final chartItems = items.where((item) => item.value != null).toList();

    return _ChartCard(
      title: 'Indicadores Reprodutivos',
      subtitle: 'Taxa de serviço, concepção, prenhez e concepção por IA.',
      subtitleBottomSpacing: 28,
      child: chartItems.isEmpty
          ? const SizedBox(
              height: 190,
              child: _EmptyChart(message: 'Sem indicadores calculados.'),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final theme = Theme.of(context);
                final colorScheme = theme.colorScheme;
                final maxValue = chartItems.fold<double>(0, (max, item) {
                  return math.max(max, item.value ?? 0);
                });
                final maxY = math.max(1.0, maxValue + 0.10).clamp(0.0, 1.0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 195,
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: math.max(1, chartItems.length - 1).toDouble(),
                          minY: 0,
                          maxY: maxY,
                          lineTouchData: LineTouchData(
                            handleBuiltInTouches: true,
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (spots) {
                                return spots.map((spot) {
                                  final index = spot.x.toInt();
                                  if (index < 0 || index >= chartItems.length) {
                                    return null;
                                  }
                                  final item = chartItems[index];
                                  return LineTooltipItem(
                                    '${item.label}\n${formatPercent(item.value!)}',
                                    (theme.textTheme.bodySmall ??
                                            const TextStyle())
                                        .copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 0.25,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: colorScheme.outline.withValues(
                                alpha: 0.18,
                              ),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(),
                            rightTitles: const AxisTitles(),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 42,
                                interval: 0.25,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${(value * 100).round()}%',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 48,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  final index = value.round();
                                  if (index < 0 || index >= chartItems.length) {
                                    return const SizedBox.shrink();
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      chartItems[index].shortLabel,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w800,
                                            height: 1.05,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                for (
                                  var index = 0;
                                  index < chartItems.length;
                                  index++
                                )
                                  FlSpot(
                                    index.toDouble(),
                                    chartItems[index].value!.clamp(0.0, 1.0),
                                  ),
                              ],
                              isCurved: true,
                              preventCurveOverShooting: true,
                              color: _ChartColors.deepBlue,
                              barWidth: 4,
                              isStrokeCapRound: true,
                              belowBarData: BarAreaData(
                                show: true,
                                color: _ChartColors.deepBlue.withValues(
                                  alpha: 0.18,
                                ),
                              ),
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, bar, index) {
                                  final item = chartItems[index];
                                  return FlDotCirclePainter(
                                    radius: 5,
                                    color: item.color,
                                    strokeWidth: 3,
                                    strokeColor: colorScheme.surface,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _RateLegend(items: chartItems),
                  ],
                );
              },
            ),
    );
  }
}

class _RateLegend extends StatelessWidget {
  const _RateLegend({required this.items});

  final List<_RateItem> items;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < MOBILE_WIDTH;

    if (isMobile) {
      return Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          for (final item in items)
            _LegendItem(
              color: item.color,
              label: item.label,
              value: item.value == null ? '--' : formatPercent(item.value!),
              allowWrap: true,
            ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const SizedBox(width: 10),
          Expanded(
            child: _LegendItem(
              color: items[index].color,
              label: items[index].label,
              value: items[index].value == null
                  ? '--'
                  : formatPercent(items[index].value!),
              expand: true,
              allowWrap: true,
            ),
          ),
        ],
      ],
    );
  }
}


class _RateGaugeChart extends StatelessWidget {
  const _RateGaugeChart({required this.items});

  final List<_RateItem> items;

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'Indicadores em Velocímetro',
      subtitle: 'Visualização rápida das taxas reprodutivas do período.',
      subtitleBottomSpacing: 18,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 920
              ? 4
              : width >= 660
              ? 2
              : 1;
          const spacing = 12.0;
          final itemWidth = (width - spacing * (columns - 1)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final item in items)
                SizedBox(width: itemWidth, child: _GaugeTile(item: item)),
            ],
          );
        },
      ),
    );
  }
}

class _GaugeTile extends StatelessWidget {
  const _GaugeTile({required this.item});

  final _RateItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 110,
          width: double.infinity,
          child: CustomPaint(
            painter: _GaugePainter(
              value: item.value?.clamp(0.0, 1.0),
              indicatorColor: item.color,
              backgroundColor: colorScheme.outlineVariant,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  item.value == null ? '--' : formatPercent(item.value!),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
        Text(
          item.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.value,
    required this.indicatorColor,
    required this.backgroundColor,
  });

  final double? value;
  final Color indicatorColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final width = math.min(size.width, size.height * 2);
    final center = Offset(size.width / 2, size.height * 0.94);
    final radius = width / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = math.pi;
    const sweep = math.pi;
    const gap = 0.035;
    final strokeWidth = math.max(12.0, radius * 0.18);

    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final segments = [
      (0.26, _ChartColors.danger),
      (0.15, const Color(0xFFFACC15)),
      (0.19, const Color(0xFFFDBA74)),
      (0.40, const Color(0xFFB45309)),
    ];
    var cursor = start;
    for (final segment in segments) {
      final segmentSweep = sweep * segment.$1;
      segmentPaint.color = value == null
          ? backgroundColor.withValues(alpha: 0.55)
          : segment.$2;
      canvas.drawArc(
        rect,
        cursor + gap,
        segmentSweep - gap * 2,
        false,
        segmentPaint,
      );
      cursor += segmentSweep;
    }

    if (value == null) return;

    final normalized = value!.clamp(0, 1);
    final angle = start + sweep * normalized;
    final needleLength = radius - strokeWidth * 0.15;
    final needleEnd = Offset(
      center.dx + math.cos(angle) * needleLength,
      center.dy + math.sin(angle) * needleLength,
    );
    final needlePaint = Paint()
      ..color = indicatorColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, shadowPaint);
    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 5, Paint()..color = indicatorColor);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.indicatorColor != indicatorColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class _PercentBar extends StatelessWidget {
  const _PercentBar({required this.item, required this.total});

  final _ChartCountItem item;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percent = total == 0 ? 0.0 : item.value / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(percent * 100).round()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 18,
            value: percent.clamp(0.0, 1.0),
            backgroundColor: item.color.withValues(alpha: 0.12),
            color: item.color,
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.centerContent = false,
    this.subtitleBottomSpacing = 16,
  });

  final String title;
  final Widget child;
  final String? subtitle;
  final bool centerContent;
  final double subtitleBottomSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shouldCenterContent =
        centerContent && MediaQuery.sizeOf(context).width >= MOBILE_WIDTH;
    final content = shouldCenterContent
        ? Expanded(child: Center(child: child))
        : child;

    return AppCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: shouldCenterContent ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w900,
        ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          SizedBox(height: subtitle == null ? 16 : subtitleBottomSpacing),
          content,
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.items, this.organizeOnDesktop = false});

  final List<_ChartCountItem> items;
  final bool organizeOnDesktop;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        for (final item in items)
          _LegendItem(
            color: item.color,
            label: item.label,
            value: item.value.toString(),
            allowWrap: true,
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    this.expand = false,
    this.allowWrap = false,
  });

  final Color color;
  final String label;
  final String value;
  final bool expand;
  final bool allowWrap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: expand ? double.infinity : 220),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label: $value',
              maxLines: allowWrap ? 3 : 1,
              overflow: allowWrap ? TextOverflow.visible : TextOverflow.ellipsis,
              softWrap: allowWrap,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
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

class _MonthlyCalendarSection extends StatelessWidget {
  const _MonthlyCalendarSection({required this.rows});

  final List<_MonthlyScheduleRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          'Calendário Mensal',
          subtitle: 'Secagem, pré-parto e partos previstos por mês.',
        ),
        const SizedBox(height: 10),
        _MonthlyChart(rows: rows),
        const SizedBox(height: 12),
        _MonthlySummaryTables(rows: rows),
      ],
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.rows});

  final List<_MonthlyScheduleRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const AppCard(
        borderRadius: 16,
        child: SizedBox(
          height: 92,
          child: _EmptyChart(message: 'Sem eventos mensais no período.'),
        ),
      );
    }

    final maxY = rows.fold<int>(1, (max, row) {
      return math.max(
        max,
        math.max(row.dryOff, math.max(row.prepartum, row.births)),
      );
    }).toDouble();
    final chartWidth = math.max(620.0, rows.length * 76.0);

    return AppCard(
      borderRadius: 16,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: chartWidth,
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              minY: 0,
              maxY: maxY + 1,
              groupsSpace: 18,
              barTouchData: BarTouchData(enabled: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.18),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= rows.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          rows[index].monthLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var index = 0; index < rows.length; index++)
                  BarChartGroupData(
                    x: index,
                    barsSpace: 4,
                    barRods: [
                      _calendarRod(rows[index].dryOff, _ChartColors.warning),
                      _calendarRod(rows[index].prepartum, _ChartColors.info),
                      _calendarRod(rows[index].births, _ChartColors.success),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BarChartRodData _calendarRod(int value, Color color) {
    return BarChartRodData(
      toY: value.toDouble(),
      color: color,
      width: 8,
      borderRadius: BorderRadius.circular(4),
    );
  }
}

class _MonthlySummaryTables extends StatelessWidget {
  const _MonthlySummaryTables({required this.rows});

  final List<_MonthlyScheduleRow> rows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 660
            ? 2
            : 1;

        final double? rowHeight = rows.isEmpty
            ? null
            : math.max(190.0, rows.length * 38.0 + 112.0);

        return _EqualHeightCardGrid(
          columns: columns,
          desktopRowHeight: rowHeight,
          children: [
            _MonthlySummaryCard(
              title: 'Mês de secagem',
              valueLabel: 'Vacas secas',
              rows: [
                for (final row in rows)
                  _MonthlySummaryItem(row.monthLabel, row.dryOff),
              ],
            ),
            _MonthlySummaryCard(
              title: 'Mês de pré-parto',
              valueLabel: 'Vacas em pré-parto',
              rows: [
                for (final row in rows)
                  _MonthlySummaryItem(row.monthLabel, row.prepartum),
              ],
            ),
            _MonthlySummaryCard(
              title: 'Mês de parto',
              valueLabel: 'Partos por mês',
              rows: [
                for (final row in rows)
                  _MonthlySummaryItem(row.monthLabel, row.births),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({
    required this.title,
    required this.valueLabel,
    required this.rows,
  });

  final String title;
  final String valueLabel;
  final List<_MonthlySummaryItem> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final visibleRows = rows.where((row) => row.value > 0).toList();
    final total = visibleRows.fold<int>(0, (sum, row) => sum + row.value);

    return AppCard(
      borderRadius: 16,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.54),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    valueLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (visibleRows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Sem eventos no período.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else ...[
            for (final row in visibleRows)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.month,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      _formatCount(row.value),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            Divider(color: colorScheme.outline.withValues(alpha: 0.26)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total geral',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    _formatCount(total),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthlySummaryItem {
  const _MonthlySummaryItem(this.month, this.value);

  final String month;
  final int value;
}

class _VisitHistorySection extends StatelessWidget {
  const _VisitHistorySection({required this.rows, required this.showProperty});

  final List<_VisitHistoryRow> rows;
  final bool showProperty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          'Histórico de Visitas',
          subtitle: 'Visitas recentes no período selecionado.',
        ),
        const SizedBox(height: 10),
        _VisitHistoryTable(rows: rows, showProperty: showProperty),
      ],
    );
  }
}

class _VisitHistoryTable extends StatelessWidget {
  const _VisitHistoryTable({required this.rows, required this.showProperty});

  final List<_VisitHistoryRow> rows;
  final bool showProperty;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < MOBILE_WIDTH) {
      return _CompactVisitHistoryCard(rows: rows, showProperty: showProperty);
    }

    return AppTable<_VisitHistoryRow>(
      rows: rows,
      emptyMessage: 'Nenhuma visita encontrada no período.',
      footerLabel: _recordsLabel(
        rows.length,
        singular: 'visita',
        plural: 'visitas',
      ),
      mobileBreakpoint: 760,
      mobileTitleBuilder: (context, row) {
        return Text(
          row.date,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        );
      },
      columns: [
        AppTableColumn<_VisitHistoryRow>(
          label: 'Data',
          flex: 2,
          cellBuilder: (context, row) => Text(row.date),
        ),
        if (showProperty)
          AppTableColumn<_VisitHistoryRow>(
            label: 'Propriedade',
            flex: 3,
            cellBuilder: (context, row) => Text(row.property),
          ),
        AppTableColumn<_VisitHistoryRow>(
          label: 'Veterinário',
          flex: 3,
          cellBuilder: (context, row) => Text(row.veterinarian),
        ),
        AppTableColumn<_VisitHistoryRow>(
          label: 'Animais',
          alignment: Alignment.center,
          cellBuilder: (context, row) => Text(row.animals),
        ),
        AppTableColumn<_VisitHistoryRow>(
          label: 'Observações',
          flex: 5,
          cellBuilder: (context, row) => Text(row.observations),
        ),
      ],
    );
  }
}

class _CompactVisitHistoryCard extends StatelessWidget {
  const _CompactVisitHistoryCard({
    required this.rows,
    required this.showProperty,
  });

  final List<_VisitHistoryRow> rows;
  final bool showProperty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rows.isEmpty)
            Text(
              'Nenhuma visita encontrada no período.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0)
                Divider(
                  height: 18,
                  color: colorScheme.outline.withValues(alpha: 0.18),
                ),
              _CompactVisitRow(
                row: rows[index],
                showProperty: showProperty,
              ),
            ],
          ],
          Divider(
            height: 20,
            color: colorScheme.outline.withValues(alpha: 0.22),
          ),
          _CompactTableFooter(
            label: _recordsLabel(
              rows.length,
              singular: 'visita',
              plural: 'visitas',
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactVisitRow extends StatelessWidget {
  const _CompactVisitRow({required this.row, required this.showProperty});

  final _VisitHistoryRow row;
  final bool showProperty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        _CompactListIcon(icon: Icons.event_note_rounded),
        const SizedBox(width: 10),
        Text(
          row.date,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _dashIfBlank(row.veterinarian),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (showProperty) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _dashIfBlank(row.property),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AnimalDetailsSection extends StatelessWidget {
  const _AnimalDetailsSection({required this.rows});

  final List<_AnimalDetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          'Animais da propriedade',
          subtitle: 'Lista detalhada das matrizes acompanhadas.',
        ),
        const SizedBox(height: 10),
        _AnimalDetailTable(rows: rows),
      ],
    );
  }
}

class _AnimalDetailTable extends StatelessWidget {
  const _AnimalDetailTable({required this.rows});

  final List<_AnimalDetailRow> rows;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < MOBILE_WIDTH) {
      return _CompactAnimalListCard(rows: rows);
    }

    final table = AppTable<_AnimalDetailRow>(
      rows: rows,
      mobileBreakpoint: 1180,
      emptyMessage: 'Nenhum animal encontrado para o filtro atual.',
      footerLabel: _recordsLabel(
        rows.length,
        singular: 'animal',
        plural: 'animais',
      ),
      mobileTitleBuilder: (context, row) {
        return Text(
          row.matriz,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        );
      },
      columns: [
        AppTableColumn<_AnimalDetailRow>(
          label: 'Matriz',
          flex: 2,
          alignment: Alignment.centerLeft,
          cellBuilder: (context, row) {
            return _DashboardAnimalIdentityCell(row: row);
          },
        ),
        AppTableColumn<_AnimalDetailRow>(
          label: 'Idade',
          flex: 2,
          cellBuilder: (context, row) => Text(row.idade),
        ),
        AppTableColumn<_AnimalDetailRow>(
          label: 'Último parto',
          flex: 2,
          cellBuilder: (context, row) => Text(row.ultimoParto),
        ),
        AppTableColumn<_AnimalDetailRow>(
          label: 'Produtiva',
          flex: 2,
          cellBuilder: (context, row) => Text(row.situacaoProdutiva),
        ),
        AppTableColumn<_AnimalDetailRow>(
          label: 'Reprodutiva',
          flex: 2,
          alignment: Alignment.center,
          cellBuilder: (context, row) {
            return Center(
              child: StatusBadge(
                label: row.situacaoReprodutiva,
                type: row.reproductiveBadgeType,
              ),
            );
          },
        ),
        AppTableColumn<_AnimalDetailRow>(
          label: 'Decisão/obs.',
          flex: 3,
          cellBuilder: (context, row) => Text(row.decisaoObservacao),
        ),
        AppTableColumn<_AnimalDetailRow>(
          label: 'Última IA',
          flex: 2,
          cellBuilder: (context, row) => Text(row.dataUltimaIa),
        ),
        AppTableColumn<_AnimalDetailRow>(
          label: 'IAs',
          alignment: Alignment.center,
          cellBuilder: (context, row) => Text(row.numeroIas),
        ),
        AppTableColumn<_AnimalDetailRow>(
          label: 'Prenhez',
          alignment: Alignment.center,
          cellBuilder: (context, row) => Text(row.diasPrenhez),
        ),
        AppTableColumn<_AnimalDetailRow>(
          label: 'DEL',
          alignment: Alignment.center,
          cellBuilder: (context, row) => Text(row.del),
        ),
        AppTableColumn<_AnimalDetailRow>(
          label: 'Dias secar',
          flex: 2,
          alignment: Alignment.center,
          cellBuilder: (context, row) => Text(row.diasParaSecar),
        ),
        AppTableColumn<_AnimalDetailRow>(
          label: 'Secagem',
          flex: 2,
          cellBuilder: (context, row) => Text(row.previsaoSecagem),
        ),
        AppTableColumn<_AnimalDetailRow>(
          label: 'Pre-parto',
          flex: 2,
          cellBuilder: (context, row) => Text(row.dataPreParto),
        ),
        AppTableColumn<_AnimalDetailRow>(
          label: 'Parto',
          flex: 2,
          cellBuilder: (context, row) => Text(row.previsaoParto),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(1680.0, constraints.maxWidth - 8);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: SizedBox(width: tableWidth, child: table),
        );
      },
    );
  }
}

class _CompactAnimalListCard extends StatelessWidget {
  const _CompactAnimalListCard({required this.rows});

  final List<_AnimalDetailRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: rows.isEmpty
          ? Text(
              'Nenhum animal encontrado para o filtro atual.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < rows.length; index++) ...[
                  if (index > 0)
                    Divider(
                      height: 18,
                      color: colorScheme.outline.withValues(alpha: 0.18),
                    ),
                  _CompactAnimalRow(row: rows[index]),
                ],
              ],
            ),
    );
  }
}

class _CompactAnimalRow extends StatelessWidget {
  const _CompactAnimalRow({required this.row});

  final _AnimalDetailRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        _CompactListIcon(icon: Icons.pets_rounded),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            row.matriz,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        StatusBadge(
          label: row.situacaoReprodutiva,
          type: row.reproductiveBadgeType,
        ),
      ],
    );
  }
}

class _CompactListIcon extends StatelessWidget {
  const _CompactListIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 18, color: colorScheme.onPrimary),
    );
  }
}

class _DashboardAnimalIdentityCell extends StatelessWidget {
  const _DashboardAnimalIdentityCell({required this.row});

  final _AnimalDetailRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          row.matriz,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Último parto: ${row.ultimoParto}',
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

class _VisitObservationsSection extends StatelessWidget {
  const _VisitObservationsSection({required this.items});

  final List<_ObservationItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          'Observações da visita',
          subtitle: 'Ocorrencias classificadas no período selecionado.',
        ),
        const SizedBox(height: 10),
        AppCard(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: items.isEmpty
              ? Text(
                  'Nenhuma observação classificada no período.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final item in items)
                      _ObservationChip(label: item.label, count: item.count),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ObservationChip extends StatelessWidget {
  const _ObservationChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $count',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Não foi possível carregar animais e visitas.',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Os indicadores principais continuam disponíveis enquanto os dados são recarregados.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _DashboardRelatedData {
  const _DashboardRelatedData({required this.animals, required this.visits});

  const _DashboardRelatedData.empty() : animals = const [], visits = const [];

  final List<AnimalSummaryModel> animals;
  final List<VisitSummaryModel> visits;
}

class _DashboardInsights {
  const _DashboardInsights({
    required this.metrics,
    required this.data,
    required this.users,
    required this.usersLoading,
    required this.usersError,
    required this.properties,
    required this.selectedProperty,
    required this.period,
    required this.now,
    required this.range,
    required this.records,
    required this.periodVisits,
    required this.periodEntries,
    required this.productiveCounts,
    required this.reproductiveCounts,
    required this.reproductiveChartItems,
    required this.lactationThirds,
    required this.parityChartItems,
    required this.rateItems,
    required this.monthlySchedule,
    required this.agendaItems,
    required this.visitHistoryRows,
    required this.animalRows,
    required this.observations,
  });

  final DashboardMetricsModel metrics;
  final _DashboardRelatedData data;
  final List<UserSummaryModel>? users;
  final bool usersLoading;
  final bool usersError;
  final List<PropertySummaryModel> properties;
  final PropertySummaryModel? selectedProperty;
  final DashboardPeriodFilter period;
  final DateTime now;
  final _DateRange range;
  final List<_AnimalRecord> records;
  final List<VisitSummaryModel> periodVisits;
  final List<_VisitEntryRecord> periodEntries;
  final _ProductiveCounts productiveCounts;
  final List<_SituationCount> reproductiveCounts;
  final List<_ChartCountItem> reproductiveChartItems;
  final List<_ChartCountItem> lactationThirds;
  final List<_ChartCountItem> parityChartItems;
  final List<_RateItem> rateItems;
  final List<_MonthlyScheduleRow> monthlySchedule;
  final List<_AgendaItem> agendaItems;
  final List<_VisitHistoryRow> visitHistoryRows;
  final List<_AnimalDetailRow> animalRows;
  final List<_ObservationItem> observations;

  bool get isPropertyView => selectedProperty != null;

  int get activeVeterinarians {
    if (users == null || usersLoading || usersError) return 0;
    return users!.where((user) {
      return user.status == UserStatus.active &&
          user.perfil.toUpperCase() == 'VETERINARIO';
    }).length;
  }

  List<_MetricItem> get mainMetrics {
    final totalAnimals = isPropertyView
        ? data.animals.length
        : metrics.totalAnimais;

    // Dados integrados ao back-end: total de propriedades, total de animais,
    // taxa de servico e taxa de prenhez. Dados apenas front-end: classificacoes
    // produtivas/reprodutivas derivadas de animals/visits.
    final items = <_MetricItem>[
      if (!isPropertyView)
        _MetricItem(
          label: 'Propriedades atendidas',
          value: _formatCount(metrics.totalPropriedades),
          color: _ChartColors.primary,
        ),
      _MetricItem(
        label: isPropertyView ? 'Animais da fazenda' : 'Animais acompanhados',
        value: _formatCount(totalAnimals),
        color: _ChartColors.success,
      ),
      _MetricItem(
        label: 'Vacas em lactação',
        value: _formatCount(productiveCounts.lactating),
        color: _ChartColors.info,
      ),
      _MetricItem(
        label: 'Vacas secas',
        value: _formatCount(productiveCounts.dry),
        color: _ChartColors.warning,
      ),
      _MetricItem(
        label: 'Novilhas',
        value: _formatCount(productiveCounts.heifers),
        color: _ChartColors.purple,
      ),
    ];

    return items;
  }

  factory _DashboardInsights.from({
    required DashboardMetricsModel metrics,
    required _DashboardRelatedData data,
    required List<UserSummaryModel>? users,
    required bool usersLoading,
    required bool usersError,
    required List<PropertySummaryModel> properties,
    required PropertySummaryModel? selectedProperty,
    required DashboardPeriodFilter period,
    required DateTime now,
  }) {
    final range = _rangeFor(period, now);
    final periodVisits = data.visits
        .where((visit) => range.contains(visit.dataVisita))
        .toList(growable: false);
    final periodEntries = _visitEntryRecords(periodVisits);
    final records = _animalRecords(data.animals, data.visits);
    final productiveCounts = _ProductiveCounts.from(records);
    final reproductiveCounts = _buildReproductiveCounts(records);

    return _DashboardInsights(
      metrics: metrics,
      data: data,
      users: users,
      usersLoading: usersLoading,
      usersError: usersError,
      properties: properties,
      selectedProperty: selectedProperty,
      period: period,
      now: now,
      range: range,
      records: records,
      periodVisits: periodVisits,
      periodEntries: periodEntries,
      productiveCounts: productiveCounts,
      reproductiveCounts: reproductiveCounts,
      reproductiveChartItems: _buildReproductiveChartItems(reproductiveCounts),
      lactationThirds: _buildLactationThirds(records),
      parityChartItems: _buildParityChartItems(records),
      rateItems: _buildRateItems(metrics, records, periodEntries),
      monthlySchedule: _buildMonthlySchedule(records, range, now),
      agendaItems: _buildAgendaItems(
        visits: data.visits,
        records: records,
        properties: properties,
        selectedProperty: selectedProperty,
        now: now,
      ),
      visitHistoryRows: _buildVisitHistoryRows(
        visits: periodVisits,
        properties: properties,
        selectedProperty: selectedProperty,
      ),
      animalRows: records
          .map((record) => _AnimalDetailRow.from(record, now))
          .toList(growable: false),
      observations: _buildVisitObservations(periodVisits),
    );
  }
}

class _MetricItem {
  const _MetricItem({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;
}

class _AnimalRecord {
  const _AnimalRecord({
    required this.animal,
    required this.latestEntry,
    required this.latestVisit,
  });

  final AnimalSummaryModel animal;
  final VisitAnimalEntryModel? latestEntry;
  final VisitSummaryModel? latestVisit;
}

class _VisitEntryRecord {
  const _VisitEntryRecord({required this.visit, required this.entry});

  final VisitSummaryModel visit;
  final VisitAnimalEntryModel entry;
}

class _ProductiveCounts {
  const _ProductiveCounts({
    required this.lactating,
    required this.dry,
    required this.heifers,
  });

  final int lactating;
  final int dry;
  final int heifers;

  factory _ProductiveCounts.from(List<_AnimalRecord> records) {
    var lactating = 0;
    var dry = 0;
    var heifers = 0;

    for (final record in records) {
      switch (_productiveStatusFor(record)) {
        case _ProductiveStatus.lactating:
          lactating++;
        case _ProductiveStatus.dry:
          dry++;
        case _ProductiveStatus.heifer:
          heifers++;
        case _ProductiveStatus.other:
          break;
      }
    }

    return _ProductiveCounts(lactating: lactating, dry: dry, heifers: heifers);
  }
}

class _SituationCount {
  const _SituationCount({
    required this.kind,
    required this.label,
    required this.count,
  });

  final _SituationKind kind;
  final String label;
  final int count;
}

class _ChartCountItem {
  const _ChartCountItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class _RateItem {
  const _RateItem({
    required this.label,
    required this.value,
    required this.color,
    required this.shortLabel,
  });

  final String label;
  final double? value;
  final Color color;
  final String shortLabel;
}

class _MonthlyScheduleRow {
  const _MonthlyScheduleRow({
    required this.month,
    required this.monthLabel,
    required this.dryOff,
    required this.prepartum,
    required this.births,
  });

  final DateTime month;
  final String monthLabel;
  final int dryOff;
  final int prepartum;
  final int births;
}

class _AgendaItem {
  const _AgendaItem({
    required this.date,
    required this.type,
    required this.property,
    required this.animalCode,
    required this.description,
  });

  final DateTime? date;
  final String type;
  final String property;
  final String? animalCode;
  final String description;
}

class _VisitHistoryRow {
  const _VisitHistoryRow({
    required this.date,
    required this.property,
    required this.veterinarian,
    required this.animals,
    required this.observations,
  });

  final String date;
  final String property;
  final String veterinarian;
  final String animals;
  final String observations;
}

class _ObservationItem {
  const _ObservationItem({required this.label, required this.count});

  final String label;
  final int count;
}

class _AnimalDetailRow {
  const _AnimalDetailRow({
    required this.matriz,
    required this.idade,
    required this.ultimoParto,
    required this.situacaoProdutiva,
    required this.situacaoReprodutiva,
    required this.reproductiveBadgeType,
    required this.decisaoObservacao,
    required this.dataUltimaIa,
    required this.numeroIas,
    required this.diasPrenhez,
    required this.del,
    required this.diasParaSecar,
    required this.previsaoSecagem,
    required this.dataPreParto,
    required this.previsaoParto,
  });

  final String matriz;
  final String idade;
  final String ultimoParto;
  final String situacaoProdutiva;
  final String situacaoReprodutiva;
  final StatusBadgeType reproductiveBadgeType;
  final String decisaoObservacao;
  final String dataUltimaIa;
  final String numeroIas;
  final String diasPrenhez;
  final String del;
  final String diasParaSecar;
  final String previsaoSecagem;
  final String dataPreParto;
  final String previsaoParto;

  factory _AnimalDetailRow.from(_AnimalRecord record, DateTime now) {
    final animal = record.animal;
    final entry = record.latestEntry;
    final status = _reproductiveStatusFor(record);
    final productiveStatus = _productiveStatusLabel(
      _productiveStatusFor(record),
    );
    final decision = _firstText([
      entry?.decisao,
      entry?.diagnostico,
      animal.historicoReprodutivo,
    ]);
    final daysPregnant =
        entry?.diasPrenhez ??
        _daysSinceIf(
          status == AnimalReproductiveStatus.pregnant,
          entry?.dataUltimaIa,
          now,
        );
    final daysToDry =
        entry?.diasParaSecar ?? _daysUntil(entry?.previsaoSecagem, now);

    return _AnimalDetailRow(
      matriz: _animalCodeLabel(animal.codigo),
      idade: _ageLabel(animal.dataNascimento, entry?.idadeMeses, now),
      ultimoParto: formatDate(animal.dataUltimoParto),
      situacaoProdutiva: productiveStatus,
      situacaoReprodutiva: status.label,
      reproductiveBadgeType: _reproductiveStatusBadgeType(status),
      decisaoObservacao: _dashIfBlank(decision),
      dataUltimaIa: formatDate(entry?.dataUltimaIa),
      numeroIas: _formatNullableInt(entry?.numeroIaRecebida),
      diasPrenhez: _formatNullableInt(daysPregnant),
      del: _formatNullableInt(entry?.del ?? animal.diasEmLactacao),
      diasParaSecar: _formatNullableInt(daysToDry),
      previsaoSecagem: formatDate(entry?.previsaoSecagem),
      dataPreParto: formatDate(entry?.dataPreParto),
      previsaoParto: formatDate(entry?.previsaoParto),
    );
  }
}

class _DateRange {
  const _DateRange({this.start, this.end});

  final DateTime? start;
  final DateTime? end;

  bool contains(DateTime? date) {
    if (date == null) return false;
    final value = _dateOnly(date);
    if (start != null && value.isBefore(_dateOnly(start!))) return false;
    if (end != null && value.isAfter(_dateOnly(end!))) return false;
    return true;
  }
}

enum _SituationKind {
  pregnant,
  empty,
  protocol,
  inseminated,
  waitingDiagnosis,
  voluntaryWaiting,
  discard,
}

enum _ProductiveStatus { lactating, dry, heifer, other }

class _ChartColors {
  const _ChartColors._();

  static const primary = Color(0xFF005115);
  static const success = Color(0xFF177930);
  static const info = Color(0xFF008B5E);
  static const warning = Color(0xFFE86D00);
  static const danger = Color(0xFFD11F1F);
  static const neutral = Color(0xFF3F4843);
  static const purple = Color(0xFF6D28D9);
  static const deepBlue = Color(0xFF0B2F6B);
  static const blue = Color(0xFF155EEF);
  static const cyanBlue = Color(0xFF0369A1);
  static const indigo = Color(0xFF3730A3);
}

List<_SituationCount> _buildReproductiveCounts(List<_AnimalRecord> records) {
  return [
    _SituationCount(
      kind: _SituationKind.pregnant,
      label: 'Prenha',
      count: records.where((record) {
        return _reproductiveStatusFor(record) ==
            AnimalReproductiveStatus.pregnant;
      }).length,
    ),
    _SituationCount(
      kind: _SituationKind.empty,
      label: 'Vazia',
      count: records.where((record) {
        return _reproductiveStatusFor(record) == AnimalReproductiveStatus.empty;
      }).length,
    ),
    _SituationCount(
      kind: _SituationKind.protocol,
      label: 'Em protocolo',
      count: records.where(_hasProtocol).length,
    ),
    _SituationCount(
      kind: _SituationKind.inseminated,
      label: 'Inseminada ST',
      count: records.where(_isInseminatedSt).length,
    ),
    _SituationCount(
      kind: _SituationKind.waitingDiagnosis,
      label: 'Aguardando DG',
      count: records.where(_awaitingPregnancyDiagnosis).length,
    ),
    _SituationCount(
      kind: _SituationKind.voluntaryWaiting,
      label: 'PEV',
      count: records.where(_isVoluntaryWaitingPeriod).length,
    ),
    _SituationCount(
      kind: _SituationKind.discard,
      label: 'Descarte',
      count: records.where(_hasDiscardDecision).length,
    ),
  ];
}

List<_ChartCountItem> _buildReproductiveChartItems(
  List<_SituationCount> counts,
) {
  return [
    for (final count in counts)
      _ChartCountItem(
        label: count.label,
        value: count.count,
        color: _situationColor(count.kind),
      ),
  ];
}

int _chartTotal(List<_ChartCountItem> items) {
  return items.fold<int>(0, (sum, item) => sum + item.value);
}

String _percentLabel(int value, int total) {
  if (total <= 0 || value <= 0) return '';
  final percent = value / total * 100;
  if (percent < 1) return '<1%';
  return '${percent.round()}%';
}

List<_ChartCountItem> _buildLactationThirds(List<_AnimalRecord> records) {
  // Dados apenas front-end: terço de lactação calculado a partir de DEL
  // vindo de animals/visits; ainda nao ha endpoint consolidado para o grafico.
  var first = 0;
  var second = 0;
  var third = 0;
  var noDel = 0;

  for (final record in records) {
    final del = record.latestEntry?.del ?? record.animal.diasEmLactacao;
    if (del == null) {
      noDel++;
    } else if (del <= 100) {
      first++;
    } else if (del <= 200) {
      second++;
    } else {
      third++;
    }
  }

  return const [
        _ChartCountItem(
          label: '1o terço',
          value: 0,
          color: _ChartColors.primary,
        ),
        _ChartCountItem(label: '2o terço', value: 0, color: _ChartColors.info),
        _ChartCountItem(
          label: '3o terço',
          value: 0,
          color: _ChartColors.warning,
        ),
        _ChartCountItem(
          label: 'Sem DEL',
          value: 0,
          color: _ChartColors.neutral,
        ),
      ]
      .asMap()
      .entries
      .map((entry) {
        final value = switch (entry.key) {
          0 => first,
          1 => second,
          2 => third,
          _ => noDel,
        };
        final item = entry.value;
        return _ChartCountItem(
          label: item.label,
          value: value,
          color: item.color,
        );
      })
      .toList(growable: false);
}

List<_ChartCountItem> _buildParityChartItems(List<_AnimalRecord> records) {
  // Dados apenas front-end: multípara/novilha é derivado de numeroLactacao,
  // data do último parto e categoria; o back-end ainda nao retorna paridade
  // consolidada para este grafico.
  var heifers = 0;
  var multiparous = 0;

  for (final record in records) {
    final animal = record.animal;
    final text = [
      animal.categoria,
      record.latestEntry?.situacaoProdutiva ?? '',
    ].join(' ').normalize();
    final isHeifer =
        text.contains('novilh') ||
        (animal.numeroLactacao <= 0 && animal.dataUltimoParto == null);

    if (isHeifer) {
      heifers++;
    } else {
      multiparous++;
    }
  }

  return const [
        _ChartCountItem(
          label: 'Multíparas',
          value: 0,
          color: _ChartColors.purple,
        ),
        _ChartCountItem(label: 'Novilhas', value: 0, color: _ChartColors.warning),
      ]
      .asMap()
      .entries
      .map((entry) {
        final value = entry.key == 0 ? multiparous : heifers;
        final item = entry.value;
        return _ChartCountItem(
          label: item.label,
          value: value,
          color: item.color,
        );
      })
      .toList(growable: false);
}

List<_RateItem> _buildRateItems(
  DashboardMetricsModel metrics,
  List<_AnimalRecord> records,
  List<_VisitEntryRecord> entries,
) {
  // Dados integrados ao back-end: taxa de serviço e taxa de prenhez.
  // Dados apenas front-end: taxa de concepção e concepção por IA derivadas
  // dos status/lançamentos de visitas. Pendente de integração: concepção IATF
  // depende de campo/endpoint especifico.
  return [
    _RateItem(
      label: 'Taxa de serviço',
      shortLabel: 'Serviço',
      value: metrics.taxaServico,
      color: _ChartColors.deepBlue,
    ),
    _RateItem(
      label: 'Taxa de concepção',
      shortLabel: 'Concepção',
      value: _conceptionRate(records),
      color: _ChartColors.blue,
    ),
    _RateItem(
      label: 'Taxa de prenhez',
      shortLabel: 'Prenhez',
      value: metrics.taxaPrenhez,
      color: _ChartColors.cyanBlue,
    ),
    _RateItem(
      label: 'Concepção por IA',
      shortLabel: 'IA',
      value: _iaConceptionRate(entries),
      color: _ChartColors.indigo,
    ),
  ];
}

List<_MonthlyScheduleRow> _buildMonthlySchedule(
  List<_AnimalRecord> records,
  _DateRange range,
  DateTime now,
) {
  // Dados apenas front-end: calendario mensal calculado a partir das datas
  // registradas nas visitas; ainda nao ha endpoint agregado de secagem,
  // pre-parto e partos previstos por mes.
  final visibleRange = range.start == null && range.end == null
      ? _DateRange(
          start: _dateOnly(now),
          end: DateTime(now.year, now.month + 12, 0),
        )
      : range;
  final months = <DateTime, _MutableMonthCount>{};

  void add(DateTime? date, void Function(_MutableMonthCount count) update) {
    if (date == null || !visibleRange.contains(date)) return;
    final month = DateTime(date.year, date.month);
    update(months.putIfAbsent(month, () => _MutableMonthCount()));
  }

  for (final record in records) {
    final entry = record.latestEntry;
    add(entry?.previsaoSecagem, (count) => count.dryOff++);
    add(entry?.dataPreParto, (count) => count.prepartum++);
    add(entry?.previsaoParto, (count) => count.births++);
  }

  final rows = months.entries.map((entry) {
    return _MonthlyScheduleRow(
      month: entry.key,
      monthLabel: _monthLabel(entry.key),
      dryOff: entry.value.dryOff,
      prepartum: entry.value.prepartum,
      births: entry.value.births,
    );
  }).toList();
  rows.sort((a, b) => a.month.compareTo(b.month));
  return rows;
}

List<_AgendaItem> _buildAgendaItems({
  required List<VisitSummaryModel> visits,
  required List<_AnimalRecord> records,
  required List<PropertySummaryModel> properties,
  required PropertySummaryModel? selectedProperty,
  required DateTime now,
}) {
  // Dados integrados ao back-end: visitas cadastradas e campos de visita.
  // Dados apenas front-end: agenda derivada dos campos dos animais nas visitas.
  // Pendente de integracao: datas futuras especificas de protocolo.
  final items = <_AgendaItem>[];
  final today = _dateOnly(now);
  final limit = today.add(const Duration(days: 60));
  final propertyById = {
    for (final property in properties) property.id: property,
  };

  bool inWindow(DateTime? date) {
    if (date == null) return false;
    final value = _dateOnly(date);
    return !value.isBefore(today) && !value.isAfter(limit);
  }

  String propertyForVisit(VisitSummaryModel visit) {
    return selectedProperty?.nome ??
        propertyById[visit.idPropriedade]?.nome ??
        visit.idExternoPropriedade;
  }

  String propertyForAnimal(AnimalSummaryModel animal) {
    return selectedProperty?.nome ??
        propertyById[animal.idPropriedade]?.nome ??
        animal.idExternoPropriedade;
  }

  for (final visit in visits) {
    if (!inWindow(visit.dataVisita)) continue;
    items.add(
      _AgendaItem(
        date: visit.dataVisita,
        type: 'Visita cadastrada',
        property: propertyForVisit(visit),
        animalCode: null,
        description: visit.veterinarioResponsavel == null
            ? 'Visita técnica agendada.'
            : 'Visita com ${visit.veterinarioResponsavel}.',
      ),
    );
  }

  for (final record in records) {
    final entry = record.latestEntry;
    if (entry == null) continue;
    final property = propertyForAnimal(record.animal);
    final animalCode = _animalCodeLabel(record.animal.codigo);

    void addAnimalAction({
      required DateTime? date,
      required String type,
      required String description,
      bool includeWithoutDate = false,
    }) {
      if (!includeWithoutDate && !inWindow(date)) return;
      items.add(
        _AgendaItem(
          date: date,
          type: type,
          property: property,
          animalCode: animalCode,
          description: description,
        ),
      );
    }

    addAnimalAction(
      date: entry.previsaoParto,
      type: 'Parto previsto',
      description: 'Conferir preparação para parto.',
    );
    addAnimalAction(
      date: entry.dataPreParto,
      type: 'Pré-parto',
      description: 'Mover para lote ou rotina de pré-parto.',
    );
    addAnimalAction(
      date: entry.previsaoSecagem,
      type: 'Secagem',
      description: 'Programar secagem conforme calendário.',
    );
    addAnimalAction(
      date: entry.dataUltimaIa?.add(const Duration(days: 30)),
      type: 'Diagnóstico gestacional',
      description: 'Animal aguardando DG.',
    );
    if (_hasProtocol(record)) {
      addAnimalAction(
        date: record.latestVisit?.dataVisita,
        type: 'Animal em protocolo',
        description: 'Acompanhar protocolo registrado.',
        includeWithoutDate: record.latestVisit?.dataVisita == null,
      );
    }
    if (_decisionPending(record)) {
      addAnimalAction(
        date: null,
        type: 'Decisão pendente',
        description: 'Revisar decisão ou observação do animal.',
        includeWithoutDate: true,
      );
    }
  }

  items.sort((a, b) {
    final dateA = a.date;
    final dateB = b.date;
    if (dateA == null && dateB == null) return a.type.compareTo(b.type);
    if (dateA == null) return 1;
    if (dateB == null) return -1;
    return dateA.compareTo(dateB);
  });

  return items.take(18).toList(growable: false);
}

List<_VisitHistoryRow> _buildVisitHistoryRows({
  required List<VisitSummaryModel> visits,
  required List<PropertySummaryModel> properties,
  required PropertySummaryModel? selectedProperty,
}) {
  final propertyById = {
    for (final property in properties) property.id: property,
  };

  String propertyForVisit(VisitSummaryModel visit) {
    return selectedProperty?.nome ??
        propertyById[visit.idPropriedade]?.nome ??
        visit.idExternoPropriedade;
  }

  return visits
      .take(12)
      .map((visit) {
        return _VisitHistoryRow(
          date: formatDate(visit.dataVisita),
          property: _dashIfBlank(propertyForVisit(visit)),
          veterinarian: _dashIfBlank(visit.veterinarioResponsavel),
          animals: _formatCount(visit.animais.length),
          observations: _dashIfBlank(visit.observacoes),
        );
      })
      .toList(growable: false);
}

List<_ObservationItem> _buildVisitObservations(List<VisitSummaryModel> visits) {
  final counts = <String, int>{
    'Pos-parto': 0,
    'Vacas atrasadas': 0,
    'Abortos': 0,
    'Cistos': 0,
    'Infusoes': 0,
    'Descartes': 0,
    'Protocolos pendentes': 0,
  };

  void scan(String? value) {
    final text = (value ?? '').normalize();
    if (text.isEmpty) return;
    if (text.contains('pos-parto') ||
        text.contains('pos parto') ||
        text.contains('puerper')) {
      counts['Pos-parto'] = counts['Pos-parto']! + 1;
    }
    if (text.contains('atrasad')) {
      counts['Vacas atrasadas'] = counts['Vacas atrasadas']! + 1;
    }
    if (text.contains('aborto')) {
      counts['Abortos'] = counts['Abortos']! + 1;
    }
    if (text.contains('cisto')) {
      counts['Cistos'] = counts['Cistos']! + 1;
    }
    if (text.contains('infus')) {
      counts['Infusoes'] = counts['Infusoes']! + 1;
    }
    if (text.contains('descarte')) {
      counts['Descartes'] = counts['Descartes']! + 1;
    }
    if (text.contains('protocolo') && text.contains('pend')) {
      counts['Protocolos pendentes'] = counts['Protocolos pendentes']! + 1;
    }
  }

  for (final visit in visits) {
    scan(visit.observacoes);
    for (final entry in visit.animais) {
      scan(entry.decisao);
      scan(entry.diagnostico);
      scan(entry.situacaoReprodutiva);
    }
  }

  return counts.entries
      .where((entry) => entry.value > 0)
      .map((entry) => _ObservationItem(label: entry.key, count: entry.value))
      .toList(growable: false);
}

List<_AnimalRecord> _animalRecords(
  List<AnimalSummaryModel> animals,
  List<VisitSummaryModel> visits,
) {
  return animals
      .map((animal) {
        VisitAnimalEntryModel? latestEntry;
        VisitSummaryModel? latestVisit;

        for (final visit in visits) {
          for (final entry in visit.animais) {
            if (_entryMatchesAnimal(entry, animal)) {
              latestEntry = entry;
              latestVisit = visit;
              break;
            }
          }
          if (latestEntry != null) break;
        }

        return _AnimalRecord(
          animal: animal,
          latestEntry: latestEntry,
          latestVisit: latestVisit,
        );
      })
      .toList(growable: false);
}

List<_VisitEntryRecord> _visitEntryRecords(List<VisitSummaryModel> visits) {
  return [
    for (final visit in visits)
      for (final entry in visit.animais)
        _VisitEntryRecord(visit: visit, entry: entry),
  ];
}

bool _entryMatchesAnimal(
  VisitAnimalEntryModel entry,
  AnimalSummaryModel animal,
) {
  if (entry.animalId != 0 && entry.animalId == animal.id) return true;
  if (entry.animalCodigo.trim().isNotEmpty &&
      entry.animalCodigo.trim() == animal.codigo.trim()) {
    return true;
  }
  if (entry.animalIdExterno.trim().isNotEmpty &&
      entry.animalIdExterno.trim() == animal.idExterno.trim()) {
    return true;
  }
  return false;
}

AnimalReproductiveStatus _reproductiveStatusFor(_AnimalRecord record) {
  return IndicadorReprodutivoCalculator.resolveAnimalStatus(
    record.animal,
    extraTexts: [
      record.latestEntry?.situacaoProdutiva,
      record.latestEntry?.situacaoReprodutiva,
      record.latestEntry?.decisao,
      record.latestEntry?.diagnostico,
    ],
  );
}

_ProductiveStatus _productiveStatusFor(_AnimalRecord record) {
  final text = _normalizedRecordText(record);
  final animal = record.animal;
  final category = animal.categoria.normalize();
  final reproductiveStatus = _reproductiveStatusFor(record);

  if (text.contains('novilha') || category.contains('novilha')) {
    return _ProductiveStatus.heifer;
  }
  if (text.contains('seca') ||
      reproductiveStatus == AnimalReproductiveStatus.dry) {
    return _ProductiveStatus.dry;
  }
  if (text.contains('lact') ||
      animal.diasEmLactacao != null ||
      animal.numeroLactacao > 0) {
    return _ProductiveStatus.lactating;
  }
  return _ProductiveStatus.other;
}

String _productiveStatusLabel(_ProductiveStatus status) {
  return switch (status) {
    _ProductiveStatus.lactating => 'Lactante',
    _ProductiveStatus.dry => 'Seca',
    _ProductiveStatus.heifer => 'Novilha',
    _ProductiveStatus.other => 'Não informada',
  };
}

bool _hasProtocol(_AnimalRecord record) {
  final text = _normalizedRecordText(record);
  return text.contains('protoc') || text.contains('iatf');
}

bool _isInseminatedSt(_AnimalRecord record) {
  final text = _normalizedRecordText(record);
  if (text.contains('inseminada st') || text.contains('ia st')) return true;
  return _reproductiveStatusFor(record) ==
          AnimalReproductiveStatus.inseminated &&
      !text.contains('iatf') &&
      !text.contains('protoc');
}

bool _awaitingPregnancyDiagnosis(_AnimalRecord record) {
  final text = _normalizedRecordText(record);
  if (text.contains('aguard') && text.contains('dg')) return true;
  if (text.contains('diagnostico') && text.contains('gest')) return true;
  return _reproductiveStatusFor(record) == AnimalReproductiveStatus.inseminated;
}

bool _isVoluntaryWaitingPeriod(_AnimalRecord record) {
  final text = _normalizedRecordText(record);
  final del = record.latestEntry?.del ?? record.animal.diasEmLactacao;
  if (text.contains('pev') || text.contains('espera volunt')) return true;
  return del != null &&
      del <= 60 &&
      _productiveStatusFor(record) == _ProductiveStatus.lactating;
}

bool _hasDiscardDecision(_AnimalRecord record) {
  final text = _normalizedRecordText(record);
  return text.contains('descarte') ||
      record.animal.status == AnimalStatus.sold ||
      record.animal.status == AnimalStatus.inactive;
}

bool _decisionPending(_AnimalRecord record) {
  final entry = record.latestEntry;
  if (entry == null) return false;
  final decision = entry.decisao?.trim();
  final diagnosis = entry.diagnostico?.trim();
  return (decision == null || decision.isEmpty) &&
      (diagnosis == null || diagnosis.isEmpty) &&
      _reproductiveStatusFor(record) == AnimalReproductiveStatus.pending;
}

String _normalizedRecordText(_AnimalRecord record) {
  final entry = record.latestEntry;
  return [
    record.animal.categoria,
    record.animal.historicoReprodutivo ?? '',
    entry?.situacaoProdutiva ?? '',
    entry?.situacaoReprodutiva ?? '',
    entry?.decisao ?? '',
    entry?.diagnostico ?? '',
  ].join(' ').normalize();
}

double? _conceptionRate(List<_AnimalRecord> records) {
  return IndicadorReprodutivoCalculator.pregnancyRateFromStatuses(
    records.map(_reproductiveStatusFor),
  );
}

double? _iaConceptionRate(List<_VisitEntryRecord> entries) {
  return IndicadorReprodutivoCalculator.iaConceptionRateFromEntries(
    entries.map((record) => record.entry),
  );
}

bool _animalMatchesPropertyId(AnimalSummaryModel animal, int? propertyId) {
  return propertyId == null || animal.idPropriedade == propertyId;
}

bool _visitMatchesPropertyId(VisitSummaryModel visit, int? propertyId) {
  return propertyId == null || visit.idPropriedade == propertyId;
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

_DateRange _rangeFor(DashboardPeriodFilter period, DateTime now) {
  final today = _dateOnly(now);

  return switch (period) {
    DashboardPeriodFilter.last30 => _DateRange(
      start: today.subtract(const Duration(days: 29)),
      end: today,
    ),
    DashboardPeriodFilter.last90 => _DateRange(
      start: today.subtract(const Duration(days: 89)),
      end: today,
    ),
    DashboardPeriodFilter.currentMonth => _DateRange(
      start: DateTime(today.year, today.month),
      end: DateTime(today.year, today.month + 1, 0),
    ),
    DashboardPeriodFilter.currentYear => _DateRange(
      start: DateTime(today.year),
      end: DateTime(today.year, 12, 31),
    ),
    DashboardPeriodFilter.all => const _DateRange(),
  };
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

int _daysBetween(DateTime from, DateTime to) {
  return _dateOnly(to).difference(_dateOnly(from)).inDays;
}

int? _daysUntil(DateTime? date, DateTime now) {
  if (date == null) return null;
  return _daysBetween(now, date);
}

int? _daysSinceIf(bool condition, DateTime? date, DateTime now) {
  if (!condition || date == null) return null;
  return _daysBetween(date, now);
}

int _monthsBetween(DateTime from, DateTime to) {
  var months = (to.year - from.year) * 12 + to.month - from.month;
  if (to.day < from.day) months--;
  return months;
}

String _monthLabel(DateTime date) {
  const months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];
  return '${months[date.month - 1]}/${date.year}';
}

String _ageLabel(DateTime? birthDate, num? ageMonths, DateTime now) {
  final rawMonths =
      ageMonths ?? (birthDate == null ? null : _monthsBetween(birthDate, now));
  final months = rawMonths?.round();
  if (months == null) return '--';
  if (months < 24) return '$months meses';
  final years = months ~/ 12;
  final remainingMonths = months % 12;
  if (remainingMonths == 0) return '$years anos';
  return '$years a $remainingMonths m';
}

String _animalCodeLabel(String code) {
  final text = code.trim();
  if (text.isEmpty) return '--';
  if (text.startsWith('#')) return text;
  return '#$text';
}

String _firstText(List<String?> values) {
  for (final value in values) {
    final text = value?.trim();
    if (text != null && text.isNotEmpty) return text;
  }
  return '';
}

String _dashIfBlank(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return '--';
  return text;
}

String _formatCount(int value) {
  return formatInteger(value);
}

String _formatNullableInt(int? value) {
  if (value == null) return '--';
  return value.toString();
}


String _recordsLabel(
  int count, {
  required String singular,
  required String plural,
}) {
  return '$count ${count == 1 ? singular : plural} no filtro atual';
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

Color _situationColor(_SituationKind kind) {
  return switch (kind) {
    _SituationKind.pregnant => _ChartColors.success,
    _SituationKind.empty => _ChartColors.danger,
    _SituationKind.protocol => _ChartColors.purple,
    _SituationKind.inseminated => _ChartColors.info,
    _SituationKind.waitingDiagnosis => _ChartColors.warning,
    _SituationKind.voluntaryWaiting => _ChartColors.primary,
    _SituationKind.discard => _ChartColors.neutral,
  };
}

class _MutableMonthCount {
  int dryOff = 0;
  int prepartum = 0;
  int births = 0;
}
