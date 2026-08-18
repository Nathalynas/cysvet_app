import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_scaffold_messenger.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../properties/domain/property_summary_model.dart';
import '../application/animals_excel_import_controller.dart';
import '../application/animals_excel_import_state.dart';
import '../domain/animal_import_field.dart';
import '../domain/animal_summary_model.dart';

class AnimalExcelImportDialog extends ConsumerStatefulWidget {
  const AnimalExcelImportDialog({super.key, required this.properties});

  final List<PropertySummaryModel> properties;

  static Future<List<AnimalSummaryModel>?> show(
    BuildContext context, {
    required List<PropertySummaryModel> properties,
  }) {
    return AppDialog.show<List<AnimalSummaryModel>>(
      context: context,
      title: 'Importar animais por Excel',
      width: 1180,
      height: 720,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      fullscreenOnMobile: true,
      fullscreenBodyPadding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      useInternalScroll: false,
      content: AnimalExcelImportDialog(properties: properties),
    );
  }

  @override
  ConsumerState<AnimalExcelImportDialog> createState() {
    return _AnimalExcelImportDialogState();
  }
}

class _AnimalExcelImportDialogState
    extends ConsumerState<AnimalExcelImportDialog> {
  static const _maxPreviewRows = 160;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(animalsExcelImportControllerProvider.notifier).reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(animalsExcelImportControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildStep(context, state)),
        const SizedBox(height: 14),
        _DialogFooter(
          state: state,
          onPickFile: _pickFile,
          onBack: () => ref
              .read(animalsExcelImportControllerProvider.notifier)
              .backToSheetSelection(),
          onAdvance: () => ref
              .read(animalsExcelImportControllerProvider.notifier)
              .openSelectedSheet(properties: widget.properties),
          onImport: () {
            final animals = state.validation?.validAnimals ?? const [];
            Navigator.of(context).maybePop(animals);
          },
        ),
      ],
    );
  }

  Widget _buildStep(BuildContext context, AnimalsExcelImportState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (state.step) {
      case AnimalsExcelImportStep.selectFile:
        return _FileStep(
          errorMessage: state.errorMessage,
          onPickFile: _pickFile,
        );
      case AnimalsExcelImportStep.selectSheet:
        return _SheetStep(
          state: state,
          onSheetChanged: (sheetName) {
            if (sheetName == null) return;
            ref
                .read(animalsExcelImportControllerProvider.notifier)
                .selectSheet(sheetName);
          },
        );
      case AnimalsExcelImportStep.preview:
        return _PreviewStep(
          state: state,
          properties: widget.properties,
          maxPreviewRows: _maxPreviewRows,
        );
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      showAppError('Não foi possível ler o arquivo selecionado.');
      return;
    }

    await ref
        .read(animalsExcelImportControllerProvider.notifier)
        .loadFile(bytes: bytes, fileName: file.name);
  }
}

class _FileStep extends StatelessWidget {
  const _FileStep({required this.errorMessage, required this.onPickFile});

