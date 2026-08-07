import 'dart:math' as math;

import 'package:cysvet_app/core/constants/app_constants.dart';
import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/core/enums/user_status.dart';
import 'package:cysvet_app/core/widgets/app_button.dart';
import 'package:cysvet_app/core/widgets/app_card.dart';
import 'package:cysvet_app/core/widgets/app_dropdown.dart';
import 'package:cysvet_app/core/widgets/app_table.dart';
import 'package:cysvet_app/core/widgets/loading_state.dart';
import 'package:cysvet_app/core/widgets/property_filter_card.dart';
import 'package:cysvet_app/core/widgets/status_badge.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_shell.dart';
import '../../../../app/theme.dart';
import '../../../../core/presentation/async_value_view.dart';
import '../../../../core/utils/formatters.dart';
import '../../../animals/application/animals_provider.dart';
import '../../../animals/data/animals_repository.dart';
import '../../../animals/domain/animal_summary_model.dart';
import '../../../auth/application/auth_state.dart';
import '../../../auth/domain/auth_session_model.dart';
import '../../../indicators/indicador_reprodutivo_calculator.dart';
import '../../../properties/application/properties_provider.dart';
import '../../../properties/domain/property_summary_model.dart';
import '../../../users/application/users_provider.dart';
import '../../../users/domain/user_summary_model.dart';
import '../../../visits/application/visits_provider.dart';
import '../../../visits/data/visits_repository.dart';
import '../../../visits/domain/visit_summary_model.dart';
import '../../../visits/presentation/pages/visit_report_page.dart';
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

      PropertySummaryModel? selectedProperty;
      if (propertyId != null) {
        final availableProperties = await ref.watch(propertiesProvider.future);
        for (final property in availableProperties) {
          if (property.id == propertyId) {
            selectedProperty = property;
            break;
          }
        }
      }

      final visits =
          {
            for (final visit in remoteVisits)
              visit.id: localVisits[visit.id] ?? visit,
            ...localVisits,
          }.values.where((visit) {
            return _visitMatchesProperty(
              visit,
              propertyId: propertyId,
              propertyExternalId: selectedProperty?.idExterno,
            );
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

class _DashboardToolbar extends StatefulWidget {
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
  State<_DashboardToolbar> createState() => _DashboardToolbarState();
}

class _DashboardToolbarState extends State<_DashboardToolbar> {
  bool _filtersOpen = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.sizeOf(context).width < MOBILE_WIDTH;
        final stacked = constraints.maxWidth < 720;

        final propertyFilter = PropertySegmentedFilter(
          properties: widget.properties,
          selectedPropertyId: widget.selectedPropertyId,
          generalText: 'Geral',
          propertyText: 'Por propriedade',
          onChanged: widget.onPropertyChanged,
        );

        final periodFilter = AppDropdown<DashboardPeriodFilter>(
          value: widget.period,
          labelText: 'Período',
          onChanged: widget.onPeriodChanged,
          options: DashboardPeriodFilter.values
              .map(
                (item) => AppDropdownOption<DashboardPeriodFilter>(
                  label: item.label,
                  value: item,
                ),
              )
              .toList(growable: false),
        );

        final filterButton = Tooltip(
          message: _filtersOpen ? 'Ocultar período' : 'Mostrar período',
          child: AppButton(
            height: 40,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: propertyFilter),
                  const SizedBox(width: 10),
                  filterButton,
                ],
              ),
              if (_filtersOpen) ...[
                const SizedBox(height: 10),
                SizedBox(width: 230, child: periodFilter),
              ],
            ],
          );
        }

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
          _ChartsSection(insights: insights),
          const SizedBox(height: 22),
          _AgendaSection(
            items: insights.agendaItems,
            showProperty: !isPropertyView,
          ),
          const SizedBox(height: 22),
          _MonthlyCalendarSection(rows: insights.monthlySchedule),
          if (isPropertyView) ...[
            const SizedBox(height: 22),
            _AnimalDetailsSection(rows: insights.animalRows),
            const SizedBox(height: 22),
            _VisitObservationsSection(items: insights.observations),
          ],
          const SizedBox(height: 22),
          _VisitHistorySection(rows: insights.visitHistoryRows),
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

    final primary = AppTheme.primary2For(theme.brightness);

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
                      primary,
                      primary.withValues(alpha: 0.92),
                      primary.withValues(alpha: 0.78),
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
                      primary.withValues(alpha: 0.96),
                      primary.withValues(alpha: 0.70),
                      primary.withValues(alpha: 0.08),
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
                        fontWeight: FontWeight.w500,
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
          _RateEvolutionChart(
            items: insights.rateItems,
            points: insights.rateTrendPoints,
          ),
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
          Expanded(
            child: _RateEvolutionChart(
              items: insights.rateItems,
              points: insights.rateTrendPoints,
            ),
          ),
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
        'Resumo do rebanho',
        style: theme.textTheme.titleSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Principais totais no filtro atual.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    ];

    final rows = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(top: isMobile ? 12 : 14, bottom: 12),
          child: Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.24),
          ),
        ),
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0)
            Padding(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
              child: Divider(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.24),
              ),
            ),
          _MetricSummaryRow(item: items[index]),
        ],
      ],
    );

    return AppCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...header,
          if (isMobile) rows else Expanded(child: rows),
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
  if (text.contains('propriedade')) return Icons.agriculture_outlined;
  if (text.contains('animal')) return MdiIcons.cow;
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
          'Agenda reprodutiva',
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
    return AppTable<_AgendaItem>(
      rows: items,
      emptyMessage: 'Nenhuma ação reprodutiva encontrada.',
      footerLabel: _agendaRecordsLabel(items.length),
      mobileBreakpoint: 760,
      borderRadius: 16,
      shadow: false,
      enableRowHover: false,
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
          alignment: Alignment.centerLeft,
          headerAlignment: Alignment.center,
          cellBuilder: (context, item) => _AgendaDateCell(item: item),
        ),
        AppTableColumn<_AgendaItem>(
          label: 'Tipo',
          flex: 3,
          headerAlignment: Alignment.center,
          cellBuilder: (context, item) => Text(item.type),
        ),
        AppTableColumn<_AgendaItem>(
          label: showProperty ? 'Propriedade' : 'Animal',
          flex: 4,
          headerAlignment: Alignment.center,
          cellBuilder: (context, item) => Text(
            _dashIfBlank(showProperty ? item.property : item.animalCode),
          ),
        ),
      ],
    );
  }
}

