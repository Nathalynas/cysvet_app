import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../app/app_shell.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/presentation/app_scaffold_messenger.dart';
import '../../../core/presentation/async_value_view.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_table.dart';
import '../../auth/application/auth_state.dart';
import '../../auth/domain/auth_session_model.dart';
import '../../properties/application/properties_provider.dart';
import '../../properties/domain/property_summary_model.dart';
import '../application/visits_provider.dart';
import '../data/visits_repository.dart';
import '../domain/visit_summary_model.dart';

final visitReportDataProvider =
    FutureProvider.family<VisitReportRouteData, int>((ref, visitId) async {
      final localVisits = ref.watch(localVisitsProvider);
      final properties = await ref.watch(propertiesProvider.future);
      final visit = localVisits[visitId] ??
          await ref.watch(visitsRepositoryProvider).getById(visitId);

      final property = _firstWhereOrNull(
        properties,
        (item) => item.id == visit.idPropriedade,
      );
      final fallbackName = visit.idExternoPropriedade.trim().isEmpty
          ? 'Propriedade'
          : visit.idExternoPropriedade;

      return VisitReportRouteData(
        visit: visit,
        propertyName: property?.nome ?? fallbackName,
        property: property,
      );
    });

class VisitReportRouteData {
  const VisitReportRouteData({
    required this.visit,
    required this.propertyName,
    this.property,
    this.returnRoute,
  });

  final VisitSummaryModel visit;
  final String propertyName;
  final PropertySummaryModel? property;
  final String? returnRoute;
}

class _ReportTokens {
  const _ReportTokens._();

  static const documentWidth = 840.0;
  static const documentPadding = 40.0;
  static const contentWidth = documentWidth - (documentPadding * 2);
  static const summaryCardWidth = 100.0;
  static const summaryCardGap = 10.0;
  static const headerLogoWidth = 188.0;
  static const minZoom = 0.7;
  static const maxZoom = 2.0;
  static const zoomStep = 0.1;
  static const estimatedDocumentHeight = 1500.0;
}

enum _ReportPdfAction { share, download }

class VisitReportPage extends ConsumerWidget {
  const VisitReportPage({
    super.key,
    required this.visitId,
    this.initialData,
    this.returnRoute,
  });

