import 'package:uuid/uuid.dart';

import '../../../core/enums/animal_status.dart';
import '../../../core/utils/formatters.dart';
import '../../properties/domain/property_summary_model.dart';
import '../domain/animal_import_field.dart';
import '../domain/animal_summary_model.dart';
import 'animals_excel_import_state.dart';

class AnimalsExcelImportValidator {
  const AnimalsExcelImportValidator();

  AnimalExcelValidationResult validate({
    required AnimalExcelSheetData sheet,
    required Map<int, AnimalExcelColumnMapping> mappings,
    required List<PropertySummaryModel> properties,
  }) {
    final activeMappings = <int, AnimalImportFieldKey>{};
    mappings.forEach((columnIndex, mapping) {
      if (!mapping.ignored && mapping.field != null) {
        activeMappings[columnIndex] = mapping.field!;
      }
    });

    final mappedFields = activeMappings.values.toSet();
    final missingRequiredFields = requiredAnimalImportFields
        .where((field) {
          return !mappedFields.contains(field.key);
        })
        .toList(growable: false);

    final rows = <AnimalExcelRowValidation>[];
    for (var rowIndex = 0; rowIndex < sheet.rows.length; rowIndex++) {
      final row = sheet.rows[rowIndex];
      final parsedValues = <AnimalImportFieldKey, Object?>{};
      final issues = <AnimalExcelCellIssue>[];

      for (final entry in activeMappings.entries) {
        final columnIndex = entry.key;
        final field = entry.value.spec;
        final cell = columnIndex < row.cells.length
            ? row.cells[columnIndex]
            : const AnimalExcelCellValue(displayText: '');

        if (cell.isError) {
          issues.add(
            AnimalExcelCellIssue(
              columnIndex: columnIndex,
              message: 'Erro de fórmula',
            ),
          );
          continue;
        }

        final value = cell.displayText.trim();
        if (value.isEmpty) {
          if (field.required) {
            issues.add(
              AnimalExcelCellIssue(
                columnIndex: columnIndex,
                message: 'Campo obrigatório vazio',
              ),
            );
          }
          continue;
        }

        final parsed = _parseField(
          field: field,
          cell: cell,
          properties: properties,
        );

        if (!parsed.isValid) {
          issues.add(
            AnimalExcelCellIssue(
              columnIndex: columnIndex,
              message: parsed.errorMessage ?? 'Valor incompatível',
            ),
          );
          continue;
        }

        parsedValues[field.key] = parsed.value;
      }

      final status = issues.isNotEmpty
          ? AnimalsExcelRowStatus.invalid
          : missingRequiredFields.isNotEmpty
          ? AnimalsExcelRowStatus.pending
          : AnimalsExcelRowStatus.valid;

      rows.add(
        AnimalExcelRowValidation(
          rowIndex: rowIndex,
          excelRowNumber: row.excelRowNumber,
          status: status,
          issues: issues,
          animal: status == AnimalsExcelRowStatus.valid
              ? _buildAnimal(parsedValues)
              : null,
        ),
      );
    }

    return AnimalExcelValidationResult(
      rows: rows,
      missingRequiredFields: missingRequiredFields,
    );
  }

  _ParsedImportValue _parseField({
    required AnimalImportFieldSpec field,
    required AnimalExcelCellValue cell,
    required List<PropertySummaryModel> properties,
  }) {
    final text = cell.displayText.trim();

    switch (field.type) {
      case AnimalImportFieldType.text:
        return _ParsedImportValue.valid(text);
      case AnimalImportFieldType.integer:
        final value = _parseInteger(cell);
        if (value == null) {
          return const _ParsedImportValue.invalid('Informe um número inteiro');
        }
        return _ParsedImportValue.valid(value);
      case AnimalImportFieldType.date:
        final value = _parseDate(cell);
        if (value == null) {
          return const _ParsedImportValue.invalid('Informe uma data válida');
        }
        return _ParsedImportValue.valid(value);
      case AnimalImportFieldType.property:
        final value = findAnimalImportProperty(properties, text);
        if (value == null) {
          return const _ParsedImportValue.invalid('Propriedade não encontrada');
        }
        return _ParsedImportValue.valid(value);
      case AnimalImportFieldType.reproductiveStatus:
        final value = parseAnimalImportReproductiveStatus(text);
        if (value == null) {
          return const _ParsedImportValue.invalid(
            'Status reprodutivo inválido',
          );
        }
        return _ParsedImportValue.valid(value);
    }
  }

  AnimalSummaryModel _buildAnimal(Map<AnimalImportFieldKey, Object?> values) {
    final property =
        values[AnimalImportFieldKey.idPropriedade] as PropertySummaryModel;

    return AnimalSummaryModel(
      idExterno: const Uuid().v4(),
      idPropriedade: property.id,
      idExternoPropriedade: property.idExterno,
      codigo: values[AnimalImportFieldKey.codigo] as String,
      categoria: values[AnimalImportFieldKey.categoria] as String,
      dataNascimento: values[AnimalImportFieldKey.dataNascimento] as DateTime,
      statusReprodutivo:
          values[AnimalImportFieldKey.statusReprodutivo]
              as AnimalReproductiveStatus,
      numeroLactacao: values[AnimalImportFieldKey.numeroLactacao] as int,
      dataUltimoParto:
          values[AnimalImportFieldKey.dataUltimoParto] as DateTime?,
      dataInseminacao:
          values[AnimalImportFieldKey.dataInseminacao] as DateTime?,
      historicoReprodutivo:
          values[AnimalImportFieldKey.historicoReprodutivo] as String?,
      status: AnimalStatus.active,
    );
  }

  int? _parseInteger(AnimalExcelCellValue cell) {
    final raw = cell.rawValue;
    if (raw is int) return raw;
    if (raw is double && raw == raw.roundToDouble()) return raw.toInt();

    final normalized = cell.displayText.trim().replaceAll(',', '.');
    final parsed = num.tryParse(normalized);
    if (parsed == null || parsed != parsed.roundToDouble()) return null;
    return parsed.toInt();
  }

  DateTime? _parseDate(AnimalExcelCellValue cell) {
    final raw = cell.rawValue;
    if (raw is DateTime) return raw;
    if (raw is int) return _dateFromExcelSerial(raw.toDouble());
    if (raw is double) return _dateFromExcelSerial(raw);

    final text = cell.displayText.trim();
    if (text.isEmpty) return null;

    final typedDate = parseDateInput(text);
    if (typedDate != null) return typedDate;

    final numeric = double.tryParse(text.replaceAll(',', '.'));
    if (numeric != null) return _dateFromExcelSerial(numeric);

    return null;
  }

  DateTime? _dateFromExcelSerial(double value) {
    if (value < 1 || value > 80000) return null;
    final days = value.floor();
    return DateTime(1899, 12, 30).add(Duration(days: days));
  }
}

class _ParsedImportValue {
  const _ParsedImportValue._({
    required this.isValid,
    this.value,
    this.errorMessage,
  });

  const _ParsedImportValue.valid(Object? value)
    : this._(isValid: true, value: value);

  const _ParsedImportValue.invalid(String errorMessage)
    : this._(isValid: false, errorMessage: errorMessage);

  final bool isValid;
  final Object? value;
  final String? errorMessage;
}
