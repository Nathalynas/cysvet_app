import 'dart:async';

import 'package:cysvet_app/app/app_shell.dart';
import 'package:cysvet_app/core/constants/app_constants.dart';
import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/core/enums/property_status.dart';
import 'package:cysvet_app/core/presentation/app_scaffold_messenger.dart';
import 'package:cysvet_app/core/utils/formatters.dart';
import 'package:cysvet_app/core/widgets/app_button.dart';
import 'package:cysvet_app/core/widgets/app_card.dart';
import 'package:cysvet_app/core/widgets/app_dialog.dart';
import 'package:cysvet_app/core/widgets/status_badge.dart';
import 'package:cysvet_app/features/animals/application/animals_provider.dart';
import 'package:cysvet_app/features/animals/data/animals_repository.dart';
import 'package:cysvet_app/features/animals/domain/animal_summary_model.dart';
import 'package:cysvet_app/features/animals/presentation/animal_history_dialog.dart';
import 'package:cysvet_app/features/auth/application/auth_state.dart';
import 'package:cysvet_app/features/indicators/indicador_reprodutivo_calculator.dart';
import 'package:cysvet_app/features/properties/application/properties_provider.dart';
import 'package:cysvet_app/features/properties/domain/property_summary_model.dart';
import 'package:cysvet_app/features/properties/presentation/property_dialog.dart';
import 'package:cysvet_app/features/visits/application/visits_provider.dart';
import 'package:cysvet_app/features/visits/data/visits_repository.dart';
import 'package:cysvet_app/features/visits/domain/visit_summary_model.dart';
import 'package:cysvet_app/features/visits/presentation/pages/visit_report_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum PropertyTab { general, animals, visits }

PropertyTab propertyTabFromQuery(String? value) {
  final normalized = value?.trim().toLowerCase();
  return switch (normalized) {
    'animals' || 'animais' => PropertyTab.animals,
    'visits' || 'visitas' => PropertyTab.visits,
    _ => PropertyTab.general,
  };
}

extension _PropertyTabLabel on PropertyTab {
  String get label {
    return switch (this) {
      PropertyTab.general => 'Dados Gerais',
      PropertyTab.animals => 'Animais',
      PropertyTab.visits => 'Visitas',
    };
  }
}

final propertyDetailsProvider = FutureProvider.autoDispose
    .family<PropertySummaryModel, int>((ref, propertyId) async {
      if (propertyId == 0) {
        throw StateError('Identificador de propriedade invalido.');
      }

      // TODO(api): substituir a busca pela lista por GET /api/properties/:id
      // quando o backend expuser o endpoint de detalhe.
      final properties = await ref.watch(propertiesProvider.future);

      for (final property in properties) {
        if (property.id == propertyId) return property;
      }

      throw StateError('Propriedade nao encontrada.');
    });

final propertyDetailsAnimalsProvider = FutureProvider.autoDispose
    .family<List<AnimalSummaryModel>, int>((ref, propertyId) async {
      final propertyFuture = ref.watch(
        propertyDetailsProvider(propertyId).future,
      );
      final session = ref.watch(authSessionProvider);
      final localItems = ref.watch(localAnimalsProvider);
      final deletedIds = ref.watch(deletedAnimalsProvider);
      final repository = ref.watch(animalsRepositoryProvider);

      if (session == null) {
        throw StateError('Sessão indisponível.');
      }

      final property = await propertyFuture;
      final remoteItems = await repository.list(
        propertyId: property.id > 0 ? property.id : null,
      );
      final merged =
          {
            for (final animal in remoteItems)
              animal.id: localItems[animal.id] ?? animal,
            ...localItems,
          }.values.where((animal) {
            return !deletedIds.contains(animal.id) &&
                _animalBelongsToProperty(animal, property);
          }).toList();

      merged.sort((a, b) => a.codigo.compareTo(b.codigo));
      return merged;
    });