  final int visitId;
  final VisitReportRouteData? initialData;
  final String? returnRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = initialData == null
        ? ref.watch(visitReportDataProvider(visitId))
        : AsyncValue<VisitReportRouteData>.data(initialData!);
    final session = ref.watch(authSessionProvider);
    final activeCompanyName = _cleanText(session?.activeCompany?.name);
    final currentUserName = _cleanText(session?.user.name);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        // TODO(frontend-only): Pagina de detalhes exibindo o relatorio como documento fixo.
        child: AsyncValueView<VisitReportRouteData>(
          value: value,
          loadingMessage: 'Carregando relatório...',
          onRetry: initialData == null
              ? () => ref.invalidate(visitReportDataProvider(visitId))
              : null,
          builder: (data) => _ReportPageContent(
            data: data,
            companyName: activeCompanyName,
            currentUserName: currentUserName,
            backRoute: _safeVisitReportBackRoute(
              data.returnRoute ?? returnRoute,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportPageContent extends StatelessWidget {
  const _ReportPageContent({
    required this.data,
    required this.companyName,
    required this.currentUserName,
    required this.backRoute,
  });

  final VisitReportRouteData data;
  final String? companyName;
  final String? currentUserName;
  final String backRoute;

  @override
  Widget build(BuildContext context) {
    final horizontal = PageTitle.horizontalPadding(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _ReportDocumentViewport(
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    final colorScheme = theme.colorScheme;
                    final isMobile =
                        MediaQuery.sizeOf(context).width < MOBILE_WIDTH;
                    final horizontal = PageTitle.horizontalPadding(context);

                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        isMobile ? 16 : 24,
                        horizontal,
                        isMobile ? 10 : 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Tooltip(
                            message: 'Voltar',
                            child: AppButton(
                              width: 38,
                              height: 38,
                              padding: EdgeInsets.zero,
                              borderRadius: 12,
                              shadow: true,
                              color: colorScheme.surface,
                              textColor: colorScheme.primary,
                              borderColor: colorScheme.outline.withValues(
                                alpha: 0.55,
                              ),
                              icon: Icon(
                                Icons.arrow_back,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              onPressed: () => context.go(backRoute),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Detalhes da visita',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontal,
                  ).copyWith(top: 10, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _ReportPdfActions(
                      visit: data.visit,
                      propertyName: data.propertyName,
                    ),
                  ),
                ),
              ],
            ),
            child: VisitReportCard(
              visit: data.visit,
              propertyName: data.propertyName,
              property: data.property,
              companyName: companyName,
              currentUserName: currentUserName,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportDocumentViewport extends StatefulWidget {
  const _ReportDocumentViewport({required this.child, this.header});

  final Widget child;
  final Widget? header;

  @override
  State<_ReportDocumentViewport> createState() =>
      _ReportDocumentViewportState();
}

class _ReportDocumentViewportState extends State<_ReportDocumentViewport> {
  final _verticalController = ScrollController();
  final _horizontalController = ScrollController();
  final _documentKey = GlobalKey();

  double _scale = 1;
  double? _documentHeight;

  @override
  void initState() {
    super.initState();
    _scheduleDocumentMeasure();
  }

  @override
  void didUpdateWidget(covariant _ReportDocumentViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleDocumentMeasure();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  void _scheduleDocumentMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final renderObject = _documentKey.currentContext?.findRenderObject();
      if (renderObject is! RenderBox) return;

      final nextHeight = renderObject.size.height;
      if (nextHeight <= 0) return;

      final currentHeight = _documentHeight;
      if (currentHeight != null && (currentHeight - nextHeight).abs() < 0.5) {
        return;
      }

      setState(() => _documentHeight = nextHeight);
    });
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (!HardwareKeyboard.instance.isControlPressed) return;

    GestureBinding.instance.pointerSignalResolver.register(event, (signal) {
      if (signal is! PointerScrollEvent) return;

      final direction = signal.scrollDelta.dy > 0 ? -1 : 1;
      final nextScale = (_scale + (direction * _ReportTokens.zoomStep))
          .clamp(_ReportTokens.minZoom, _ReportTokens.maxZoom)
          .toDouble();

      if (nextScale == _scale) return;
      setState(() => _scale = nextScale);
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleDocumentMeasure();

    final scaledWidth = _ReportTokens.documentWidth * _scale;
    final scaledHeight =
        (_documentHeight ?? _ReportTokens.estimatedDocumentHeight) * _scale;

    // TODO(frontend-only): Usar scroll horizontal/vertical quando a tela for menor que o documento.
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < MOBILE_WIDTH;

        final horizontalPadding = isMobile
            ? PageTitle.horizontalPadding(context)
            : 24.0;

        return Scrollbar(
          controller: _verticalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.header != null) widget.header!,

                Scrollbar(
                  controller: _horizontalController,
                  thumbVisibility: true,
                  notificationPredicate: (notification) {
                    return notification.metrics.axis == Axis.horizontal;
                  },
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          18,
                          horizontalPadding,
                          32,
                        ),
                        child: Align(
                          alignment: isMobile
                              ? Alignment.topLeft
                              : Alignment.topCenter,
                          child: Listener(
                            onPointerSignal: _handlePointerSignal,
                            child: SizedBox(
                              width: scaledWidth,
                              height: scaledHeight,
                              child: ClipRect(
                                child: Transform.scale(
                                  scale: _scale,
                                  alignment: Alignment.topLeft,
                                  child: OverflowBox(
                                    alignment: Alignment.topLeft,
                                    minWidth: _ReportTokens.documentWidth,
                                    maxWidth: _ReportTokens.documentWidth,
                                    minHeight: 0,
                                    maxHeight: double.infinity,
                                    child: SizedBox(
                                      width: _ReportTokens.documentWidth,
                                      child: KeyedSubtree(
                                        key: _documentKey,
                                        child: widget.child,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class VisitReportCard extends StatelessWidget {
  const VisitReportCard({
    super.key,
    required this.visit,
    required this.propertyName,
    this.companyName,
    this.currentUserName,
    this.property,
  });

  final VisitSummaryModel visit;
  final String propertyName;
  final String? companyName;
  final String? currentUserName;
  final PropertySummaryModel? property;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final data = _VisitReportData.fromVisit(
      visit: visit,
      propertyName: propertyName,
      property: property,
      companyName: companyName,
      currentUserName: currentUserName,
    );

    // TODO(frontend-only): Layout do relatorio nao deve ser responsivo internamente.
    return SizedBox(
      width: _ReportTokens.documentWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.24 : 0.08,
              ),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(_ReportTokens.documentPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ReportHeader(data: data),
              const SizedBox(height: 28),
              _ReportStatsGrid(stats: data.stats),
              const SizedBox(height: 30),
              _NextStepsSection(steps: data.nextSteps),
              const SizedBox(height: 24),
              _ProceduresSection(rows: data.procedures),
              const SizedBox(height: 24),
              _ConfirmedAnimalsSection(rows: data.animals),
              const SizedBox(height: 24),
              _ObservationsSection(observations: data.observations),
              const SizedBox(height: 30),
              _ReportFooter(data: data),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportPdfActions extends ConsumerStatefulWidget {
  const _ReportPdfActions({required this.visit, required this.propertyName});

  final VisitSummaryModel visit;
  final String propertyName;

  @override
  ConsumerState<_ReportPdfActions> createState() => _ReportPdfActionsState();
}

class _ReportPdfActionsState extends ConsumerState<_ReportPdfActions> {
  _ReportPdfAction? _runningAction;

  @override
  Widget build(BuildContext context) {
    final controllerBusy = ref.watch(visitsReportBusyProvider);
    final canUsePdf = widget.visit.id > 0;
    final isBusy = _runningAction != null || controllerBusy;
    final unavailableMessage = canUsePdf
        ? null
        : 'PDF disponivel apos sincronizar a visita.';

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: unavailableMessage ?? 'Compartilhar relatorio em PDF',
            child: AppButton(
              text: 'Compartilhar',
              outlined: true,
              height: 40,
              borderRadius: 10,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              borderColor: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.75),
              loading: _runningAction == _ReportPdfAction.share,
              disabled: !canUsePdf || isBusy,
              icon: const Icon(Icons.share_outlined, size: 18),
              onPressed: canUsePdf && !isBusy
                  ? () => _runPdfAction(_ReportPdfAction.share)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: unavailableMessage ?? 'Exportar relatorio em PDF',
            child: AppButton(
              text: 'Exportar PDF',
              height: 40,
              borderRadius: 10,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
              loading: _runningAction == _ReportPdfAction.download,
              disabled: !canUsePdf || isBusy,
              icon: const Icon(Icons.file_download_outlined, size: 18),
              onPressed: canUsePdf && !isBusy
                  ? () => _runPdfAction(_ReportPdfAction.download)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runPdfAction(_ReportPdfAction action) async {
    if (_runningAction != null || widget.visit.id <= 0) return;

    setState(() => _runningAction = action);

    try {
      final bytes = await ref
          .read(visitsControllerProvider)
          .downloadReportPdf(widget.visit.id);
      final fileName = _reportFileName(widget.visit);

      if (action == _ReportPdfAction.share) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: fileName,
          subject: 'Relatorio Tecnico de Visita',
          body: 'Relatorio tecnico da visita em ${widget.propertyName}.',
        );
      } else {
        await Printing.layoutPdf(name: fileName, onLayout: (_) async => bytes);
      }
    } catch (error) {
      showAppError(error);
    } finally {
      if (mounted) {
        setState(() => _runningAction = null);
      }
    }
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.data});

  final _VisitReportData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = Text(
      'Relatório Técnico de Visita',
      style: theme.textTheme.headlineMedium?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w900,
        height: 1.1,
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        const SizedBox(height: 14),
        Text(
          data.propertyName,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        _HeaderMetaLine(label: 'Data da visita', value: data.visitDate),
        if (data.responsible != null)
          _HeaderMetaLine(label: 'Responsável', value: data.responsible!),
      ],
    );
    final logo = Align(
      alignment: Alignment.topRight,
      child: Image.asset(
        AppAssets.companyLogo,
        // TODO(frontend-only): Logo PNG usado temporariamente como asset local.
        width: _ReportTokens.headerLogoWidth,
        fit: BoxFit.contain,
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: details),
        const SizedBox(width: 18),
        Padding(padding: const EdgeInsets.only(top: 2), child: logo),
      ],
    );
  }
}

class _HeaderMetaLine extends StatelessWidget {
  const _HeaderMetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(
              text: value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportStatsGrid extends StatelessWidget {
  const _ReportStatsGrid({required this.stats});

  final List<_ReportStat> stats;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _ReportTokens.contentWidth,
      child: Row(
        children: [
          for (var index = 0; index < stats.length; index++) ...[
            SizedBox(
              width: _ReportTokens.summaryCardWidth,
              child: _ReportStatCard(stat: stats[index]),
            ),
            if (index < stats.length - 1)
              const SizedBox(width: _ReportTokens.summaryCardGap),
          ],
        ],
      ),
    );
  }
}

class _ReportStatCard extends StatelessWidget {
  const _ReportStatCard({required this.stat});

  final _ReportStat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: SizedBox(
        height: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                stat.label,
                maxLines: 1,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                stat.value,
                maxLines: 1,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextStepsSection extends StatelessWidget {
  const _NextStepsSection({required this.steps});

  final List<_NextStepRow> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ReportSectionTitle(
            icon: Icons.event_available_outlined,
            title: 'Próximos Passos',
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < steps.length; index++) ...[
            _NextStepTile(step: steps[index]),
            if (index < steps.length - 1) const SizedBox(height: 12),
          ],
          if (steps.isEmpty)
            Text(
              'Nenhum próximo passo informado.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _NextStepTile extends StatelessWidget {
  const _NextStepTile({required this.step});

  final _NextStepRow step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${step.dateLabel} - ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: step.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProceduresSection extends StatelessWidget {
  const _ProceduresSection({required this.rows});

  final List<_ProcedureReportRow> rows;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ReportSectionTitle(title: 'Procedimentos Realizados'),
        const SizedBox(height: 12),
        // TODO(frontend-only): Ajustar bordas das tabelas para seguir o padrao visual.
        AppTable<_ProcedureReportRow>(
          borderRadius: 18,
          mobileBreakpoint: 0,
          rows: rows,
          emptyMessage: 'Nenhum procedimento informado para esta visita.',
          mobileTitleBuilder: (context, item) => Text(
            item.procedure,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          columns: [
            AppTableColumn<_ProcedureReportRow>(
              label: 'Procedimento',
              flex: 3,
              alignment: Alignment.centerLeft,
              cellBuilder: (context, item) => _StrongCell(item.procedure),
            ),
            AppTableColumn<_ProcedureReportRow>(
              label: 'Quant.',
              flex: 1,
              alignment: Alignment.center,
              cellBuilder: (context, item) =>
                  _StrongCell(item.quantity, textAlign: TextAlign.center),
            ),
            AppTableColumn<_ProcedureReportRow>(
              label: 'Observação',
              flex: 3,
              cellBuilder: (context, item) => Text(item.observation),
            ),
            AppTableColumn<_ProcedureReportRow>(
              label: 'Resultado',
              flex: 2,
              cellBuilder: (context, item) => _StrongCell(
                item.result,
                color: item.highlightResult ? colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConfirmedAnimalsSection extends StatelessWidget {
  const _ConfirmedAnimalsSection({required this.rows});

  final List<_ConfirmedAnimalReportRow> rows;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ReportSectionTitle(title: 'Animais Confirmados na Visita'),
        const SizedBox(height: 12),
        AppTable<_ConfirmedAnimalReportRow>(
          borderRadius: 18,
          mobileBreakpoint: 0,
          rows: rows,
          emptyMessage: 'Nenhum animal confirmado nesta visita.',
          mobileTitleBuilder: (context, item) => Text(
            item.identification,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          columns: [
            AppTableColumn<_ConfirmedAnimalReportRow>(
              label: 'Identificação',
              flex: 2,
              alignment: Alignment.centerLeft,
              cellBuilder: (context, item) => _StrongCell(item.identification),
            ),
            AppTableColumn<_ConfirmedAnimalReportRow>(
              label: 'Categoria',
              flex: 2,
              cellBuilder: (context, item) => Text(item.category),
            ),
            AppTableColumn<_ConfirmedAnimalReportRow>(
              label: 'Lote',
              flex: 1,
              cellBuilder: (context, item) => Text(item.lot),
            ),
            AppTableColumn<_ConfirmedAnimalReportRow>(
              label: 'Status',
              flex: 2,
              cellBuilder: (context, item) => Text(item.status),
            ),
            AppTableColumn<_ConfirmedAnimalReportRow>(
              label: 'Resultado',
              flex: 2,
              cellBuilder: (context, item) => _StrongCell(
                item.result,
                color: item.highlightResult ? colorScheme.primary : null,
              ),
            ),
            AppTableColumn<_ConfirmedAnimalReportRow>(
              label: 'Observação',
              flex: 3,
              cellBuilder: (context, item) => Text(item.observation),
            ),
          ],
        ),
      ],
    );
  }
}

class _ObservationsSection extends StatelessWidget {
  const _ObservationsSection({required this.observations});

  final String observations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ReportSectionTitle(
            icon: Icons.chat_bubble_outline,
            title: 'Observações',
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    observations,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.55,
                      fontStyle: FontStyle.italic,
                    ),
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

class _ReportFooter extends StatelessWidget {
  const _ReportFooter({required this.data});

  final _VisitReportData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(color: colorScheme.primary, thickness: 1.2),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                data.reportCreator,
                maxLines: 2,
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                data.companyName,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Relatório gerado em ${data.generatedAt}',
                maxLines: 2,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReportSectionTitle extends StatelessWidget {
  const _ReportSectionTitle({this.icon, required this.title});

  final IconData? icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: colorScheme.primary, size: 24),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _StrongCell extends StatelessWidget {
  const _StrongCell(this.value, {this.color, this.textAlign});

  final String value;
  final Color? color;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      value,
      textAlign: textAlign,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: color ?? colorScheme.onSurface,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _VisitReportData {
  const _VisitReportData({
    required this.propertyName,
    required this.visitDate,
    required this.responsible,
    required this.reportCreator,
    required this.companyName,
    required this.generatedAt,
    required this.stats,
    required this.nextSteps,
    required this.procedures,
    required this.animals,
    required this.observations,
  });

  final String propertyName;
  final String visitDate;
  final String? responsible;
  final String reportCreator;
  final String companyName;
  final String generatedAt;
  final List<_ReportStat> stats;
  final List<_NextStepRow> nextSteps;
  final List<_ProcedureReportRow> procedures;
  final List<_ConfirmedAnimalReportRow> animals;
  final String observations;

  factory _VisitReportData.fromVisit({
    required VisitSummaryModel visit,
    required String propertyName,
    PropertySummaryModel? property,
    String? companyName,
    String? currentUserName,
  }) {
    final animals = visit.animais;
    final lactating = animals.where(_isLactating).length;
    final dry = animals.where(_isDry).length;
    final heifers = animals.where(_isHeifer).length;
    final empty = animals.where(_isEmptyReproductive).length;
    final pregnant = animals.where(_isPregnant).length;
    final pregnancyDenominator = pregnant + empty;
    final pregnancyRate = pregnancyDenominator == 0
        ? 0
        : ((pregnant / pregnancyDenominator) * 100).round();
    final responsible = visit.veterinarioResponsavel;
    final reportCreator =
        _cleanText(visit.nomeUsuario) ??
        _cleanText(currentUserName) ??
        'Não informado';
    final reportCompany = _cleanText(companyName) ?? 'Empresa não informada';

    return _VisitReportData(
      propertyName: propertyName.trim().isEmpty ? 'Propriedade' : propertyName,
      visitDate: formatDate(visit.dataVisita),
      responsible: responsible,
      reportCreator: reportCreator,
      companyName: reportCompany,
      generatedAt: formatDate(DateTime.now()),
      stats: [
        _ReportStat(label: 'Animais', value: animals.length.toString()),
        _ReportStat(label: 'Lactantes', value: lactating.toString()),
        _ReportStat(label: 'Secas', value: dry.toString()),
        _ReportStat(label: 'Novilhas', value: heifers.toString()),
        _ReportStat(label: 'Vazias', value: empty.toString()),
        _ReportStat(label: 'Prenhas', value: pregnant.toString()),
        _ReportStat(label: 'Taxa de Prenhez', value: '$pregnancyRate%'),
      ],
      nextSteps: _buildNextSteps(animals),
      procedures: _buildProcedures(
        animals: animals,
        propertyName: propertyName,
        observations: visit.observacoes,
        pregnant: pregnant,
        empty: empty,
      ),
      animals: [
        for (final item in animals) _ConfirmedAnimalReportRow.fromEntry(item),
      ],
      observations:
          _cleanText(visit.observacoes) ??
          property?.observacoes?.trim() ??
          'Nenhuma observação técnica registrada para esta visita.',
    );
  }
}

class _ReportStat {
  const _ReportStat({required this.label, required this.value});

  final String label;
  final String value;
}

class _NextStepRow {
  const _NextStepRow({required this.date, required this.description});

  final DateTime? date;
  final String description;

  String get dateLabel => date == null ? 'A definir' : formatDate(date);
}

class _ProcedureReportRow {
  const _ProcedureReportRow({
    required this.procedure,
    required this.quantity,
    required this.observation,
    required this.result,
    this.highlightResult = false,
  });

  final String procedure;
  final String quantity;
  final String observation;
  final String result;
  final bool highlightResult;
}

class _ConfirmedAnimalReportRow {
  const _ConfirmedAnimalReportRow({
    required this.identification,
    required this.category,
    required this.lot,
    required this.status,
    required this.result,
    required this.observation,
    required this.highlightResult,
  });

  final String identification;
  final String category;
  final String lot;
  final String status;
  final String result;
  final String observation;
  final bool highlightResult;

  factory _ConfirmedAnimalReportRow.fromEntry(VisitAnimalEntryModel entry) {
    final result =
        _cleanText(entry.diagnostico) ??
        _cleanText(entry.decisao) ??
        (entry.diasPrenhez == null ? null : '${entry.diasPrenhez} dias') ??
        'Aguardando';

    return _ConfirmedAnimalReportRow(
      identification:
          _cleanText(entry.animalCodigo) ??
          _cleanText(entry.animalIdExterno) ??
          'Animal ${entry.animalId}',
      category: _cleanText(entry.animalCategoria) ?? 'Não informada',
      // Integracao futura: substituir por lote retornado pelo back-end.
      lot: '--',
      status:
          _cleanText(entry.situacaoReprodutiva) ??
          _cleanText(entry.situacaoProdutiva) ??
          'Registrado',
      result: result,
      // Integracao futura: usar observacao individual do animal quando a API
      // expuser esse campo. Por enquanto exibimos dados tecnicos coletados.
      observation: _animalObservation(entry),
      highlightResult: _isPregnant(entry),
    );
  }
}

List<_NextStepRow> _buildNextSteps(List<VisitAnimalEntryModel> animals) {
  final steps = <_NextStepRow>[];

  // Temporario no front-end: proximos passos ainda nao chegam como uma lista
  // estruturada pelo back-end, entao derivamos eventos previstos dos animais.
  for (final animal in animals) {
    final identification =
        _cleanText(animal.animalCodigo) ?? _cleanText(animal.animalIdExterno);

    if (animal.previsaoSecagem != null) {
      steps.add(
        _NextStepRow(
          date: animal.previsaoSecagem,
          description: 'Secagem prevista para ${identification ?? 'animal'}.',
        ),
      );
    }

    if (animal.dataPreParto != null) {
      steps.add(
        _NextStepRow(
          date: animal.dataPreParto,
          description: 'Pré-parto previsto para ${identification ?? 'animal'}.',
        ),
      );
    }

    if (animal.previsaoParto != null) {
      steps.add(
        _NextStepRow(
          date: animal.previsaoParto,
          description: 'Parto previsto para ${identification ?? 'animal'}.',
        ),
      );
    }
  }

  steps.sort((a, b) {
    final dateA = a.date;
    final dateB = b.date;
    if (dateA == null && dateB == null) return 0;
    if (dateA == null) return 1;
    if (dateB == null) return -1;
    return dateA.compareTo(dateB);
  });

  if (steps.isEmpty) {
    steps.add(
      const _NextStepRow(
        date: null,
        description: 'Próximos passos pendentes de cadastro.',
      ),
    );
  }

  return steps.take(6).toList(growable: false);
}

List<_ProcedureReportRow> _buildProcedures({
  required List<VisitAnimalEntryModel> animals,
  required String propertyName,
  required String? observations,
  required int pregnant,
  required int empty,
}) {
  final rows = <_ProcedureReportRow>[];
  final diagnosticCount = animals
      .where(
        (item) =>
            _cleanText(item.diagnostico) != null ||
            _isPregnant(item) ||
            _isEmptyReproductive(item),
      )
      .length;

  // Temporario no front-end: substituir por procedimentos realizados vindos
  // da API quando o back-end entregar essa estrutura.
  if (animals.isNotEmpty) {
    rows.add(
      _ProcedureReportRow(
        procedure: 'Conferência de animais',
        quantity: animals.length.toString(),
        observation: propertyName.trim().isEmpty
            ? 'Visita técnica'
            : propertyName,
        result: 'Concluído',
        highlightResult: true,
      ),
    );
  }

  if (diagnosticCount > 0) {
    final result = [
      if (pregnant > 0) '$pregnant prenha(s)',
      if (empty > 0) '$empty vazia(s)',
    ].join(', ');

    rows.add(
      _ProcedureReportRow(
        procedure: 'Diagnóstico reprodutivo',
        quantity: diagnosticCount.toString(),
        observation: 'Animais avaliados na visita',
        result: result.isEmpty ? 'Registrado' : result,
        highlightResult: pregnant > 0,
      ),
    );
  }

  if (_cleanText(observations) != null) {
    rows.add(
      const _ProcedureReportRow(
        procedure: 'Orientação técnica',
        quantity: '1',
        observation: 'Observações gerais registradas',
        result: 'Registrado',
      ),
    );
  }

  return rows;
}

String _reportFileName(VisitSummaryModel visit) {
  final date = visit.dataVisita;
  if (date == null) return 'relatorio-visita-${visit.id}.pdf';

  return 'relatorio-visita-${formatCompactDate(date)}-${visit.id}.pdf';
}

String _animalObservation(VisitAnimalEntryModel entry) {
  final parts = <String>[
    if (entry.dataUltimaIa != null)
      'Última IA: ${formatDate(entry.dataUltimaIa)}',
    if (entry.numeroIaRecebida != null) 'IA: ${entry.numeroIaRecebida}',
    if (entry.diasPrenhez != null) 'Prenhez: ${entry.diasPrenhez} dias',
    if (entry.del != null) 'DEL: ${entry.del}',
    if (entry.diasParaSecar != null) 'Secar em ${entry.diasParaSecar} dias',
    if (entry.previsaoSecagem != null)
      'Prev. secagem: ${formatDate(entry.previsaoSecagem)}',
    if (entry.dataPreParto != null)
      'Pré-parto: ${formatDate(entry.dataPreParto)}',
    if (entry.previsaoParto != null)
      'Prev. parto: ${formatDate(entry.previsaoParto)}',
  ];

  if (parts.isEmpty) return '--';
  return parts.join(' | ');
}

bool _isLactating(VisitAnimalEntryModel entry) {
  return _containsAny(
    '${entry.situacaoProdutiva ?? ''} ${entry.animalCategoria}',
    const ['lactante', 'lactacao', 'lactacao', 'lact'],
  );
}

bool _isDry(VisitAnimalEntryModel entry) {
  return _containsAny(
    '${entry.situacaoProdutiva ?? ''} ${entry.animalCategoria}',
    const ['seca', 'seco', 'dry'],
  );
}

bool _isHeifer(VisitAnimalEntryModel entry) {
  return _containsAny(entry.animalCategoria, const ['novilha', 'heifer']);
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

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) return item;
  }

  return null;
}

String _safeVisitReportBackRoute(String? route) {
  final trimmed = route?.trim();
  if (trimmed == '/visitas' || trimmed?.startsWith('/propriedades/') == true) {
    return trimmed!;
  }

  return '/visitas';
}
