import 'dart:async';
import 'dart:math' as math;

import 'package:cysvet_app/app/app_shell.dart';
import 'package:cysvet_app/app/theme.dart';
import 'package:cysvet_app/core/constants/app_constants.dart';
import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/core/enums/property_status.dart';
import 'package:cysvet_app/core/presentation/app_scaffold_messenger.dart';
import 'package:cysvet_app/core/utils/formatters.dart';
import 'package:cysvet_app/core/widgets/app_button.dart';
import 'package:cysvet_app/core/widgets/app_card.dart';
import 'package:cysvet_app/core/widgets/app_dialog.dart';
import 'package:cysvet_app/core/widgets/app_table.dart';
import 'package:cysvet_app/core/widgets/status_badge.dart';
import 'package:cysvet_app/providers/animals_provider.dart';
import 'package:cysvet_app/api/animals_api.dart';
import 'package:cysvet_app/models/animal_summary_model.dart';
import 'package:cysvet_app/pages/animals/animal_dialog.dart';
import 'package:cysvet_app/pages/animals/animal_history_dialog.dart';
import 'package:cysvet_app/pages/animals/animal_mobile_card.dart';
import 'package:cysvet_app/providers/auth_state.dart';
import 'package:cysvet_app/models/indicador_reprodutivo_calculator.dart';
import 'package:cysvet_app/providers/properties_provider.dart';
import 'package:cysvet_app/api/properties_api.dart';
import 'package:cysvet_app/models/property_summary_model.dart';
import 'package:cysvet_app/pages/properties/property_dialog.dart';
import 'package:cysvet_app/providers/visits_provider.dart';
import 'package:cysvet_app/api/visits_api.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';
import 'package:cysvet_app/pages/visits/visit_mobile_card.dart';
import 'package:cysvet_app/pages/visits/visit_report_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
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

      final session = ref.watch(authSessionProvider);
      final localItems = ref.watch(localPropertiesProvider);
      final deletedIds = ref.watch(deletedPropertiesProvider);

      if (session == null) {
        throw StateError('Sessao indisponivel.');
      }

      if (deletedIds.contains(propertyId)) {
        throw StateError('Propriedade nao encontrada.');
      }

      final localProperty = localItems[propertyId];
      if (localProperty != null) {
        return localProperty;
      }

      return ref.watch(propertiesRepositoryProvider).getById(propertyId);
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
          onEdit: () => _openEdit(property),
          onToggleStatus: () => _confirmToggleStatus(property),
          onDelete: () => _confirmDelete(property),
          onCreateVisit: () {
            context.go('/visitas/nova?propriedade=${property.id}');
          },
        ),
        const SizedBox(height: 16),
        _PropertyTabsCard(
          activeTab: _activeTab,
          onTabChanged: (tab) => setState(() => _activeTab = tab),
          child: _tabContent(
            property,
            animalsValue,
            visitsValue,
            stats,
            statsLoading,
          ),
        ),
      ],
    );
  }

  Widget _tabContent(
    PropertySummaryModel property,
    AsyncValue<List<AnimalSummaryModel>> animalsValue,
    AsyncValue<List<VisitSummaryModel>> visitsValue,
    _PropertyStats? stats,
    bool statsLoading,
  ) {
    return switch (_activeTab) {
      PropertyTab.general => _PropertyGeneralTab(
        property: property,
        stats: stats,
        statsLoading: statsLoading,
      ),
      PropertyTab.animals => _PropertyAnimalsTab(
        property: property,
        value: animalsValue,
        onEdit: (animal) => _openAnimalEdit(property, animal),
        onToggleStatus: _confirmToggleAnimalStatus,
        onDelete: _confirmDeleteAnimal,
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

  Future<void> _openAnimalEdit(
    PropertySummaryModel property,
    AnimalSummaryModel animal,
  ) async {
    await AnimalDialog.show(context, properties: [property], animal: animal);
    if (!mounted) return;
    ref.invalidate(propertyDetailsAnimalsProvider(widget.propertyId));
  }

  Future<void> _confirmToggleAnimalStatus(AnimalSummaryModel animal) {
    return animal.status == AnimalStatus.inactive
        ? _confirmActivateAnimal(animal)
        : _confirmInactivateAnimal(animal);
  }

  Future<void> _confirmInactivateAnimal(AnimalSummaryModel animal) {
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
          ref.invalidate(propertyDetailsAnimalsProvider(widget.propertyId));
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

  Future<void> _confirmActivateAnimal(AnimalSummaryModel animal) {
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
          ref.invalidate(propertyDetailsAnimalsProvider(widget.propertyId));
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

  Future<void> _confirmDeleteAnimal(AnimalSummaryModel animal) {
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
          ref.invalidate(propertyDetailsAnimalsProvider(widget.propertyId));
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
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onCreateVisit,
  });

  final PropertySummaryModel property;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;
  final VoidCallback onCreateVisit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 18,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 760;
          final identity = _PropertySummaryIdentity(property: property);
          final actions = _PropertyActions(
            property: property,
            onEdit: onEdit,
            onToggleStatus: onToggleStatus,
            onDelete: onDelete,
            onCreateVisit: onCreateVisit,
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
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _PropertySummaryIdentity extends StatelessWidget {
  const _PropertySummaryIdentity({required this.property});

  final PropertySummaryModel property;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary2 = AppTheme.primary2Color;
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
            color: primary2.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              _initialsFor(property.nome),
              style: theme.textTheme.titleMedium?.copyWith(
                color: primary2,
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
                  _PropertyStatusBadge(status: property.status),
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
                  if (_cleanText(property.contato) != null)
                    _SummaryMetaItem(
                      icon: Icons.phone_outlined,
                      text: property.contato!.trim(),
                    ),
                  if (hasLocation)
                    _SummaryMetaItem(
                      icon: Icons.place_outlined,
                      text: _locationLabel(property),
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

class _PropertyStatsPanel extends StatelessWidget {
  const _PropertyStatsPanel({
    required this.stats,
    required this.loading,
    required this.stacked,
  });

  final _PropertyStats? stats;
  final bool loading;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final loadingLabel = loading && stats == null ? '...' : '--';
    final cards = [
      _PropertyMetricCard(
        label: 'Rebanho total',
        value: stats == null ? loadingLabel : formatInteger(stats!.herdTotal),
      ),
      _PropertyMetricCard(
        label: 'Em produção',
        value: stats == null
            ? loadingLabel
            : formatInteger(stats!.reproductionCount),
        highlighted: true,
      ),
      _PropertyMetricCard(
        label: 'Última visita',
        value: stats == null ? loadingLabel : formatDate(stats!.lastVisitDate),
      ),
    ];

    if (stacked) {
      return Row(
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            Expanded(child: cards[index]),
            if (index < cards.length - 1) const SizedBox(width: 10),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < cards.length; index++) ...[
          cards[index],
          if (index < cards.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PropertyMetricCard extends StatelessWidget {
  const _PropertyMetricCard({
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

class _PropertyActions extends StatelessWidget {
  const _PropertyActions({
    required this.property,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onCreateVisit,
  });

  final PropertySummaryModel property;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;
  final VoidCallback onCreateVisit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isInactive = property.status == PropertyStatus.inactive;
    final toggleTooltip = isInactive ? 'Ativar' : 'Inativar';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        _PropertyActionButton(
          label: 'Editar',
          icon: Icons.edit_outlined,
          onPressed: onEdit,
        ),
        _PropertyActionButton(
          label: toggleTooltip,
          icon: isInactive ? Icons.unarchive_outlined : Icons.archive_outlined,
          onPressed: onToggleStatus,
        ),
        _PropertyActionButton(
          label: 'Excluir',
          icon: Icons.delete_outline,
          color: colorScheme.error,
          onPressed: onDelete,
        ),
        AppButton(
          text: 'Nova visita',
          icon: const Icon(Icons.add, size: 18),
          height: 38,
          borderRadius: 12,
          shadow: false,
          onPressed: onCreateVisit,
        ),
      ],
    );
  }
}

class _PropertyActionButton extends StatelessWidget {
  const _PropertyActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return AppButton(
      text: label,
      outlined: true,
      height: 38,
      borderRadius: 12,
      shadow: false,
      color: effectiveColor,
      textColor: effectiveColor,
      backgroundColor: Colors.transparent,
      borderColor: effectiveColor.withValues(alpha: 0.36),
      icon: Icon(icon, size: 18),
      onPressed: onPressed,
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
    final tabs = SingleChildScrollView(
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
    );

    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tabs,
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
  const _PropertyGeneralTab({
    required this.property,
    required this.stats,
    required this.statsLoading,
  });

  final PropertySummaryModel property;
  final _PropertyStats? stats;
  final bool statsLoading;

  @override
  Widget build(BuildContext context) {
    final details = _DetailsFieldGrid(
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
    final statsPanel = SizedBox(
      width: 250,
      child: _PropertyStatsPanel(
        stats: stats,
        loading: statsLoading,
        stacked: false,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              details,
              const SizedBox(height: 14),
              Align(alignment: Alignment.centerLeft, child: statsPanel),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: details),
            const SizedBox(width: 18),
            statsPanel,
          ],
        );
      },
    );
  }
}

class _PropertyAnimalsTab extends StatelessWidget {
  const _PropertyAnimalsTab({
    required this.property,
    required this.value,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onRetry,
  });

  final PropertySummaryModel property;
  final AsyncValue<List<AnimalSummaryModel>> value;
  final ValueChanged<AnimalSummaryModel> onEdit;
  final ValueChanged<AnimalSummaryModel> onToggleStatus;
  final ValueChanged<AnimalSummaryModel> onDelete;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (animals) => _PropertyAnimalsTable(
        property: property,
        animals: animals,
        onEdit: onEdit,
        onToggleStatus: onToggleStatus,
        onDelete: onDelete,
      ),
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
  const _PropertyAnimalsTable({
    required this.property,
    required this.animals,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final PropertySummaryModel property;
  final List<AnimalSummaryModel> animals;
  final ValueChanged<AnimalSummaryModel> onEdit;
  final ValueChanged<AnimalSummaryModel> onToggleStatus;
  final ValueChanged<AnimalSummaryModel> onDelete;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < MOBILE_WIDTH;

    if (isMobile) {
      return AnimalMobileCardList(
        animals: animals,
        propertyNameFor: (_) => property.nome,
        onTap: (animal) => AnimalHistoryDialog.show(
          context: context,
          animal: animal,
          propertyName: property.nome,
        ),
        onEdit: onEdit,
        onInactivate: onToggleStatus,
        onActivate: onToggleStatus,
        onDelete: onDelete,
        footerLabel: _animalsRecordsLabel(animals.length),
        emptyMessage: 'Nenhum animal vinculado a esta propriedade.',
      );
    }

    final table = AppTable<AnimalSummaryModel>(
      rows: animals,
      footerLabel: _animalsRecordsLabel(animals.length),
      emptyMessage: 'Nenhum animal vinculado a esta propriedade.',
      mobileBreakpoint: 1180,
      borderRadius: 16,
      shadow: false,
      onRowTap: (animal) => AnimalHistoryDialog.show(
        context: context,
        animal: animal,
        propertyName: property.nome,
      ),
      mobileTitleBuilder: (context, animal) {
        return _AnimalIdentityCell(animal: animal);
      },
      columns: [
        AppTableColumn<AnimalSummaryModel>(
          label: 'Identificação\n(Brinco)',
          mobileLabel: 'Identificação/Brinco',
          flex: 3,
          alignment: Alignment.centerLeft,
          headerAlignment: Alignment.center,
          cellBuilder: (context, animal) => _AnimalIdentityCell(animal: animal),
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Touro IA',
          flex: 2,
          alignment: Alignment.center,
          cellBuilder: (context, animal) =>
              Center(child: _AnimalIaBullCell(animal: animal)),
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Idade',
          flex: 2,
          cellBuilder: (context, animal) => _AnimalTableText(
            value: _animalAgeLabel(animal.dataNascimento, DateTime.now()),
          ),
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Último parto',
          flex: 2,
          cellBuilder: (context, animal) =>
              _AnimalTableText(value: formatDate(animal.dataUltimoParto)),
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Produtiva',
          flex: 2,
          cellBuilder: (context, animal) =>
              _AnimalTableText(value: _animalProductiveStatusLabel(animal)),
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Status',
          flex: 2,
          alignment: Alignment.center,
          cellBuilder: (context, animal) =>
              Center(child: _AnimalStatusPill(status: animal.status)),
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Status\nreprodutivo',
          mobileLabel: 'Status reprodutivo',
          flex: 2,
          alignment: Alignment.center,
          cellBuilder: (context, animal) {
            final status = IndicadorReprodutivoCalculator.resolveAnimalStatus(
              animal,
            );
            return Center(child: _ReproductiveStatusPill(status: status));
          },
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Decisão/obs.',
          mobileLabel: 'Decisão/observação',
          flex: 3,
          cellBuilder: (context, animal) => _AnimalTableText(
            value: _dashIfBlank(animal.historicoReprodutivo),
          ),
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Última IA',
          flex: 2,
          cellBuilder: (context, animal) =>
              _AnimalTableText(value: formatDate(animal.dataInseminacao)),
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'IAs',
          alignment: Alignment.center,
          cellBuilder: (context, animal) =>
              const _AnimalTableText(value: '--', textAlign: TextAlign.center),
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Prenhez',
          alignment: Alignment.center,
          cellBuilder: (context, animal) => _AnimalTableText(
            value: _animalPregnancyDaysLabel(animal, DateTime.now()),
            textAlign: TextAlign.center,
          ),
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'DEL',
          alignment: Alignment.center,
          cellBuilder: (context, animal) => _AnimalTableText(
            value: _formatNullableInt(animal.diasEmLactacao),
            textAlign: TextAlign.center,
          ),
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Dias secar',
          flex: 2,
          alignment: Alignment.center,
          cellBuilder: (context, animal) =>
              const _AnimalTableText(value: '--', textAlign: TextAlign.center),
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Secagem',
          flex: 2,
          cellBuilder: (context, animal) => const _AnimalTableText(value: '--'),
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Pré-parto',
          flex: 2,
          cellBuilder: (context, animal) => const _AnimalTableText(value: '--'),
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Parto',
          flex: 2,
          cellBuilder: (context, animal) => const _AnimalTableText(value: '--'),
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Último evento',
          flex: 2,
          cellBuilder: (context, animal) =>
              _AnimalLastEventText(animal: animal),
        ),
        AppTableColumn<AnimalSummaryModel>(
          label: 'Ações',
          flex: 1,
          alignment: Alignment.center,
          cellBuilder: (context, animal) => Center(
            child: _AnimalActionsMenu(
              animal: animal,
              onEdit: () => onEdit(animal),
              onToggleStatus: () => onToggleStatus(animal),
              onDelete: () => onDelete(animal),
            ),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1180) {
          return table;
        }

        final tableWidth = math.max(1880.0, constraints.maxWidth);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: SizedBox(width: tableWidth, child: table),
        );
      },
    );
  }
}

class _PropertyVisitsTable extends StatelessWidget {
  const _PropertyVisitsTable({required this.property, required this.visits});

  final PropertySummaryModel property;
  final List<VisitSummaryModel> visits;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < MOBILE_WIDTH;

    if (isMobile) {
      return VisitMobileCardList<VisitSummaryModel>(
        items: visits,
        visitFor: (visit) => visit,
        propertyNameFor: (_) => property.nome,
        onTap: (visit) => _openVisit(context, visit),
        footerLabel: _visitsRecordsLabel(visits.length),
        emptyMessage: 'Nenhuma visita vinculada a esta propriedade.',
      );
    }

    return AppTable<VisitSummaryModel>(
      rows: visits,
      footerLabel: _visitsRecordsLabel(visits.length),
      emptyMessage: 'Nenhuma visita vinculada a esta propriedade.',
      borderRadius: 16,
      shadow: false,
      onRowTap: (visit) => _openVisit(context, visit),
      mobileTitleBuilder: (context, visit) {
        return _PropertyVisitIdentity(visit: visit);
      },
      columns: [
        AppTableColumn<VisitSummaryModel>(
          label: 'Visita',
          flex: 3,
          alignment: Alignment.centerLeft,
          headerAlignment: Alignment.centerLeft,
          cellBuilder: (context, visit) => _PropertyVisitIdentity(visit: visit),
        ),
        AppTableColumn<VisitSummaryModel>(
          label: 'Protocolo',
          flex: 3,
          cellBuilder: (context, visit) =>
              _PropertyVisitText(value: _protocolLabel(visit), maxLines: 2),
        ),
        AppTableColumn<VisitSummaryModel>(
          label: 'Próximo passo',
          flex: 4,
          cellBuilder: (context, visit) =>
              _PropertyVisitText(value: _nextStepText(visit), maxLines: 2),
        ),
        AppTableColumn<VisitSummaryModel>(
          label: 'Animais',
          flex: 1,
          cellBuilder: (context, visit) => _PropertyVisitMetric(
            value: visit.animais.length.toString(),
            label: 'Animais',
          ),
        ),
        AppTableColumn<VisitSummaryModel>(
          label: 'Prenhas',
          flex: 1,
          cellBuilder: (context, visit) => _PropertyVisitMetric(
            value: _visitPregnantCountLabel(visit),
            label: 'Prenhas',
            highlighted: true,
          ),
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

class _PropertyVisitIdentity extends StatelessWidget {
  const _PropertyVisitIdentity({required this.visit});

  final VisitSummaryModel visit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary2 = AppTheme.primary2Color;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primary2.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(Icons.description_outlined, size: 19, color: primary2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatDate(visit.dataVisita),
                maxLines: 3,
                overflow: TextOverflow.visible,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _dashIfBlank(visit.veterinarioResponsavel),
                maxLines: 3,
                overflow: TextOverflow.visible,
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

class _PropertyVisitText extends StatelessWidget {
  const _PropertyVisitText({required this.value, this.maxLines = 1});

  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }
}

class _PropertyVisitMetric extends StatelessWidget {
  const _PropertyVisitMetric({
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
    final valueColor = highlighted
        ? AppTheme.primary2Color
        : colorScheme.onSurface;

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

class _AnimalIdentityCell extends StatelessWidget {
  const _AnimalIdentityCell({required this.animal});

  final AnimalSummaryModel animal;

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
                maxLines: 3,
                overflow: TextOverflow.visible,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _dashIfBlank(animal.idExterno),
                maxLines: 3,
                overflow: TextOverflow.visible,
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
          animal.touroIa?.trim().isNotEmpty == true ? animal.touroIa! : '--',
          maxLines: 3,
          overflow: TextOverflow.visible,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'Nascimento: ${formatDate(animal.dataNascimento)}',
          maxLines: 2,
          overflow: TextOverflow.visible,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          'Lactação: ${animal.numeroLactacao}',
          maxLines: 2,
          overflow: TextOverflow.visible,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AnimalTableText extends StatelessWidget {
  const _AnimalTableText({required this.value, this.textAlign});

  final String value;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 6,
      overflow: TextOverflow.visible,
      textAlign: textAlign,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }
}

class _AnimalLastEventText extends StatelessWidget {
  const _AnimalLastEventText({required this.animal});

  final AnimalSummaryModel animal;

  @override
  Widget build(BuildContext context) {
    final lastBirth = animal.dataUltimoParto;
    final inseminationDate = animal.dataInseminacao;

    if (lastBirth != null) {
      return _AnimalTableText(value: 'Parto em ${formatDate(lastBirth)}');
    }

    if (inseminationDate != null) {
      return _AnimalTableText(value: 'IA em ${formatDate(inseminationDate)}');
    }

    final history = _cleanText(animal.historicoReprodutivo);
    return _AnimalTableText(value: history ?? 'Sem evento');
  }
}

class _AnimalStatusPill extends StatelessWidget {
  const _AnimalStatusPill({required this.status});

  final AnimalStatus status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == AnimalStatus.active;

    return StatusBadge(
      label: status.label,
      type: _animalStatusBadgeType(status),
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

enum _AnimalAction { edit, toggleActive, delete }

class _AnimalActionsMenu extends StatelessWidget {
  const _AnimalActionsMenu({
    required this.animal,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final AnimalSummaryModel animal;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isInactive = animal.status == AnimalStatus.inactive;

    return PopupMenuButton<_AnimalAction>(
      tooltip: 'Ações',
      padding: EdgeInsets.zero,
      onSelected: (action) {
        switch (action) {
          case _AnimalAction.edit:
            onEdit();
            break;
          case _AnimalAction.toggleActive:
            onToggleStatus();
            break;
          case _AnimalAction.delete:
            onDelete();
            break;
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
            title: Text(isInactive ? 'Ativar' : 'Inativar'),
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
      child: IgnorePointer(
        child: AppButton(
          outlined: true,
          width: 36,
          height: 36,
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          borderColor: colorScheme.outline.withValues(alpha: 0.55),
          shadow: false,
          color: colorScheme.primary,
          textColor: colorScheme.primary,
          onPressed: () {},
          child: const Icon(Icons.more_vert, size: 20),
        ),
      ),
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

String _visitPregnantCountLabel(VisitSummaryModel visit) {
  final pregnant = visit.animais.where(_isPregnant).length;
  return pregnant == 0 ? '--' : pregnant.toString();
}

String _animalAgeLabel(DateTime? birthDate, DateTime now) {
  if (birthDate == null) return '--';

  var months = (now.year - birthDate.year) * 12 + now.month - birthDate.month;
  if (now.day < birthDate.day) months--;
  if (months < 0) return '--';
  if (months < 24) return '$months ${months == 1 ? 'mês' : 'meses'}';

  final years = months ~/ 12;
  final remainingMonths = months % 12;
  if (remainingMonths == 0) return '$years ${years == 1 ? 'ano' : 'anos'}';
  return '$years a $remainingMonths m';
}

String _animalProductiveStatusLabel(AnimalSummaryModel animal) {
  final text = [
    animal.historicoReprodutivo,
    animal.statusReprodutivo?.label,
  ].whereType<String>().join(' ').normalize();

  if (text.contains('novilha')) return 'Novilha';
  if (text.contains('seca')) return 'Seca';
  if (text.contains('lact') ||
      animal.diasEmLactacao != null ||
      animal.numeroLactacao > 0) {
    return 'Lactante';
  }
  return 'Não informada';
}

String _animalPregnancyDaysLabel(AnimalSummaryModel animal, DateTime now) {
  final status = IndicadorReprodutivoCalculator.resolveAnimalStatus(animal);
  final insemination = animal.dataInseminacao;

  if (status != AnimalReproductiveStatus.pregnant || insemination == null) {
    return '--';
  }

  final days = now.difference(insemination).inDays;
  return days < 0 ? '--' : days.toString();
}

String _formatNullableInt(int? value) {
  return value == null ? '--' : formatInteger(value);
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

StatusBadgeType _animalStatusBadgeType(AnimalStatus status) {
  return switch (status) {
    AnimalStatus.active => StatusBadgeType.success,
    AnimalStatus.sold => StatusBadgeType.info,
    AnimalStatus.death => StatusBadgeType.error,
    AnimalStatus.inactive => StatusBadgeType.neutral,
  };
}

String _protocolLabel(VisitSummaryModel visit) {
  return _cleanText(visit.observacoes) ?? '--';
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
