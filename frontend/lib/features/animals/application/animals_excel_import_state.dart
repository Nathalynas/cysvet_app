import '../domain/animal_import_field.dart';
import '../domain/animal_summary_model.dart';

enum AnimalsExcelImportStep { selectFile, selectSheet, preview }

enum AnimalsExcelRowStatus { valid, pending, invalid }

class AnimalExcelWorkbookInfo {
  const AnimalExcelWorkbookInfo({
    required this.fileName,
    required this.bytes,
    required this.sheetNames,
  });

  final String fileName;
  final List<int> bytes;
  final List<String> sheetNames;
}

class AnimalExcelCellValue {
  const AnimalExcelCellValue({
    required this.displayText,
    this.rawValue,
    this.isError = false,
  });

  final String displayText;
  final Object? rawValue;
  final bool isError;

  bool get isBlank => displayText.trim().isEmpty;
}

class AnimalExcelDataRow {
  const AnimalExcelDataRow({required this.excelRowNumber, required this.cells});

  final int excelRowNumber;
  final List<AnimalExcelCellValue> cells;
}

class AnimalExcelSheetData {
  const AnimalExcelSheetData({
    required this.sheetName,
    required this.headerRowIndex,
    required this.columns,
    required this.rows,
  });

  final String sheetName;
  final int headerRowIndex;
  final List<String> columns;
  final List<AnimalExcelDataRow> rows;
}

class AnimalExcelColumnMapping {
  const AnimalExcelColumnMapping({this.field, this.ignored = false});

  final AnimalImportFieldKey? field;
  final bool ignored;

  AnimalExcelColumnMapping copyWith({
    AnimalImportFieldKey? field,
    bool clearField = false,
    bool? ignored,
  }) {
    return AnimalExcelColumnMapping(
      field: clearField ? null : field ?? this.field,
      ignored: ignored ?? this.ignored,
    );
  }
}

class AnimalExcelCellIssue {
  const AnimalExcelCellIssue({
    required this.columnIndex,
    required this.message,
  });

  final int columnIndex;
  final String message;
}

class AnimalExcelRowValidation {
  const AnimalExcelRowValidation({
    required this.rowIndex,
    required this.excelRowNumber,
    required this.status,
    required this.issues,
    this.animal,
  });

  final int rowIndex;
  final int excelRowNumber;
  final AnimalsExcelRowStatus status;
  final List<AnimalExcelCellIssue> issues;
  final AnimalSummaryModel? animal;

  bool hasIssueAt(int columnIndex) {
    return issues.any((issue) => issue.columnIndex == columnIndex);
  }

  String issueTextAt(int columnIndex) {
    return issues
        .where((issue) => issue.columnIndex == columnIndex)
        .map((issue) => issue.message)
        .join('; ');
  }
}

class AnimalExcelImportSummary {
  const AnimalExcelImportSummary({
    required this.validRows,
    required this.pendingRows,
    required this.invalidRows,
  });

  final int validRows;
  final int pendingRows;
  final int invalidRows;
}

class AnimalExcelValidationResult {
  const AnimalExcelValidationResult({
    required this.rows,
    required this.missingRequiredFields,
  });

  final List<AnimalExcelRowValidation> rows;
  final List<AnimalImportFieldSpec> missingRequiredFields;

  AnimalExcelImportSummary get summary {
    var valid = 0;
    var pending = 0;
    var invalid = 0;

    for (final row in rows) {
      switch (row.status) {
        case AnimalsExcelRowStatus.valid:
          valid++;
        case AnimalsExcelRowStatus.pending:
          pending++;
        case AnimalsExcelRowStatus.invalid:
          invalid++;
      }
    }

    return AnimalExcelImportSummary(
      validRows: valid,
      pendingRows: pending,
      invalidRows: invalid,
    );
  }

  List<AnimalSummaryModel> get validAnimals {
    return rows
        .where((row) => row.status == AnimalsExcelRowStatus.valid)
        .map((row) => row.animal)
        .whereType<AnimalSummaryModel>()
        .toList(growable: false);
  }
}

class AnimalsExcelImportState {
  const AnimalsExcelImportState({
    this.step = AnimalsExcelImportStep.selectFile,
    this.isLoading = false,
    this.errorMessage,
    this.workbook,
    this.selectedSheetName,
    this.sheet,
    this.mappings = const {},
    this.validation,
  });

  final AnimalsExcelImportStep step;
  final bool isLoading;
  final String? errorMessage;
  final AnimalExcelWorkbookInfo? workbook;
  final String? selectedSheetName;
  final AnimalExcelSheetData? sheet;
  final Map<int, AnimalExcelColumnMapping> mappings;
  final AnimalExcelValidationResult? validation;

  bool get canSelectSheet {
    return workbook != null && selectedSheetName != null && !isLoading;
  }

  bool get canImport {
    final validationResult = validation;
    if (validationResult == null) return false;
    return validationResult.missingRequiredFields.isEmpty &&
        validationResult.validAnimals.isNotEmpty;
  }

  AnimalsExcelImportState copyWith({
    AnimalsExcelImportStep? step,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    AnimalExcelWorkbookInfo? workbook,
    bool clearWorkbook = false,
    String? selectedSheetName,
    bool clearSelectedSheetName = false,
    AnimalExcelSheetData? sheet,
    bool clearSheet = false,
    Map<int, AnimalExcelColumnMapping>? mappings,
    AnimalExcelValidationResult? validation,
    bool clearValidation = false,
  }) {
    return AnimalsExcelImportState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      workbook: clearWorkbook ? null : workbook ?? this.workbook,
      selectedSheetName: clearSelectedSheetName
          ? null
          : selectedSheetName ?? this.selectedSheetName,
      sheet: clearSheet ? null : sheet ?? this.sheet,
      mappings: mappings ?? this.mappings,
      validation: clearValidation ? null : validation ?? this.validation,
    );
  }
}