final propertyDetailsVisitsProvider = FutureProvider.autoDispose
    .family<List<VisitSummaryModel>, int>((ref, propertyId) async {
      final propertyFuture = ref.watch(
        propertyDetailsProvider(propertyId).future,
      );
      final session = ref.watch(authSessionProvider);
      final localItems = ref.watch(localVisitsProvider);
      final repository = ref.watch(visitsRepositoryProvider);

      if (session == null) {
        throw StateError('Sessão indisponível.');
      }

      final property = await propertyFuture;
      final remoteItems = await repository.list(
        propertyId: property.id > 0 ? property.id : null,
      );
      final merged =
          {
            for (final visit in remoteItems)
              visit.id: localItems[visit.id] ?? visit,
            ...localItems,
          }.values.where((visit) {
            return _visitBelongsToProperty(visit, property);
          }).toList();

      merged.sort(_compareVisitsByDateDesc);
      return merged;
    });

class PropertyDetailsPage extends ConsumerStatefulWidget {
  const PropertyDetailsPage({
    super.key,
    required this.propertyId,
    this.initialTab = PropertyTab.general,
    this.onRefresh,
  });

  final int propertyId;
  final PropertyTab initialTab;
  final FutureOr<void> Function()? onRefresh;

  @override
  ConsumerState<PropertyDetailsPage> createState() =>
      _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends ConsumerState<PropertyDetailsPage> {
  late PropertyTab _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant PropertyDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.propertyId != widget.propertyId ||
        oldWidget.initialTab != widget.initialTab) {
      _activeTab = widget.initialTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final propertyValue = ref.watch(propertyDetailsProvider(widget.propertyId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: propertyValue.when(
            data: _buildContent,
            loading: () => _buildLoading(context),
            error: (error, stackTrace) => _buildError(context, error),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(PropertySummaryModel property) {
    final animalsValue = ref.watch(
      propertyDetailsAnimalsProvider(widget.propertyId),
    );
    final visitsValue = ref.watch(
      propertyDetailsVisitsProvider(widget.propertyId),
    );
    final animals = animalsValue.asData?.value;
    final visits = visitsValue.asData?.value;
    final stats = animals == null && visits == null
        ? null
        : _PropertyStats.from(animals ?? const [], visits ?? const []);
    final statsLoading = animalsValue.isLoading || visitsValue.isLoading;

    return _PropertyDetailsList(
      propertyName: property.nome,
      children: [
        _PropertySummaryCard(
          property: property,
          stats: stats,
          statsLoading: statsLoading,
          onEdit: () => _openEdit(property),
          onToggleStatus: () => _confirmToggleStatus(property),
          onDelete: () => _confirmDelete(property),
        ),
        const SizedBox(height: 16),
        _PropertyTabsCard(
          activeTab: _activeTab,
          onTabChanged: (tab) => setState(() => _activeTab = tab),
          child: _tabContent(property, animalsValue, visitsValue),
        ),
      ],
    );
  }

  Widget _tabContent(
    PropertySummaryModel property,
    AsyncValue<List<AnimalSummaryModel>> animalsValue,
    AsyncValue<List<VisitSummaryModel>> visitsValue,
  ) {
    return switch (_activeTab) {
      PropertyTab.general => _PropertyGeneralTab(property: property),
      PropertyTab.animals => _PropertyAnimalsTab(
        property: property,
        value: animalsValue,
        onRetry: () {
          ref.invalidate(propertyDetailsAnimalsProvider(widget.propertyId));
        },
      ),
      PropertyTab.visits => _PropertyVisitsTab(
        property: property,
        value: visitsValue,
        onRetry: () {
          ref.invalidate(propertyDetailsVisitsProvider(widget.propertyId));
        },
      ),
    };
  }

  Widget _buildLoading(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _PropertyDetailsList(
      propertyName: 'Carregando...',
      children: [
        AppCard(
          child: Row(
            children: [
              SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(child: Text('Buscando propriedade...')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _PropertyDetailsList(
      propertyName: 'Detalhes',
      children: [
        AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Tentar novamente',
                icon: const Icon(Icons.refresh),
                onPressed: _retry,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _refresh() async {
    final callback = widget.onRefresh;
    ref.invalidate(propertyDetailsProvider(widget.propertyId));
    ref.invalidate(propertyDetailsAnimalsProvider(widget.propertyId));
    ref.invalidate(propertyDetailsVisitsProvider(widget.propertyId));

    final refreshes = <Future<void>>[
      ref
          .refresh(propertyDetailsProvider(widget.propertyId).future)
          .then<void>((_) {}),
      ref
          .refresh(propertyDetailsAnimalsProvider(widget.propertyId).future)
          .then<void>((_) {}),
      ref
          .refresh(propertyDetailsVisitsProvider(widget.propertyId).future)
          .then<void>((_) {}),
    ];

    if (callback != null) {
      refreshes.add(Future.sync(callback));
    }

    await Future.wait(refreshes);
  }

  void _retry() {
    ref.invalidate(propertyDetailsProvider(widget.propertyId));
    ref.invalidate(propertyDetailsAnimalsProvider(widget.propertyId));
    ref.invalidate(propertyDetailsVisitsProvider(widget.propertyId));
  }

  Future<void> _openEdit(PropertySummaryModel property) async {
    await PropertyDialog.show(context, property: property, fromDetails: true);
    if (!mounted) return;
    ref.invalidate(propertyDetailsProvider(widget.propertyId));
    ref.invalidate(propertyDetailsAnimalsProvider(widget.propertyId));
    ref.invalidate(propertyDetailsVisitsProvider(widget.propertyId));
    final callback = widget.onRefresh;
    if (callback != null) {
      await Future.sync(callback);
    }
  }

  Future<void> _confirmToggleStatus(PropertySummaryModel property) {
    return property.status == PropertyStatus.inactive
        ? _confirmActivate(property)
        : _confirmInactivate(property);
  }

  Future<void> _confirmInactivate(PropertySummaryModel property) {
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
          ref.invalidate(propertyDetailsProvider(widget.propertyId));
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

  Future<void> _confirmActivate(PropertySummaryModel property) {
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
          ref.invalidate(propertyDetailsProvider(widget.propertyId));
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

  Future<void> _confirmDelete(PropertySummaryModel property) {
    return AppDialog.show<void>(
      context: context,
      title: 'Excluir propriedade',
      content: Text('Deseja excluir ${property.nome} desta sessao?'),
      confirmText: 'Excluir',
      cancelText: 'Cancelar',
      onConfirm: () async {
        final navigator = Navigator.of(context, rootNavigator: true);
        final router = GoRouter.of(context);
        try {
          await ref.read(propertiesControllerProvider).delete(property.id);
          if (!mounted) return;
          await navigator.maybePop();
          router.go('/propriedades');
          showAppSuccess('Propriedade excluída com sucesso.');
        } catch (error) {
          showAppError(error);
        }
      },
    );
  }
}

class _PropertyDetailsList extends StatelessWidget {
  const _PropertyDetailsList({
    required this.propertyName,
    required this.children,
  });

  final String propertyName;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < MOBILE_WIDTH;
    final horizontal = PageTitle.horizontalPadding(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontal,
        isMobile ? 16 : 24,
        horizontal,
        isMobile ? 88 : 24,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _PropertyDetailsTop(propertyName: propertyName),
        const SizedBox(height: 18),
        ...children,
      ],
    );
  }
}

class _PropertyDetailsTop extends StatelessWidget {
  const _PropertyDetailsTop({required this.propertyName});

  final String propertyName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        _PropertyActionIconButton(
          tooltip: 'Voltar',
          icon: Icons.arrow_back,
          color: colorScheme.primary,
          backgroundColor: colorScheme.surface,
          borderColor: colorScheme.outline.withValues(alpha: 0.55),
          filled: true,
          shadow: true,
          onPressed: () => context.go('/propriedades'),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Propriedades',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: ' / ',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                TextSpan(
                  text: _dashIfBlank(propertyName),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

class _PropertySummaryCard extends StatelessWidget {
  const _PropertySummaryCard({
    required this.property,
    required this.stats,
    required this.statsLoading,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final PropertySummaryModel property;
  final _PropertyStats? stats;
  final bool statsLoading;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 18,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 760;
          final identity = _PropertySummaryIdentity(
            property: property,
            stats: stats,
            statsLoading: statsLoading,
          );
          final actions = _PropertyActions(
            property: property,
            stats: stats,
            statsLoading: statsLoading,
            onEdit: onEdit,
            onToggleStatus: onToggleStatus,
            onDelete: onDelete,
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [identity, const SizedBox(height: 18), actions],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: identity),
              const SizedBox(width: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: actions,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PropertySummaryIdentity extends StatelessWidget {
  const _PropertySummaryIdentity({
    required this.property,
    required this.stats,
    required this.statsLoading,
  });

  final PropertySummaryModel property;
  final _PropertyStats? stats;
  final bool statsLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasLocation =
        _cleanText(property.cidade) != null ||
        _cleanText(property.estado) != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              _initialsFor(property.nome),
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [
                  Text(
                    _dashIfBlank(property.nome),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                  ),
                  StatusBadge(
                    label: property.status.label,
                    type: _propertyStatusBadgeType(property.status),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (_cleanText(property.nomeProprietario) != null)
                    _SummaryMetaItem(
                      icon: Icons.person_outline,
                      text: property.nomeProprietario.trim(),
                    ),
                  if (hasLocation)
                    _SummaryMetaItem(
                      icon: Icons.place_outlined,
                      text: _locationLabel(property),
                    ),
                  if (_cleanText(property.contato) != null)
                    _SummaryMetaItem(
                      icon: Icons.phone_outlined,
                      text: property.contato!.trim(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryMetaItem extends StatelessWidget {
  const _SummaryMetaItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PropertyStatsStrip extends StatelessWidget {
  const _PropertyStatsStrip({
    required this.stats,
    required this.loading,
    this.stacked = false,
  });

  final _PropertyStats? stats;
  final bool loading;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final loadingLabel = loading && stats == null ? '...' : '--';

    final items = [
      _MetricPill(
        label: 'Rebanho total',
        value: stats == null ? loadingLabel : formatInteger(stats!.herdTotal),
        icon: Icons.groups_outlined,
        fullWidth: stacked,
      ),
      _MetricPill(
        label: 'Em reprodução',
        value: stats == null
            ? loadingLabel
            : formatInteger(stats!.reproductionCount),
        icon: Icons.monitor_heart_outlined,
        highlighted: true,
        fullWidth: stacked,
      ),
      _MetricPill(
        label: 'Última visita',
        value: stats == null ? loadingLabel : formatDate(stats!.lastVisitDate),
        icon: Icons.event_available_outlined,
        fullWidth: stacked,
      ),
    ];

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            items[index],
            if (index < items.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Wrap(spacing: 10, runSpacing: 10, children: items);
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.icon,
    this.highlighted = false,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlighted;
  final bool fullWidth;

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
    final muted = highlighted
        ? colorScheme.onPrimary.withValues(alpha: 0.78)
        : colorScheme.onSurfaceVariant;

    return Container(
      width: fullWidth ? double.infinity : 158,
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w900,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
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

class _PropertyActions extends StatelessWidget {
  const _PropertyActions({
    required this.property,
    required this.stats,
    required this.statsLoading,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final PropertySummaryModel property;
  final _PropertyStats? stats;
  final bool statsLoading;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isInactive = property.status == PropertyStatus.inactive;
    final toggleTooltip = isInactive ? 'Ativar' : 'Inativar';

    final buttons = Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: [
        _PropertyActionIconButton(
          tooltip: 'Editar',
          icon: Icons.edit_outlined,
          onPressed: onEdit,
        ),
        _PropertyActionIconButton(
          tooltip: toggleTooltip,
          icon: isInactive ? Icons.unarchive_outlined : Icons.archive_outlined,
          onPressed: onToggleStatus,
        ),
        _PropertyActionIconButton(
          tooltip: 'Excluir',
          icon: Icons.delete_outline,
          color: colorScheme.error,
          onPressed: onDelete,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(alignment: Alignment.centerRight, child: buttons),
              const SizedBox(height: 16),
              _PropertyStatsStrip(
                stats: stats,
                loading: statsLoading,
                stacked: true,
              ),
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _PropertyStatsStrip(stats: stats, loading: statsLoading),
            const SizedBox(width: 60),
            buttons,
          ],
        );
      },
    );
  }
}

class _PropertyActionIconButton extends StatelessWidget {
  const _PropertyActionIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.filled = false,
    this.shadow = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool filled;
  final dynamic shadow;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.primary;

    return Tooltip(
      message: tooltip,
      child: AppButton(
        outlined: !filled,
        width: 38,
        height: 38,
        padding: EdgeInsets.zero,
        borderRadius: 12,
        shadow: shadow,
        color: backgroundColor ?? effectiveColor,
        textColor: effectiveColor,
        borderColor: borderColor ?? Colors.transparent,
        icon: Icon(icon, size: 18, color: effectiveColor),
        onPressed: onPressed,
      ),
    );
  }
}

class _PropertyTabsCard extends StatelessWidget {
  const _PropertyTabsCard({
    required this.activeTab,
    required this.onTabChanged,
    required this.child,
  });

  final PropertyTab activeTab;
  final ValueChanged<PropertyTab> onTabChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final tab in PropertyTab.values)
                  _PropertyTabButton(
                    tab: tab,
                    selected: tab == activeTab,
                    onTap: () => onTabChanged(tab),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
          Padding(padding: const EdgeInsets.all(18), child: child),
        ],
      ),
    );
  }
}

class _PropertyTabButton extends StatelessWidget {
  const _PropertyTabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final PropertyTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        focusColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? colorScheme.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            tab.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _PropertyGeneralTab extends StatelessWidget {
  const _PropertyGeneralTab({required this.property});

  final PropertySummaryModel property;

  @override
  Widget build(BuildContext context) {
    return _DetailsFieldGrid(
      fields: [
        _DetailField(label: 'Nome', value: _dashIfBlank(property.nome)),
        _DetailField(
          label: 'Responsável',
          value: _dashIfBlank(property.nomeProprietario),
        ),
        _DetailField(label: 'Contato', value: _dashIfBlank(property.contato)),
        _DetailField(label: 'Cidade', value: _dashIfBlank(property.cidade)),
        _DetailField(label: 'UF', value: _dashIfBlank(property.estado)),
        _DetailField(label: 'Localização', value: _locationLabel(property)),
        _DetailField(label: 'Status', value: property.status.label),
        _DetailField(
          label: 'ID externo',
          value: _dashIfBlank(property.idExterno),
        ),
        _DetailField(
          label: 'Observações',
          value: _dashIfBlank(property.observacoes),
          wide: true,
        ),
      ],
    );
  }
}

class _PropertyAnimalsTab extends StatelessWidget {
  const _PropertyAnimalsTab({
    required this.property,
    required this.value,
    required this.onRetry,
  });

  final PropertySummaryModel property;
  final AsyncValue<List<AnimalSummaryModel>> value;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (animals) =>
          _PropertyAnimalsTable(property: property, animals: animals),
      loading: () => const _InlineFeedback(
        message: 'Carregando animais da propriedade...',
        loading: true,
      ),
      error: (error, stackTrace) => _InlineFeedback(
        message: 'Não foi possivel carregar os animais desta propriedade.',
        onRetry: onRetry,
      ),
    );
  }
}

class _PropertyVisitsTab extends StatelessWidget {
  const _PropertyVisitsTab({
    required this.property,
    required this.value,
    required this.onRetry,
  });

  final PropertySummaryModel property;
  final AsyncValue<List<VisitSummaryModel>> value;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (visits) =>
          _PropertyVisitsTable(property: property, visits: visits),
      loading: () => const _InlineFeedback(
        message: 'Carregando visitas da propriedade...',
        loading: true,
      ),
      error: (error, stackTrace) => _InlineFeedback(
        message: 'Não foi possivel carregar as visitas desta propriedade.',
        onRetry: onRetry,
      ),
    );
  }
}

class _PropertyAnimalsTable extends StatelessWidget {
  const _PropertyAnimalsTable({required this.property, required this.animals});

  final PropertySummaryModel property;
  final List<AnimalSummaryModel> animals;

  @override
  Widget build(BuildContext context) {
    return _DetailsInlineTable<AnimalSummaryModel>(
      rows: animals,
      footerLabel: _animalsRecordsLabel(animals.length),
      emptyMessage: 'Nenhum animal vinculado a esta propriedade.',
      onRowTap: (animal) => AnimalHistoryDialog.show(
        context: context,
        animal: animal,
        propertyName: property.nome,
      ),
      mobileTitleBuilder: (context, animal) {
        return _AnimalIdentityCell(animal: animal);
      },
      columns: [
        _DetailsTableColumn<AnimalSummaryModel>(
          label: 'Animal',
          flex: 3,
          cellBuilder: (context, animal) => _AnimalIdentityCell(animal: animal),
        ),
        _DetailsTableColumn<AnimalSummaryModel>(
          label: 'Categoria',
          flex: 2,
          cellBuilder: (context, animal) => Text(_animalCategoryLabel(animal)),
        ),
        _DetailsTableColumn<AnimalSummaryModel>(
          label: 'Status',
          flex: 2,
          cellBuilder: (context, animal) => StatusBadge(
            label: animal.status.label,
            type: _animalStatusBadgeType(animal.status),
          ),
        ),
        _DetailsTableColumn<AnimalSummaryModel>(
          label: 'Reprodução',
          flex: 2,
          cellBuilder: (context, animal) {
            final status = IndicadorReprodutivoCalculator.resolveAnimalStatus(
              animal,
            );
            return StatusBadge(
              label: status.label,
              type: _reproductiveStatusBadgeType(status),
              icon: status.icon,
            );
          },
        ),
        _DetailsTableColumn<AnimalSummaryModel>(
          label: 'Última IA',
          flex: 2,
          cellBuilder: (context, animal) =>
              Text(formatDate(animal.dataInseminacao)),
        ),
        _DetailsTableColumn<AnimalSummaryModel>(
          label: 'Último parto',
          flex: 2,
          cellBuilder: (context, animal) =>
              Text(formatDate(animal.dataUltimoParto)),
        ),
      ],
    );
  }
}

class _PropertyVisitsTable extends StatelessWidget {
  const _PropertyVisitsTable({required this.property, required this.visits});

  final PropertySummaryModel property;
  final List<VisitSummaryModel> visits;

  @override
  Widget build(BuildContext context) {
    return _DetailsInlineTable<VisitSummaryModel>(
      rows: visits,
      footerLabel: _visitsRecordsLabel(visits.length),
      emptyMessage: 'Nenhuma visita vinculada a esta propriedade.',
      onRowTap: (visit) => _openVisit(context, visit),
      mobileTitleBuilder: (context, visit) {
        return Text(
          formatDate(visit.dataVisita),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        );
      },
      columns: [
        _DetailsTableColumn<VisitSummaryModel>(
          label: 'Data',
          flex: 2,
          cellBuilder: (context, visit) => Text(formatDate(visit.dataVisita)),
        ),
        _DetailsTableColumn<VisitSummaryModel>(
          label: 'Veterinário',
          flex: 3,
          cellBuilder: (context, visit) =>
              Text(_dashIfBlank(visit.veterinarioResponsavel)),
        ),
        _DetailsTableColumn<VisitSummaryModel>(
          label: 'Protocolo',
          flex: 3,
          cellBuilder: (context, visit) => Text(_protocolLabel(visit)),
        ),
        _DetailsTableColumn<VisitSummaryModel>(
          label: 'Animais',
          flex: 2,
          cellBuilder: (context, visit) => Text(
            '${visit.animais.length} ${visit.animais.length == 1 ? 'animal' : 'animais'}',
          ),
        ),
        _DetailsTableColumn<VisitSummaryModel>(
          label: 'Proximo passo',
          flex: 4,
          cellBuilder: (context, visit) => Text(_nextStepText(visit)),
        ),
      ],
    );
  }

  void _openVisit(BuildContext context, VisitSummaryModel visit) {
    final returnRoute = '/propriedades/${property.id}?aba=visitas';
    context.go(
      Uri(
        path: '/visitas/${visit.id}/detalhes',
        queryParameters: {'retorno': returnRoute},
      ).toString(),
      extra: VisitReportRouteData(
        visit: visit,
        propertyName: property.nome,
        property: property,
        returnRoute: returnRoute,
      ),
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
            fontWeight: FontWeight.w900,
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

class _DetailsFieldGrid extends StatelessWidget {
  const _DetailsFieldGrid({required this.fields});

  final List<_DetailField> fields;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 2 : 1;
        const spacing = 14.0;
        final itemWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final field in fields)
              SizedBox(
                width: field.wide ? constraints.maxWidth : itemWidth,
                child: _DetailFieldView(field: field),
              ),
          ],
        );
      },
    );
  }
}

class _DetailField {
  const _DetailField({
    required this.label,
    required this.value,
    this.wide = false,
  });

  final String label;
  final String value;
  final bool wide;
}

class _DetailFieldView extends StatelessWidget {
  const _DetailFieldView({required this.field});

  final _DetailField field;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            field.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            field.value,
            maxLines: field.wide ? 5 : 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineFeedback extends StatelessWidget {
  const _InlineFeedback({
    required this.message,
    this.loading = false,
    this.onRetry,
  });

  final String message;
  final bool loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
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
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            AppButton(
              text: 'Tentar novamente',
              outlined: true,
              height: 36,
              icon: const Icon(Icons.refresh, size: 17),
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailsTableColumn<T> {
  const _DetailsTableColumn({
    required this.label,
    required this.cellBuilder,
    this.flex = 1,
    this.alignment = Alignment.centerLeft,
    this.mobileLabel,
  });

  final String label;
  final String? mobileLabel;
  final int flex;
  final AlignmentGeometry alignment;
  final Widget Function(BuildContext context, T row) cellBuilder;
}

class _DetailsInlineTable<T> extends StatelessWidget {
  const _DetailsInlineTable({
    required this.rows,
    required this.columns,
    required this.emptyMessage,
    this.footerLabel,
    this.mobileTitleBuilder,
    this.onRowTap,
  });

  final List<T> rows;
  final List<_DetailsTableColumn<T>> columns;
  final String emptyMessage;
  final String? footerLabel;
  final Widget Function(BuildContext context, T row)? mobileTitleBuilder;
  final ValueChanged<T>? onRowTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (rows.isEmpty) {
          return _InlineFeedback(message: emptyMessage);
        }

        if (constraints.maxWidth < 720) {
          return _DetailsMobileList<T>(
            rows: rows,
            columns: columns,
            footerLabel: footerLabel,
            titleBuilder: mobileTitleBuilder,
            onRowTap: onRowTap,
          );
        }

        return _DetailsDesktopTable<T>(
          rows: rows,
          columns: columns,
          footerLabel: footerLabel,
          onRowTap: onRowTap,
        );
      },
    );
  }
}

class _DetailsDesktopTable<T> extends StatelessWidget {
  const _DetailsDesktopTable({
    required this.rows,
    required this.columns,
    required this.footerLabel,
    required this.onRowTap,
  });

  final List<T> rows;
  final List<_DetailsTableColumn<T>> columns;
  final String? footerLabel;
  final ValueChanged<T>? onRowTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                for (var index = 0; index < columns.length; index++) ...[
                  Expanded(
                    flex: columns[index].flex,
                    child: Text(
                      columns[index].label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (index < columns.length - 1) const SizedBox(width: 14),
                ],
              ],
            ),
          ),
          for (var index = 0; index < rows.length; index++) ...[
            Divider(
              height: 1,
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
            _DetailsDesktopRow<T>(
              row: rows[index],
              columns: columns,
              onTap: onRowTap,
              backgroundColor: index.isEven
                  ? colorScheme.surface
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
            ),
          ],
          if (footerLabel != null) ...[
            Divider(
              height: 1,
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                footerLabel!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailsDesktopRow<T> extends StatelessWidget {
  const _DetailsDesktopRow({
    required this.row,
    required this.columns,
    required this.backgroundColor,
    this.onTap,
  });

  final T row;
  final List<_DetailsTableColumn<T>> columns;
  final Color backgroundColor;
  final ValueChanged<T>? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var index = 0; index < columns.length; index++) ...[
            Expanded(
              flex: columns[index].flex,
              child: Align(
                alignment: columns[index].alignment,
                child: DefaultTextStyle.merge(
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  child: columns[index].cellBuilder(context, row),
                ),
              ),
            ),
            if (index < columns.length - 1) const SizedBox(width: 14),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return ColoredBox(color: backgroundColor, child: content);
    }

    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: () => onTap!(row),
        hoverColor: colorScheme.primary.withValues(alpha: 0.04),
        child: content,
      ),
    );
  }
}

class _DetailsMobileList<T> extends StatelessWidget {
  const _DetailsMobileList({
    required this.rows,
    required this.columns,
    required this.footerLabel,
    required this.titleBuilder,
    required this.onRowTap,
  });

  final List<T> rows;
  final List<_DetailsTableColumn<T>> columns;
  final String? footerLabel;
  final Widget Function(BuildContext context, T row)? titleBuilder;
  final ValueChanged<T>? onRowTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          _DetailsMobileRecord<T>(
            row: rows[index],
            columns: columns,
            titleBuilder: titleBuilder,
            onTap: onRowTap,
          ),
          if (index < rows.length - 1) const SizedBox(height: 10),
        ],
        if (footerLabel != null) ...[
          const SizedBox(height: 12),
          Text(
            footerLabel!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailsMobileRecord<T> extends StatelessWidget {
  const _DetailsMobileRecord({
    required this.row,
    required this.columns,
    required this.titleBuilder,
    required this.onTap,
  });

  final T row;
  final List<_DetailsTableColumn<T>> columns;
  final Widget Function(BuildContext context, T row)? titleBuilder;
  final ValueChanged<T>? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.22)),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titleBuilder != null) ...[
            titleBuilder!(context, row),
            const SizedBox(height: 10),
            Divider(color: colorScheme.outline.withValues(alpha: 0.22)),
            const SizedBox(height: 8),
          ],
          for (var index = 0; index < columns.length; index++) ...[
            _DetailsMobileField<T>(column: columns[index], row: row),
            if (index < columns.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTap!(row),
        child: content,
      ),
    );
  }
}

class _DetailsMobileField<T> extends StatelessWidget {
  const _DetailsMobileField({required this.column, required this.row});

  final _DetailsTableColumn<T> column;
  final T row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (column.mobileLabel ?? column.label).toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        DefaultTextStyle.merge(
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
          child: column.cellBuilder(context, row),
        ),
      ],
    );
  }
}

class _PropertyStats {
  const _PropertyStats({
    required this.herdTotal,
    required this.reproductionCount,
    required this.lastVisit,
  });

  final int herdTotal;
  final int reproductionCount;
  final VisitSummaryModel? lastVisit;

  DateTime? get lastVisitDate => lastVisit?.dataVisita;

  factory _PropertyStats.from(
    List<AnimalSummaryModel> animals,
    List<VisitSummaryModel> visits,
  ) {
    VisitSummaryModel? lastVisit;

    for (final visit in visits) {
      if (lastVisit == null || _compareVisitsByDateDesc(visit, lastVisit) < 0) {
        lastVisit = visit;
      }
    }

    return _PropertyStats(
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
  final status = IndicadorReprodutivoCalculator.resolveAnimalStatus(animal);
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

StatusBadgeType _propertyStatusBadgeType(PropertyStatus status) {
  return switch (status) {
    PropertyStatus.active => StatusBadgeType.success,
    PropertyStatus.inactive => StatusBadgeType.neutral,
  };
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

String _protocolLabel(VisitSummaryModel visit) {
  final animals = visit.animais;
  if (animals.isEmpty) return 'Visita tecnica';

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

  if (hasProtocol && hasDiagnosis) return 'IATF + Diagnostico';
  if (hasProtocol) return 'IATF / Protocolo reprodutivo';
  if (hasDiagnosis) return 'Diagnostico reprodutivo';
  return 'Conferencia tecnica';
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
          text: 'Pre-parto previsto para $identification.',
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
    return _cleanText(visit.observacoes) ?? 'Proximos passos pendentes.';
  }

  final first = steps.first;
  return '${formatDate(first.date)} - ${first.text}';
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

String _locationLabel(PropertySummaryModel property) {
  final city = _cleanText(property.cidade);
  final state = _cleanText(property.estado);
  final parts = [?city, ?state];
  return parts.isEmpty ? '--' : parts.join(' - ');
}

String _animalCategoryLabel(AnimalSummaryModel animal) {
  return [
    _dashIfBlank(animal.categoria),
    if (_cleanText(animal.sexo) != null) animal.sexo!.trim(),
  ].join(' / ');
}

String _animalCodeLabel(String code) {
  final text = code.trim();
  if (text.isEmpty) return '--';
  if (text.startsWith('#')) return text;
  return '#$text';
}

String _animalsRecordsLabel(int count) {
  return '$count ${count == 1 ? 'animal vinculado' : 'animais vinculados'}';
}

String _visitsRecordsLabel(int count) {
  return '$count ${count == 1 ? 'visita vinculada' : 'visitas vinculadas'}';
}

String _initialsFor(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) {
        return word.isNotEmpty;
      })
      .toList(growable: false);

  if (words.isEmpty) return 'PR';
  if (words.length == 1) {
    return words.first.substring(0, 1).toUpperCase();
  }

  return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'
      .toUpperCase();
}

String _dashIfBlank(String? value) {
  return _cleanText(value) ?? '--';
}

String? _cleanText(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

class _VisitNextStep {
  const _VisitNextStep({required this.date, required this.text});

  final DateTime date;
  final String text;
}
