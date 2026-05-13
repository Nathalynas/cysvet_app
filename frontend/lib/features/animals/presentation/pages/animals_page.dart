import 'dart:convert';

import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/core/presentation/app_scaffold_messenger.dart';
import 'package:cysvet_app/core/widgets/app_button.dart';
import 'package:cysvet_app/core/widgets/app_dialog.dart';
import 'package:cysvet_app/core/widgets/app_dropdown.dart';
import 'package:cysvet_app/core/widgets/property_filter_card.dart';
import 'package:cysvet_app/core/widgets/search_card.dart';
import 'package:cysvet_app/core/widgets/status_badge.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/presentation/async_value_view.dart';
import '../../../../core/utils/formatters.dart';
import '../../../properties/application/properties_provider.dart';
import '../../../properties/domain/property_summary_model.dart';
import '../../application/animals_csv_importer.dart';
import '../../application/animals_provider.dart';
import '../../domain/animal_summary_model.dart';
import '../widgets/animal_dialog.dart';

final animalsSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);
final animalsStatusFilterProvider =
    StateProvider.autoDispose<AnimalStatusFilter>((ref) {
      return AnimalStatusFilter.active;
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
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _AnimalsToolbar(
                properties: propertyOptions,
                searchQuery: searchQuery,
                selectedPropertyId: selectedPropertyId,
                statusFilter: statusFilter,
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
                onImport: () =>
                    _importAnimalsCsv(context, ref, propertyOptions),
                onCreate: () =>
                    AnimalDialog.show(context, properties: propertyOptions),
              ),
              const SizedBox(height: 16),
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
                  );
                  if (filteredItems.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(
                        child: Text(
                          'Nenhum animal encontrado para os filtros atuais.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (final animal in filteredItems) ...[
                        _AnimalCard(
                          animal: animal,
                          propertyName:
                              propertyById[animal.idPropriedade]?.nome ??
                              animal.idExternoPropriedade,
                          onEdit: () => AnimalDialog.show(
                            context,
                            properties: propertyOptions,
                            animal: animal,
                          ),
                          onInactivate: () =>
                              _confirmInactivate(context, ref, animal),
                          onActivate: () =>
                              _confirmActivate(context, ref, animal),
                          onDelete: () => _confirmDelete(context, ref, animal),
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

class _AnimalsToolbar extends StatelessWidget {
  const _AnimalsToolbar({
    required this.properties,
    required this.searchQuery,
    required this.selectedPropertyId,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onPropertyChanged,
    required this.onStatusChanged,
    required this.onImport,
    required this.onCreate,
  });

  final List<PropertySummaryModel> properties;
  final String searchQuery;
  final int? selectedPropertyId;
  final AnimalStatusFilter statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int?> onPropertyChanged;
  final ValueChanged<AnimalStatusFilter?> onStatusChanged;
  final VoidCallback onImport;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 980;
        final search = SearchCard(
          value: searchQuery,
          labelText: 'Pesquisar por brinco/ID',
          onChanged: onSearchChanged,
        );
        final propertyFilter = PropertyFilterCard(
          properties: properties,
          selectedPropertyId: selectedPropertyId,
          onChanged: onPropertyChanged,
        );
        final status = AppDropdown<AnimalStatusFilter>(
          value: statusFilter,
          labelText: 'Status',
          onChanged: onStatusChanged,
          options: AnimalStatusFilter.values
              .map((item) => AppDropdownOption(label: item.label, value: item))
              .toList(growable: false),
        );
        final importButton = Tooltip(
          message: 'Importar CSV',
          child: AppButton(
            outlined: true,
            width: 48,
            onPressed: onImport,
            child: const Icon(Icons.upload_file_outlined),
          ),
        );
        final createButton = AppButton(
          text: 'Novo animal',
          icon: const Icon(Icons.add),
          onPressed: onCreate,
        );

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
            SizedBox(width: 190, child: status),
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
) {
  final normalizedQuery = _normalize(query.trim());
  return items.where((animal) {
    final matchesStatus = switch (statusFilter) {
      AnimalStatusFilter.all => true,
      AnimalStatusFilter.active => animal.status == AnimalStatus.active,
      AnimalStatusFilter.inactive => animal.status != AnimalStatus.active,
    };
    final searchable = _normalize(
      '${animal.codigo} ${animal.idExterno} ${animal.categoria} ${animal.sexo ?? ''}',
    );
    return matchesStatus &&
        (normalizedQuery.isEmpty || searchable.contains(normalizedQuery));
  }).toList();
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp('[áàâãä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòôõö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll('ç', 'c');
}

class _AnimalCard extends StatelessWidget {
  const _AnimalCard({
    required this.animal,
    required this.propertyName,
    required this.onEdit,
    required this.onInactivate,
    required this.onActivate,
    required this.onDelete,
  });

  final AnimalSummaryModel animal;
  final String propertyName;
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
                const Icon(Icons.pets),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    animal.codigo,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                StatusBadge(
                  label: animal.status.label,
                  type: animal.status == AnimalStatus.active
                      ? StatusBadgeType.success
                      : StatusBadgeType.neutral,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Line(label: 'Propriedade', value: propertyName),
            _Line(label: 'Especie', value: animal.categoria),
            _Line(label: 'Sexo', value: animal.sexo ?? '--'),
            _Line(
              label: 'Nascimento',
              value: formatDate(animal.dataNascimento),
            ),
            _Line(label: 'Lactacao', value: animal.numeroLactacao.toString()),
            if (animal.historicoReprodutivo != null &&
                animal.historicoReprodutivo!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(animal.historicoReprodutivo!),
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
                  text: animal.status == AnimalStatus.inactive
                      ? 'Ativar'
                      : 'Inativar',
                  outlined: true,
                  height: 40,
                  icon: Icon(
                    animal.status == AnimalStatus.inactive
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                    size: 18,
                  ),
                  onPressed: animal.status == AnimalStatus.inactive
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

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

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
    showAppError('Nao foi possivel ler o arquivo CSV.');
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
    content: Text('Deseja excluir ${animal.codigo} desta sessao?'),
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
          '${importResult.animals.length} registros validos encontrados.',
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
            'Mais ${importResult.animals.length - validItems.length} registros validos.',
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
