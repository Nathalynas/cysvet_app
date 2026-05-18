import 'package:cysvet_app/core/constants/app_constants.dart';
import 'package:cysvet_app/core/enums/property_status.dart';
import 'package:cysvet_app/core/widgets/app_button.dart';
import 'package:cysvet_app/core/widgets/app_dialog.dart';
import 'package:cysvet_app/core/widgets/app_dropdown.dart';
import 'package:cysvet_app/core/widgets/search_card.dart';
import 'package:cysvet_app/core/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/presentation/async_value_view.dart';
import '../../../../core/presentation/app_scaffold_messenger.dart';
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

class PropertiesPage extends ConsumerWidget {
  const PropertiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(propertiesProvider);
    final searchQuery = ref.watch(propertiesSearchQueryProvider);
    final statusFilter = ref.watch(propertiesStatusFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(propertiesProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _PropertiesToolbar(
                searchQuery: searchQuery,
                statusFilter: statusFilter,
                onSearchChanged: (value) {
                  ref.read(propertiesSearchQueryProvider.notifier).state =
                      value;
                },
                onStatusChanged: (value) {
                  ref.read(propertiesStatusFilterProvider.notifier).state =
                      value ?? PropertyStatusFilter.all;
                },
                onCreate: () => PropertyDialog.show(context),
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

                  return Column(
                    children: [
                      for (final property in filteredItems) ...[
                        _PropertyCard(
                          property: property,
                          onEdit: () =>
                              PropertyDialog.show(context, property: property),
                          onInactivate: () =>
                              _confirmInactivate(context, ref, property),
                          onActivate: () =>
                              _confirmActivate(context, ref, property),
                          onDelete: () =>
                              _confirmDelete(context, ref, property),
                        ),
                        const SizedBox(height: 12),
                      ],
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
    final searchableText = 
      [
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
    required this.onEdit,
    required this.onInactivate,
    required this.onActivate,
    required this.onDelete,
  });

  final PropertySummaryModel property;
  final VoidCallback onEdit;
  final VoidCallback onInactivate;
  final VoidCallback onActivate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.agriculture_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    property.nome,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                StatusBadge(
                  label: property.status.label,
                  type: property.status == PropertyStatus.active
                      ? StatusBadgeType.success
                      : StatusBadgeType.neutral,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoLine(label: 'Responsavel', value: property.nomeProprietario),
            _InfoLine(label: 'Contato', value: property.contato ?? '--'),
            _InfoLine(label: 'Localizacao', value: property.localizacao),
            _InfoLine(label: 'ID externo', value: property.idExterno),
            if (property.observacoes != null &&
                property.observacoes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  property.observacoes!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            _CardActionRow(
              leadingActions: [
                AppButton(
                  text: 'Editar',
                  outlined: true,
                  height: 40,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                ),
              ],
              trailingActions: [
                AppButton(
                  text: property.status == PropertyStatus.inactive
                      ? 'Ativar'
                      : 'Inativar',
                  outlined: true,
                  height: 40,
                  icon: Icon(
                    property.status == PropertyStatus.inactive
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                    size: 18,
                  ),
                  onPressed: property.status == PropertyStatus.inactive
                      ? onActivate
                      : onInactivate,
                ),
                IconButton(
                  tooltip: 'Excluir',
                  color: colorScheme.error,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardActionRow extends StatelessWidget {
  const _CardActionRow({
    required this.leadingActions,
    required this.trailingActions,
  });

  final List<Widget> leadingActions;
  final List<Widget> trailingActions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: leadingActions),
        const Spacer(),
        Wrap(spacing: 8, runSpacing: 8, children: trailingActions),
      ],
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