  final String? errorMessage;
  final VoidCallback onPickFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.table_chart_outlined,
              size: 46,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 18),
            Text(
              'Selecione uma planilha .xlsx para iniciar a importação.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'As abas serão lidas antes da prévia, e os campos serão mapeados contra o cadastro atual de animais.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 22),
            Center(
              child: AppButton(
                text: 'Selecionar Excel',
                icon: const Icon(Icons.upload_file_outlined),
                onPressed: onPickFile,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetStep extends StatelessWidget {
  const _SheetStep({required this.state, required this.onSheetChanged});

  final AnimalsExcelImportState state;
  final ValueChanged<String?> onSheetChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workbook = state.workbook!;

    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              borderRadius: 12,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      workbook.fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppDropdown<String>(
              labelText: 'Aba da planilha',
              value: state.selectedSheetName,
              onChanged: onSheetChanged,
              options: workbook.sheetNames
                  .map((name) => AppDropdownOption(label: name, value: name))
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            Text(
              '${workbook.sheetNames.length} abas encontradas.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewStep extends ConsumerWidget {
  const _PreviewStep({
    required this.state,
    required this.properties,
    required this.maxPreviewRows,
  });

  final AnimalsExcelImportState state;
  final List<PropertySummaryModel> properties;
  final int maxPreviewRows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheet = state.sheet!;
    final validation = state.validation!;
    final visibleRows = sheet.rows.take(maxPreviewRows).toList(growable: false);
    final hiddenRows = sheet.rows.length - visibleRows.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryHeader(state: state),
        if (validation.missingRequiredFields.isNotEmpty) ...[
          const SizedBox(height: 10),
          _MissingFieldsBanner(fields: validation.missingRequiredFields),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: _PreviewTable(
            sheet: sheet,
            rows: visibleRows,
            validation: validation,
            mappings: state.mappings,
            properties: properties,
          ),
        ),
        if (hiddenRows > 0) ...[
          const SizedBox(height: 8),
          Text(
            'Exibindo $maxPreviewRows de ${sheet.rows.length} linhas lidas.',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.state});

  final AnimalsExcelImportState state;

  @override
  Widget build(BuildContext context) {
    final validation = state.validation!;
    final summary = validation.summary;
    final sheet = state.sheet!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final children = [
          _SummaryTile(
            label: 'Linhas válidas',
            value: summary.validRows,
            icon: Icons.check_circle_outline,
            color: const Color(0xFF0D6B42),
          ),
          _SummaryTile(
            label: 'Com pendências',
            value: summary.pendingRows,
            icon: Icons.pending_actions_outlined,
            color: const Color(0xFF8A5C00),
          ),
          _SummaryTile(
            label: 'Inválidas',
            value: summary.invalidRows,
            icon: Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
        ];

        final info = Text(
          '${sheet.columns.length} colunas lidas em "${sheet.sheetName}". Cabeçalho detectado na linha ${sheet.headerRowIndex + 1}.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              info,
              const SizedBox(height: 10),
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: info),
            const SizedBox(width: 12),
            ...children.expand((child) => [child, const SizedBox(width: 8)]),
          ]..removeLast(),
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        color: color.withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value.toString(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
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

class _MissingFieldsBanner extends StatelessWidget {
  const _MissingFieldsBanner({required this.fields});

  final List<AnimalImportFieldSpec> fields;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_outlined, color: colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Campos obrigatórios sem mapeamento: ${fields.map((field) => field.label).join(', ')}.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewTable extends ConsumerWidget {
  const _PreviewTable({
    required this.sheet,
    required this.rows,
    required this.validation,
    required this.mappings,
    required this.properties,
  });

  final AnimalExcelSheetData sheet;
  final List<AnimalExcelDataRow> rows;
  final AnimalExcelValidationResult validation;
  final Map<int, AnimalExcelColumnMapping> mappings;
  final List<PropertySummaryModel> properties;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final validationByRow = {
      for (final row in validation.rows) row.rowIndex: row,
    };

    return Scrollbar(
      child: SingleChildScrollView(
        child: Scrollbar(
          notificationPredicate: (notification) => notification.depth == 1,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 96,
              dataRowMinHeight: 46,
              dataRowMaxHeight: 58,
              horizontalMargin: 12,
              columnSpacing: 10,
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.22),
                ),
                verticalInside: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.14),
                ),
              ),
              columns: [
                DataColumn(
                  label: SizedBox(
                    width: 118,
                    child: Text(
                      'Linha',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                for (
                  var columnIndex = 0;
                  columnIndex < sheet.columns.length;
                  columnIndex++
                )
                  DataColumn(
                    label: _ColumnHeader(
                      columnIndex: columnIndex,
                      originalName: sheet.columns[columnIndex],
                      mapping:
                          mappings[columnIndex] ??
                          const AnimalExcelColumnMapping(),
                      properties: properties,
                    ),
                  ),
              ],
              rows: [
                for (var rowIndex = 0; rowIndex < rows.length; rowIndex++)
                  DataRow(
                    color: WidgetStatePropertyAll(
                      rowIndex.isEven
                          ? colorScheme.surface
                          : colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.22,
                            ),
                    ),
                    cells: [
                      DataCell(
                        _RowStatusCell(
                          validation: validationByRow[rowIndex],
                          excelRowNumber: rows[rowIndex].excelRowNumber,
                        ),
                      ),
                      for (
                        var columnIndex = 0;
                        columnIndex < sheet.columns.length;
                        columnIndex++
                      )
                        DataCell(
                          _ImportCell(
                            cell: rows[rowIndex].cells[columnIndex],
                            validation: validationByRow[rowIndex],
                            columnIndex: columnIndex,
                            ignored: mappings[columnIndex]?.ignored ?? false,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColumnHeader extends ConsumerWidget {
  const _ColumnHeader({
    required this.columnIndex,
    required this.originalName,
    required this.mapping,
    required this.properties,
  });

  static const _unmappedValue = '__unmapped__';
  static const _ignoredValue = '__ignored__';

  final int columnIndex;
  final String originalName;
  final AnimalExcelColumnMapping mapping;
  final List<PropertySummaryModel> properties;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedValue = mapping.ignored
        ? _ignoredValue
        : mapping.field?.name ?? _unmappedValue;

    final options = [
      const AppDropdownOption<String>(
        label: 'Selecionar campo',
        value: _unmappedValue,
      ),
      const AppDropdownOption<String>(
        label: 'Não importar',
        value: _ignoredValue,
      ),
      ...animalImportFields.map((field) {
        return AppDropdownOption<String>(
          label: field.required ? '${field.label} *' : field.label,
          value: field.key.name,
        );
      }),
    ];

    return SizedBox(
      width: 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: AppDropdown<String>(
                  labelText: 'Campo do sistema',
                  value: selectedValue,
                  height: 40,
                  menuMaxHeight: 360,
                  onChanged: (value) {
                    final controller = ref.read(
                      animalsExcelImportControllerProvider.notifier,
                    );

                    if (value == null || value == _unmappedValue) {
                      controller.unmapColumn(
                        columnIndex: columnIndex,
                        properties: properties,
                      );
                      return;
                    }

                    if (value == _ignoredValue) {
                      controller.ignoreColumn(
                        columnIndex: columnIndex,
                        properties: properties,
                      );
                      return;
                    }

                    controller.mapColumn(
                      columnIndex: columnIndex,
                      field: AnimalImportFieldKey.values.firstWhere(
                        (field) => field.name == value,
                      ),
                      properties: properties,
                    );
                  },
                  options: options,
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: 'Não importar coluna',
                child: AppButton(
                  outlined: true,
                  width: 34,
                  height: 40,
                  padding: EdgeInsets.zero,
                  shadow: false,
                  borderColor: Colors.transparent,
                  onPressed: () {
                    ref
                        .read(animalsExcelImportControllerProvider.notifier)
                        .ignoreColumn(
                          columnIndex: columnIndex,
                          properties: properties,
                        );
                  },
                  child: const Icon(Icons.visibility_off_outlined, size: 17),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            originalName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowStatusCell extends StatelessWidget {
  const _RowStatusCell({
    required this.validation,
    required this.excelRowNumber,
  });

  final AnimalExcelRowValidation? validation;
  final int excelRowNumber;

  @override
  Widget build(BuildContext context) {
    final status = validation?.status ?? AnimalsExcelRowStatus.pending;
    final colorScheme = Theme.of(context).colorScheme;

    final (label, icon, color) = switch (status) {
      AnimalsExcelRowStatus.valid => (
        'Válida',
        Icons.check_circle_outline,
        const Color(0xFF0D6B42),
      ),
      AnimalsExcelRowStatus.pending => (
        'Pendente',
        Icons.pending_actions_outlined,
        const Color(0xFF8A5C00),
      ),
      AnimalsExcelRowStatus.invalid => (
        'Inválida',
        Icons.error_outline,
        colorScheme.error,
      ),
    };

    return SizedBox(
      width: 118,
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '$excelRowNumber · $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportCell extends StatelessWidget {
  const _ImportCell({
    required this.cell,
    required this.validation,
    required this.columnIndex,
    required this.ignored,
  });

  final AnimalExcelCellValue cell;
  final AnimalExcelRowValidation? validation;
  final int columnIndex;
  final bool ignored;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final issueText = validation?.issueTextAt(columnIndex) ?? '';
    final hasIssue = issueText.isNotEmpty;
    final hasExcelError =
        cell.isError || cell.displayText.trim().toUpperCase().contains('#REF!');

    final background = hasIssue || hasExcelError
        ? colorScheme.errorContainer.withValues(alpha: 0.72)
        : ignored
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.52)
        : Colors.transparent;

    final foreground = hasIssue || hasExcelError
        ? colorScheme.onErrorContainer
        : ignored
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurface;

    final message = hasIssue
        ? issueText
        : hasExcelError
        ? 'Erro de fórmula'
        : ignored
        ? 'Coluna marcada para não importar'
        : '';

    final child = Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        cell.displayText.trim().isEmpty ? '--' : cell.displayText.trim(),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: foreground,
          fontWeight: hasIssue || hasExcelError ? FontWeight.w800 : null,
        ),
      ),
    );

    if (message.isEmpty) return child;
    return Tooltip(message: message, child: child);
  }
}

class _DialogFooter extends StatelessWidget {
  const _DialogFooter({
    required this.state,
    required this.onPickFile,
    required this.onBack,
    required this.onAdvance,
    required this.onImport,
  });

  final AnimalsExcelImportState state;
  final VoidCallback onPickFile;
  final VoidCallback onBack;
  final VoidCallback onAdvance;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final validCount = state.validation?.validAnimals.length ?? 0;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: [
        AppButton(
          text: 'Cancelar',
          outlined: true,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        if (state.step != AnimalsExcelImportStep.selectFile)
          AppButton(
            text: 'Trocar arquivo',
            outlined: true,
            icon: const Icon(Icons.upload_file_outlined),
            onPressed: onPickFile,
          ),
        if (state.step == AnimalsExcelImportStep.preview)
          AppButton(
            text: 'Voltar',
            outlined: true,
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
        if (state.step == AnimalsExcelImportStep.selectSheet)
          AppButton(
            text: 'Avançar',
            disabled: !state.canSelectSheet,
            icon: const Icon(Icons.arrow_forward),
            onPressed: onAdvance,
          ),
        if (state.step == AnimalsExcelImportStep.preview)
          AppButton(
            text: 'Importar $validCount',
            disabled: !state.canImport,
            icon: const Icon(Icons.check),
            onPressed: onImport,
          ),
      ],
    );
  }
}