class _AgendaDateCell extends StatelessWidget {
  const _AgendaDateCell({required this.item});

  final _AgendaItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.event_available_rounded,
          size: 17,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            formatDate(item.date),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
        const _SectionTitle(
          'Indicadores reprodutivos',
          subtitle:
              'Taxa de serviço, concepção, prenhez e concepção por IA no período.',
        ),
        const SizedBox(height: 14),
        _ReproductiveRateCards(items: insights.rateItems),
        const SizedBox(height: 20),
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
                  desktopRowHeight: 328,
                  children: [
                    _ReproductiveDistributionChart(
                      items: insights.reproductiveChartItems,
                    ),
                    _LactationThirdChart(items: insights.lactationThirds),
                    _ParityDonutChart(items: insights.parityChartItems),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReproductiveRateCards extends StatelessWidget {
  const _ReproductiveRateCards({required this.items});

  final List<_RateItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1180
            ? 4
            : width >= 760
            ? 2
            : 1;

        return _EqualHeightCardGrid(
          columns: columns,
          desktopRowHeight: 126,
          children: [for (final item in items) _RateIndicatorCard(item: item)],
        );
      },
    );
  }
}

class _RateIndicatorCard extends StatelessWidget {
  const _RateIndicatorCard({required this.item});

  final _RateItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final delta = _rateTargetDelta(item);

    return AppCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      shadow: false,
      borderColor: colorScheme.outline.withValues(alpha: 0.28),
      child: Row(
        children: [
          _DonutProgressIndicator(value: item.value, color: item.color),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatWholePercent(item.value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ibmPlexMono(
                    textStyle: theme.textTheme.headlineSmall,
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ).copyWith(fontFamilyFallback: const ['monospace']),
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(delta.icon, size: 15, color: delta.color),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        delta.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: delta.color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReproductiveDistributionChart extends StatelessWidget {
  const _ReproductiveDistributionChart({required this.items});

  final List<_ChartCountItem> items;

  @override
  Widget build(BuildContext context) {
    final total = _chartTotal(items);
    final hasData = total > 0;

    return _ChartCard(
      title: 'Distribuição reprodutiva',
      subtitle: _classifiedMatricesLabel(total),
      subtitleBottomSpacing: 18,
      child: hasData
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  if (index > 0) const SizedBox(height: 16),
                  _DistributionProgressRow(item: items[index], total: total),
                ],
              ],
            )
          : const SizedBox(
              height: 190,
              child: _EmptyChart(message: 'Sem registros reprodutivos.'),
            ),
    );
  }
}

class _LactationThirdChart extends StatelessWidget {
  const _LactationThirdChart({required this.items});

  final List<_ChartCountItem> items;

  @override
  Widget build(BuildContext context) {
    final hasData = items.any((item) => item.value > 0);
    final maxValue = items.fold<int>(1, (max, item) {
      return math.max(max, item.value);
    });

    return _ChartCard(
      title: 'Terço de lactação',
      subtitle: 'Vacas em lactação por DEL.',
      centerContent: true,
      subtitleBottomSpacing: 20,
      child: hasData
          ? SizedBox(
              height: 185,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    if (index > 0) const SizedBox(width: 16),
                    Expanded(
                      child: _LactationBar(
                        item: items[index],
                        maxValue: maxValue,
                      ),
                    ),
                  ],
                ],
              ),
            )
          : const SizedBox(
              height: 185,
              child: _EmptyChart(message: 'Sem dados de DEL.'),
            ),
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
      title: 'Multíparas e novilhas',
      subtitle: 'Composição do rebanho ativo.',
      centerContent: true,
      subtitleBottomSpacing: 20,
      child: hasData
          ? LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 360;
                final chartDimension = math.min(
                  compact ? 160.0 : 176.0,
                  constraints.maxWidth,
                );
                final total = _chartTotal(items);
                final chart = SizedBox.square(
                  dimension: chartDimension,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: chartDimension * 0.28,
                      sectionsSpace: 1.5,
                      pieTouchData: PieTouchData(enabled: false),
                      sections: [
                        for (final item in items)
                          if (item.value > 0)
                            PieChartSectionData(
                              value: item.value.toDouble(),
                              color: item.color,
                              radius: chartDimension * 0.22,
                              title: '',
                            ),
                      ],
                    ),
                  ),
                );

                if (compact) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      chart,
                      const SizedBox(height: 16),
                      _ParityLegend(items: items, total: total),
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(child: chart),
                    const SizedBox(width: 28),
                    Flexible(
                      child: _ParityLegend(items: items, total: total),
                    ),
                  ],
                );
              },
            )
          : const SizedBox(
              height: 185,
              child: _EmptyChart(message: 'Sem dados de categoria do rebanho.'),
            ),
    );
  }
}

// ignore: unused_element
class _RateLineChart extends StatelessWidget {
  const _RateLineChart({required this.items});

  final List<_RateItem> items;

  @override
  Widget build(BuildContext context) {
    final chartItems = items.where((item) => item.value != null).toList();

    return _ChartCard(
      title: 'Evolução das taxas',
      subtitle: 'Serviço, concepção e prenhez do período.',
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
                              color: _ChartColors.primary,
                              barWidth: 4,
                              isStrokeCapRound: true,
                              belowBarData: BarAreaData(
                                show: true,
                                color: _ChartColors.primary.withValues(
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

class _RateEvolutionChart extends StatelessWidget {
  const _RateEvolutionChart({required this.items, required this.points});

  final List<_RateItem> items;
  final List<_MonthlyRatePoint> points;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(3).toList(growable: false);
    final hasData = points.any((point) {
      return point.service != null ||
          point.conception != null ||
          point.pregnancy != null;
    });

    return AppCard(
      borderRadius: 16,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
      shadow: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final isCompact = constraints.maxWidth < 620;
          final hasBoundedHeight =
              constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
          final chartHeight = hasBoundedHeight
              ? math.max(
                  150.0,
                  constraints.maxHeight - (isCompact ? 112.0 : 72.0),
                )
              : isCompact
              ? 230.0
              : 268.0;

          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Evolução das taxas',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Serviço, concepção e prenhez nos últimos 6 meses.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isCompact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: 12),
                    _RateEvolutionLegend(items: visibleItems),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: titleBlock),
                    const SizedBox(width: 16),
                    _RateEvolutionLegend(items: visibleItems),
                  ],
                ),
              const SizedBox(height: 28),
              if (!hasData)
                SizedBox(
                  height: chartHeight,
                  child: const _EmptyChart(
                    message: 'Sem indicadores calculados.',
                  ),
                )
              else
                SizedBox(
                  height: chartHeight,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: math.max(1, points.length - 1).toDouble(),
                      minY: 0,
                      maxY: 1,
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (spots) {
                            return spots.map((spot) {
                              final index = spot.x.round();
                              if (index < 0 ||
                                  index >= points.length ||
                                  visibleItems.isEmpty) {
                                return null;
                              }

                              final itemIndex =
                                  spot.barIndex < visibleItems.length
                                  ? spot.barIndex
                                  : visibleItems.length - 1;
                              final item = visibleItems[itemIndex];
                              final monthLabel = _shortMonthLabel(
                                points[index].month,
                              );

                              return LineTooltipItem(
                                '$monthLabel - ${item.shortLabel}\n${formatPercent(spot.y)}',
                                (theme.textTheme.bodySmall ?? const TextStyle())
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
                          color: colorScheme.outline.withValues(alpha: 0.42),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        leftTitles: const AxisTitles(),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.round();
                              if (index < 0 || index >= points.length) {
                                return const SizedBox.shrink();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _shortMonthLabel(points[index].month),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        _rateEvolutionLine(
                          color: _ChartColors.primary,
                          values: points.map((point) => point.service),
                        ),
                        _rateEvolutionLine(
                          color: _ChartColors.blue,
                          values: points.map((point) => point.conception),
                        ),
                        _rateEvolutionLine(
                          color: _ChartColors.amber,
                          values: points.map((point) => point.pregnancy),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RateEvolutionLegend extends StatelessWidget {
  const _RateEvolutionLegend({required this.items});

  final List<_RateItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        for (final item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 4,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                item.shortLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

LineChartBarData _rateEvolutionLine({
  required Color color,
  required Iterable<double?> values,
}) {
  final spots = values
      .toList(growable: false)
      .asMap()
      .entries
      .where((entry) => entry.value != null)
      .map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value!.clamp(0.0, 1.0));
      })
      .toList(growable: false);

  return LineChartBarData(
    spots: spots,
    isCurved: false,
    preventCurveOverShooting: true,
    color: color,
    barWidth: 4,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: false),
  );
}

class _DonutProgressIndicator extends StatelessWidget {
  const _DonutProgressIndicator({required this.value, required this.color});

  final double? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedValue = value?.clamp(0.0, 1.0).toDouble();

    return SizedBox.square(
      dimension: 70,
      child: CustomPaint(
        painter: _DonutProgressPainter(
          value: normalizedValue,
          color: color,
          trackColor: colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.74,
          ),
        ),
      ),
    );
  }
}

class _DonutProgressPainter extends CustomPainter {
  const _DonutProgressPainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  final double? value;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = math.max(8.0, size.shortestSide * 0.13);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    final normalized = value;
    if (normalized == null || normalized <= 0) return;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * normalized,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutProgressPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}

class _DistributionProgressRow extends StatelessWidget {
  const _DistributionProgressRow({required this.item, required this.total});

  final _ChartCountItem item;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percent = total <= 0 ? 0.0 : item.value / total;
    final isMobile = MediaQuery.sizeOf(context).width < MOBILE_WIDTH;
    final valueLabel =
        '${_formatCount(item.value)} (${(percent * 100).round()}%)';

    return Row(
      children: [
        SizedBox(
          width: isMobile ? 116 : 134,
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 14,
              value: percent.clamp(0.0, 1.0),
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.78,
              ),
              color: item.color,
            ),
          ),
        ),
        const SizedBox(width: 14),
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: isMobile ? 62 : 76,
            maxWidth: isMobile ? 82 : 104,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                valueLabel,
                maxLines: 1,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LactationBar extends StatelessWidget {
  const _LactationBar({required this.item, required this.maxValue});

  final _ChartCountItem item;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final normalized = maxValue <= 0 ? 0.0 : item.value / maxValue;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: 22,
              child: Center(
                child: Text(
                  _formatCount(item.value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, barConstraints) {
                  final chartHeight = math.max(1.0, barConstraints.maxHeight);
                  final barHeight = item.value <= 0
                      ? math.min(8.0, chartHeight)
                      : math.min(
                          chartHeight,
                          math.max(24.0, chartHeight * normalized),
                        );

                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: Center(
                child: Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ParityLegend extends StatelessWidget {
  const _ParityLegend({required this.items, required this.total});

  final List<_ChartCountItem> items;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const SizedBox(height: 18),
          _ParityLegendItem(item: items[index], total: total),
        ],
      ],
    );
  }
}

class _ParityLegendItem extends StatelessWidget {
  const _ParityLegendItem({required this.item, required this.total});

  final _ChartCountItem item;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percent = _percentLabel(item.value, total);

    return Semantics(
      label: percent.isEmpty
          ? '${item.label}, ${item.value}'
          : '${item.label}, ${item.value}, $percent',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 11,
            height: 11,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatCount(item.value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    height: 1,
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
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
              overflow: allowWrap
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
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
          'Calendário mensal',
          subtitle: 'Secagem, pré-parto e partos previstos por mês.',
        ),
        const SizedBox(height: 10),
        _MonthlyCalendarTable(rows: rows),
      ],
    );
  }
}

class _MonthlyCalendarTable extends StatelessWidget {
  const _MonthlyCalendarTable({required this.rows});

  final List<_MonthlyScheduleRow> rows;

  @override
  Widget build(BuildContext context) {
    return AppTable<_MonthlyScheduleRow>(
      rows: rows,
      emptyMessage: 'Sem eventos mensais no período.',
      mobileBreakpoint: 760,
      borderRadius: 16,
      shadow: false,
      enableRowHover: false,
      equalColumnWidth: true,
      mobileTitleBuilder: (context, row) {
        return Text(
          _fullMonthLabel(row.month),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        );
      },
      columns: [
        AppTableColumn<_MonthlyScheduleRow>(
          label: 'Mês',
          flex: 4,
          alignment: Alignment.centerLeft,
          headerAlignment: Alignment.center,
          cellBuilder: (context, row) => Text(
            _fullMonthLabel(row.month),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        AppTableColumn<_MonthlyScheduleRow>(
          label: 'Vacas secas',
          flex: 2,
          headerAlignment: Alignment.center,
          cellBuilder: (context, row) => _MonthlyTableValue(
            value: row.dryOff,
            color: _ChartColors.primary,
          ),
        ),
        AppTableColumn<_MonthlyScheduleRow>(
          label: 'Pré-parto',
          flex: 2,
          headerAlignment: Alignment.center,
          cellBuilder: (context, row) => _MonthlyTableValue(
            value: row.prepartum,
            color: _ChartColors.amber,
          ),
        ),
        AppTableColumn<_MonthlyScheduleRow>(
          label: 'Partos',
          flex: 2,
          headerAlignment: Alignment.center,
          cellBuilder: (context, row) =>
              _MonthlyTableValue(value: row.births, color: _ChartColors.green),
        ),
      ],
    );
  }
}

class _MonthlyTableValue extends StatelessWidget {
  const _MonthlyTableValue({required this.value, required this.color});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      _formatCount(value),
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _VisitHistorySection extends StatelessWidget {
  const _VisitHistorySection({required this.rows});

  final List<_VisitHistoryRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          'Histórico de visitas',
          subtitle: 'Visitas recentes no período selecionado.',
        ),
        const SizedBox(height: 10),
        _VisitHistoryList(rows: rows),
      ],
    );
  }
}

class _VisitHistoryList extends StatelessWidget {
  const _VisitHistoryList({required this.rows});

  final List<_VisitHistoryRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      borderRadius: 16,
      padding: EdgeInsets.zero,
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Nenhuma visita encontrada.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0)
                Divider(
                  height: 1,
                  color: colorScheme.outline.withValues(alpha: 0.22),
                ),
              _VisitHistoryListRow(
                row: rows[index],
                onTap: () => _openDashboardVisit(context, rows[index]),
              ),
            ],
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.22),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: _CompactTableFooter(
              label: _recordsLabel(
                rows.length,
                singular: 'visita encontrada',
                plural: 'visitas encontradas',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitHistoryListRow extends StatelessWidget {
  const _VisitHistoryListRow({required this.row, required this.onTap});

  final _VisitHistoryRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1080;

        return Semantics(
          button: true,
          label: 'Abrir visita de ${row.property} em ${row.date}',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              hoverColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.045),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 14 : 18,
                  vertical: 12,
                ),
                child: compact
                    ? _CompactDashboardVisitRow(row: row)
                    : _DesktopDashboardVisitRow(row: row),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DesktopDashboardVisitRow extends StatelessWidget {
  const _DesktopDashboardVisitRow({required this.row});

  final _VisitHistoryRow row;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 4, child: _DashboardVisitIdentity(row: row)),
        const SizedBox(width: 18),
        Expanded(
          flex: 2,
          child: _VisitHistoryText(label: 'Data', value: row.date),
        ),
        const SizedBox(width: 18),
        Expanded(
          flex: 3,
          child: _VisitHistoryText(
            label: 'Protocolo',
            value: row.protocol,
            maxLines: 2,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          flex: 4,
          child: _VisitHistoryText(
            label: 'Próximo passo',
            value: row.nextStep,
            maxLines: 2,
          ),
        ),
        const SizedBox(width: 18),
        _VisitHistoryMetric(value: row.animals, label: 'Animais'),
        const SizedBox(width: 18),
        _VisitHistoryMetric(
          value: row.pregnancyRate,
          label: 'Prenhez',
          highlighted: true,
        ),
        const SizedBox(width: 14),
        _VisitHistoryArrow(),
      ],
    );
  }
}

class _CompactDashboardVisitRow extends StatelessWidget {
  const _CompactDashboardVisitRow({required this.row});

  final _VisitHistoryRow row;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _DashboardVisitIdentity(row: row)),
            const SizedBox(width: 12),
            _VisitHistoryArrow(),
          ],
        ),
        const SizedBox(height: 10),
        Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.18)),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _VisitHistoryCompactField(
                label: 'Data',
                value: row.date,
                width: double.infinity,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _VisitHistoryCompactField(
                label: 'Protocolo',
                value: row.protocol,
                width: double.infinity,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _VisitHistoryCompactField(
          label: 'Próximo passo',
          value: row.nextStep,
          width: double.infinity,
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _VisitHistoryMetric(value: row.animals, label: 'Animais'),
            const SizedBox(width: 28),
            _VisitHistoryMetric(
              value: row.pregnancyRate,
              label: 'Prenhez',
              highlighted: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardVisitIdentity extends StatelessWidget {
  const _DashboardVisitIdentity({required this.row});

  final _VisitHistoryRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark
        ? AppTheme.syncBadgeDarkForegroundColor
        : AppTheme.syncBadgeForegroundColor;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isDark ? 0.16 : 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(Icons.description_outlined, size: 19, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.property,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                row.veterinarian,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VisitHistoryText extends StatelessWidget {
  const _VisitHistoryText({
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: label,
      child: Text(
        value,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }
}

class _VisitHistoryCompactField extends StatelessWidget {
  const _VisitHistoryCompactField({
    required this.label,
    required this.value,
    this.width = 120,
  });

  final String label;
  final String value;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitHistoryMetric extends StatelessWidget {
  const _VisitHistoryMetric({
    required this.value,
    required this.label,
    this.highlighted = false,
  });

  final String value;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final valueColor = highlighted ? _ChartColors.green : colorScheme.onSurface;

    return SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitHistoryArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right_rounded,
      size: 24,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}

void _openDashboardVisit(BuildContext context, _VisitHistoryRow row) {
  final currentRoute = GoRouterState.of(context).uri.toString();
  final returnRoute = currentRoute.isEmpty ? '/dashboard' : currentRoute;
  final location = Uri(
    path: '/visitas/${row.visit.id}/detalhes',
    queryParameters: {'retorno': returnRoute},
  ).toString();
  final property = row.propertyModel;

  if (property == null) {
    context.go(location);
    return;
  }

  context.go(
    location,
    extra: VisitReportRouteData(
      visit: row.visit,
      propertyName: property.nome,
      property: property,
      returnRoute: returnRoute,
    ),
  );
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
          AppButton(
            text: 'Tentar novamente',
            icon: const Icon(Icons.refresh_rounded, size: 18),
            color: AppTheme.primary1For(theme.brightness),
            height: 40,
            onPressed: onRetry,
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
    required this.rateTrendPoints,
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
  final List<_MonthlyRatePoint> rateTrendPoints;
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
        label: isPropertyView ? 'Animais da fazenda' : 'Animais monitorados',
        value: _formatCount(totalAnimals),
        color: _ChartColors.indigo,
      ),
      _MetricItem(
        label: 'Vacas em lactação',
        value: _formatCount(productiveCounts.lactating),
        color: _ChartColors.blue,
      ),
      _MetricItem(
        label: 'Vacas secas',
        value: _formatCount(productiveCounts.dry),
        color: _ChartColors.green,
      ),
      _MetricItem(
        label: 'Novilhas',
        value: _formatCount(productiveCounts.heifers),
        color: _ChartColors.amber,
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
      rateTrendPoints: _buildRateTrendPoints(
        metrics: metrics,
        visits: data.visits,
        records: records,
        now: now,
      ),
      monthlySchedule: _buildMonthlySchedule(records, range, now),
      agendaItems: _buildAgendaItems(
        visits: data.visits,
        records: records,
        properties: properties,
        selectedProperty: selectedProperty,
        now: now,
      ),
      visitHistoryRows: _buildVisitHistoryRows(
        visits: data.visits,
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
    required this.target,
  });

  final String label;
  final double? value;
  final Color color;
  final String shortLabel;
  final double target;
}

class _RateTargetDelta {
  const _RateTargetDelta({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

class _MonthlyRatePoint {
  const _MonthlyRatePoint({
    required this.month,
    required this.service,
    required this.conception,
    required this.pregnancy,
  });

  final DateTime month;
  final double? service;
  final double? conception;
  final double? pregnancy;
}

class _MonthlyScheduleRow {
  const _MonthlyScheduleRow({
    required this.month,
    required this.dryOff,
    required this.prepartum,
    required this.births,
  });

  final DateTime month;
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
    required this.visit,
    required this.propertyModel,
    required this.date,
    required this.property,
    required this.veterinarian,
    required this.protocol,
    required this.nextStep,
    required this.animals,
    required this.pregnancyRate,
  });

  final VisitSummaryModel visit;
  final PropertySummaryModel? propertyModel;
  final String date;
  final String property;
  final String veterinarian;
  final String protocol;
  final String nextStep;
  final String animals;
  final String pregnancyRate;
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

  static const primary = AppTheme.primary2Color;
  static const accent = AppTheme.accentColor;
  static const green = AppTheme.greenColor;
  static const amber = AppTheme.amberColor;
  static const blue = AppTheme.blueColor;
  static const indigo = AppTheme.indigoColor;
  static const rose = AppTheme.roseColor;
  static const neutral = AppTheme.bodyTextColor;
}

List<_SituationCount> _buildReproductiveCounts(List<_AnimalRecord> records) {
  final counts = {for (final kind in _SituationKind.values) kind: 0};

  for (final record in records) {
    final kind = _classifyReproductiveSituation(record);
    counts[kind] = (counts[kind] ?? 0) + 1;
  }

  return [
    _SituationCount(
      kind: _SituationKind.pregnant,
      label: 'Prenha',
      count: counts[_SituationKind.pregnant] ?? 0,
    ),
    _SituationCount(
      kind: _SituationKind.empty,
      label: 'Vazia',
      count: counts[_SituationKind.empty] ?? 0,
    ),
    _SituationCount(
      kind: _SituationKind.protocol,
      label: 'Em protocolo',
      count: counts[_SituationKind.protocol] ?? 0,
    ),
    _SituationCount(
      kind: _SituationKind.inseminated,
      label: 'Inseminada',
      count: counts[_SituationKind.inseminated] ?? 0,
    ),
    _SituationCount(
      kind: _SituationKind.waitingDiagnosis,
      label: 'Aguardando DG',
      count: counts[_SituationKind.waitingDiagnosis] ?? 0,
    ),
    _SituationCount(
      kind: _SituationKind.voluntaryWaiting,
      label: 'Seca / PEV',
      count: counts[_SituationKind.voluntaryWaiting] ?? 0,
    ),
    _SituationCount(
      kind: _SituationKind.discard,
      label: 'Outros',
      count: counts[_SituationKind.discard] ?? 0,
    ),
  ];
}

_SituationKind _classifyReproductiveSituation(_AnimalRecord record) {
  final status = _reproductiveStatusFor(record);

  if (status == AnimalReproductiveStatus.pregnant) {
    return _SituationKind.pregnant;
  }
  if (status == AnimalReproductiveStatus.empty) {
    return _SituationKind.empty;
  }
  if (_hasProtocol(record) || status == AnimalReproductiveStatus.protocol) {
    return _SituationKind.protocol;
  }
  if (_isInseminatedSt(record) ||
      status == AnimalReproductiveStatus.inseminated ||
      status == AnimalReproductiveStatus.inseminatedSt) {
    return _SituationKind.inseminated;
  }
  if (_awaitingPregnancyDiagnosis(record) ||
      status == AnimalReproductiveStatus.waitingDiagnosis) {
    return _SituationKind.waitingDiagnosis;
  }
  if (_hasDiscardDecision(record)) {
    return _SituationKind.discard;
  }
  if (_isVoluntaryWaitingPeriod(record) ||
      status == AnimalReproductiveStatus.pev ||
      status == AnimalReproductiveStatus.dry) {
    return _SituationKind.voluntaryWaiting;
  }
  return _SituationKind.discard;
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
        _ChartCountItem(label: '2o terço', value: 0, color: _ChartColors.blue),
        _ChartCountItem(label: '3o terço', value: 0, color: _ChartColors.amber),
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
          color: _ChartColors.primary,
        ),
        _ChartCountItem(label: 'Novilhas', value: 0, color: _ChartColors.blue),
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
      color: _ChartColors.primary,
      target: 0.65,
    ),
    _RateItem(
      label: 'Taxa de concepção',
      shortLabel: 'Concepção',
      value: _conceptionRate(records),
      color: _ChartColors.blue,
      target: 0.40,
    ),
    _RateItem(
      label: 'Taxa de prenhez',
      shortLabel: 'Prenhez',
      value: metrics.taxaPrenhez,
      color: _ChartColors.amber,
      target: 0.25,
    ),
    _RateItem(
      label: 'Concepção por IA',
      shortLabel: 'IA',
      value: _iaConceptionRate(entries),
      color: _ChartColors.indigo,
      target: 0.35,
    ),
  ];
}

List<_MonthlyRatePoint> _buildRateTrendPoints({
  required DashboardMetricsModel metrics,
  required List<VisitSummaryModel> visits,
  required List<_AnimalRecord> records,
  required DateTime now,
}) {
  final months = List<DateTime>.generate(6, (index) {
    return DateTime(now.year, now.month - 5 + index);
  });
  final fallbackConception = _conceptionRate(records);

  return months
      .map((month) {
        final monthVisits = visits
            .where((visit) {
              final date = visit.dataVisita;
              return date != null &&
                  date.year == month.year &&
                  date.month == month.month;
            })
            .toList(growable: false);
        final entries = _visitEntryRecords(monthVisits);
        final service = _monthlyServiceRate(entries) ?? metrics.taxaServico;
        final conception =
            _monthlyConceptionRate(entries) ?? fallbackConception;
        final pregnancy = _monthlyPregnancyRate(entries) ?? metrics.taxaPrenhez;

        return _MonthlyRatePoint(
          month: month,
          service: _normalizeRate(service),
          conception: _normalizeRate(conception),
          pregnancy: _normalizeRate(pregnancy),
        );
      })
      .toList(growable: false);
}

double? _monthlyServiceRate(List<_VisitEntryRecord> entries) {
  final denominator = entries.where((record) {
    return record.entry.hasCollectedData;
  }).length;
  if (denominator == 0) return null;

  final serviced = entries.where((record) {
    final entry = record.entry;
    final reproductiveText = [
      entry.situacaoReprodutiva,
      entry.diagnostico,
      entry.decisao,
    ].whereType<String>().join(' ').normalize();

    return entry.dataUltimaIa != null ||
        (entry.numeroIaRecebida ?? 0) > 0 ||
        reproductiveText.contains('insemin');
  }).length;

  return serviced / denominator;
}

double? _monthlyConceptionRate(List<_VisitEntryRecord> entries) {
  return IndicadorReprodutivoCalculator.pregnancyRateFromStatuses(
    entries.map((record) {
      final entry = record.entry;
      return IndicadorReprodutivoCalculator.resolveStatusFromTexts(
        texts: [entry.situacaoReprodutiva, entry.diagnostico, entry.decisao],
      );
    }),
  );
}

double? _monthlyPregnancyRate(List<_VisitEntryRecord> entries) {
  final service = _monthlyServiceRate(entries);
  final conception = _monthlyConceptionRate(entries);
  if (service == null || conception == null) return null;
  return service * conception;
}

double? _normalizeRate(double? value) {
  if (value == null || !value.isFinite) return null;
  return value.clamp(0.0, 1.0).toDouble();
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
  final propertyByExternalId = {
    for (final property in properties)
      if (property.idExterno.trim().isNotEmpty)
        property.idExterno.trim(): property,
  };

  PropertySummaryModel? propertyForVisit(VisitSummaryModel visit) {
    return selectedProperty ??
        propertyById[visit.idPropriedade] ??
        propertyByExternalId[visit.idExternoPropriedade.trim()];
  }

  return visits
      .take(12)
      .map((visit) {
        final property = propertyForVisit(visit);
        final propertyName = _firstText([
          property?.nome,
          visit.idExternoPropriedade,
        ]);
        final veterinarian = _firstText([
          visit.veterinarioResponsavel,
          visit.nomeUsuario,
        ]);

        return _VisitHistoryRow(
          visit: visit,
          propertyModel: property,
          date: formatDate(visit.dataVisita),
          property: _dashIfBlank(propertyName),
          veterinarian: _dashIfBlank(veterinarian),
          protocol: _visitProtocolLabel(visit),
          nextStep: _visitNextStepText(visit),
          animals: _formatCount(visit.animais.length),
          pregnancyRate: _formatWholePercent(_visitPregnancyRate(visit)),
        );
      })
      .toList(growable: false);
}

double? _visitPregnancyRate(VisitSummaryModel visit) {
  return IndicadorReprodutivoCalculator.pregnancyRateFromStatuses(
    visit.animais.map((entry) {
      return IndicadorReprodutivoCalculator.resolveStatusFromTexts(
        texts: [entry.situacaoReprodutiva, entry.diagnostico, entry.decisao],
      );
    }),
  );
}

String _visitProtocolLabel(VisitSummaryModel visit) {
  if (visit.animais.isEmpty) return 'Visita técnica';

  final hasDiagnosis = visit.animais.any((entry) {
    return _nonBlankText(entry.diagnostico) != null ||
        _visitEntryIsPregnant(entry) ||
        _visitEntryIsEmpty(entry);
  });
  final hasProtocol = visit.animais.any((entry) {
    return _nonBlankText(entry.decisao) != null ||
        entry.dataUltimaIa != null ||
        entry.numeroIaRecebida != null;
  });

  if (hasProtocol && hasDiagnosis) return 'IATF + diagnóstico';
  if (hasProtocol) return 'IATF / protocolo';
  if (hasDiagnosis) return 'Diagnóstico reprodutivo';
  return 'Conferência técnica';
}

String _visitNextStepText(VisitSummaryModel visit) {
  final steps = <_VisitHistoryNextStep>[];

  for (final entry in visit.animais) {
    final identification = _firstText([
      entry.animalCodigo,
      entry.animalIdExterno,
      'animal',
    ]);

    void add(DateTime? date, String text) {
      if (date == null) return;
      steps.add(_VisitHistoryNextStep(date: date, text: text));
    }

    add(
      entry.previsaoSecagem,
      '${formatDate(entry.previsaoSecagem)} - Secagem de $identification',
    );
    add(
      entry.dataPreParto,
      '${formatDate(entry.dataPreParto)} - Pré-parto de $identification',
    );
    add(
      entry.previsaoParto,
      '${formatDate(entry.previsaoParto)} - Parto de $identification',
    );
  }

  steps.sort((a, b) => a.date.compareTo(b.date));
  if (steps.isNotEmpty) return steps.first.text;

  return _dashIfBlank(visit.observacoes);
}

bool _visitEntryIsPregnant(VisitAnimalEntryModel entry) {
  if (_visitEntryIsEmpty(entry)) return false;
  if (entry.diasPrenhez != null) return true;

  return _visitTextContainsAny(_visitEntryReproductiveText(entry), const [
    'prenhe',
    'prenha',
    'prenhez',
    'positivo',
    'gestante',
  ]);
}

bool _visitEntryIsEmpty(VisitAnimalEntryModel entry) {
  return _visitTextContainsAny(_visitEntryReproductiveText(entry), const [
    'vazia',
    'vazio',
    'negativo',
    'nao prenha',
    'nao gestante',
  ]);
}

String _visitEntryReproductiveText(VisitAnimalEntryModel entry) {
  return [
    entry.situacaoReprodutiva,
    entry.decisao,
    entry.diagnostico,
  ].whereType<String>().join(' ');
}

bool _visitTextContainsAny(String value, List<String> terms) {
  final normalized = value.normalize();
  return terms.any((term) => normalized.contains(term.normalize()));
}

String? _nonBlankText(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

class _VisitHistoryNextStep {
  const _VisitHistoryNextStep({required this.date, required this.text});

  final DateTime date;
  final String text;
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

bool _visitMatchesProperty(
  VisitSummaryModel visit, {
  required int? propertyId,
  required String? propertyExternalId,
}) {
  if (propertyId == null) return true;
  if (visit.idPropriedade == propertyId) return true;

  final expectedExternalId = propertyExternalId?.trim();
  if (expectedExternalId == null || expectedExternalId.isEmpty) return false;

  return visit.idExternoPropriedade.trim() == expectedExternalId;
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

String _fullMonthLabel(DateTime date) {
  const months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String _shortMonthLabel(DateTime date) {
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
  return months[date.month - 1];
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

String _formatWholePercent(double? value) {
  if (value == null) return '--';
  return '${(value.clamp(0.0, 1.0) * 100).round()}%';
}

String _classifiedMatricesLabel(int count) {
  return count == 1
      ? '1 matriz classificada.'
      : '$count matrizes classificadas.';
}

_RateTargetDelta _rateTargetDelta(_RateItem item) {
  final value = item.value;
  if (value == null) {
    return const _RateTargetDelta(
      label: 'Sem meta calculada',
      color: _ChartColors.neutral,
      icon: Icons.trending_flat_rounded,
    );
  }

  final points = ((value - item.target) * 100).round();
  if (points == 0) {
    return const _RateTargetDelta(
      label: '0 p.p. vs meta',
      color: _ChartColors.neutral,
      icon: Icons.trending_flat_rounded,
    );
  }

  final isPositive = points > 0;
  return _RateTargetDelta(
    label: '${isPositive ? '+' : '-'} ${points.abs()} p.p. vs meta',
    color: isPositive ? _ChartColors.accent : _ChartColors.rose,
    icon: isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
  );
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

String _agendaRecordsLabel(int count) {
  return '$count ${count == 1 ? 'ação reprodutiva encontrada' : 'ações reprodutivas encontradas'}';
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
    _SituationKind.pregnant => _ChartColors.primary,
    _SituationKind.empty => _ChartColors.rose,
    _SituationKind.protocol => _ChartColors.indigo,
    _SituationKind.inseminated => _ChartColors.blue,
    _SituationKind.waitingDiagnosis => _ChartColors.amber,
    _SituationKind.voluntaryWaiting => _ChartColors.green,
    _SituationKind.discard => _ChartColors.neutral,
  };
}

class _MutableMonthCount {
  int dryOff = 0;
  int prepartum = 0;
  int births = 0;
}
