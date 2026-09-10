import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/animals_repository.dart';
import '../domain/animal_import_field.dart';
import 'animals_excel_import_state.dart';

final animalsExcelImportControllerProvider =
    NotifierProvider<AnimalsExcelImportController, AnimalsExcelImportState>(
      AnimalsExcelImportController.new,
    );

class AnimalsExcelImportController extends Notifier<AnimalsExcelImportState> {
  AnimalsRepository get _repository => ref.read(animalsRepositoryProvider);

  @override
  AnimalsExcelImportState build() => const AnimalsExcelImportState();

  void reset() => state = const AnimalsExcelImportState();

  Future<void> loadFile({
    required List<int> bytes,
    required String fileName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sheets = await _repository.inspectSpreadsheet(
        bytes: bytes,
        fileName: fileName,
      );
      if (sheets.isEmpty) throw StateError('Planilha sem abas.');
      final workbook = AnimalExcelWorkbookInfo(
        fileName: fileName,
        bytes: List<int>.from(bytes),
        sheetNames: sheets,
      );
      state = AnimalsExcelImportState(
        step: AnimalsExcelImportStep.selectSheet,
        workbook: workbook,
        selectedSheetName: sheets.first,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Não foi possível ler o arquivo .xlsx.',
      );
    }
  }

  void selectSheet(String name) => state = state.copyWith(
    selectedSheetName: name,
    clearSheet: true,
    clearValidation: true,
    mappings: const {},
    clearError: true,
  );

  void selectProperty(int? propertyId) => state = state.copyWith(
    selectedPropertyId: propertyId,
    clearSelectedPropertyId: propertyId == null,
    clearError: true,
  );

  Future<void> openSelectedSheet() => _loadPreview(const {}, autoMapping: true);

  Future<void> mapColumn({
    required int columnIndex,
    required AnimalImportFieldKey field,
  }) async {
    final mappings = <int, AnimalExcelColumnMapping>{...state.mappings};
    for (final entry in mappings.entries.toList()) {
      if (entry.value.field == field) {
        mappings[entry.key] = const AnimalExcelColumnMapping();
      }
    }
    mappings[columnIndex] = AnimalExcelColumnMapping(field: field);
    await _loadPreview(mappings, autoMapping: false);
  }

  Future<void> ignoreColumn({required int columnIndex}) async {
    final mappings = <int, AnimalExcelColumnMapping>{...state.mappings};
    mappings[columnIndex] = const AnimalExcelColumnMapping(ignored: true);
    await _loadPreview(mappings, autoMapping: false);
  }

  Future<void> unmapColumn({required int columnIndex}) async {
    final mappings = <int, AnimalExcelColumnMapping>{...state.mappings};
    mappings[columnIndex] = const AnimalExcelColumnMapping();
    await _loadPreview(mappings, autoMapping: false);
  }

  void backToSheetSelection() => state = state.copyWith(
    step: AnimalsExcelImportStep.selectSheet,
    clearSheet: true,
    clearValidation: true,
    mappings: const {},
  );

  Future<AnimalSpreadsheetImportResult?> importValidRows() async {
    final workbook = state.workbook;
    final sheetName = state.selectedSheetName;
    final propertyId = state.selectedPropertyId;
    if (workbook == null ||
        sheetName == null ||
        propertyId == null ||
        !state.canImport) {
      return null;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.importSpreadsheet(
        bytes: workbook.bytes,
        fileName: workbook.fileName,
        sheetName: sheetName,
        propertyId: propertyId,
        mappings: state.mappings,
        useAutomaticMapping: state.usesAutomaticMapping,
      );
      state = state.copyWith(isLoading: false);
      return result;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Não foi possível importar os animais da planilha.',
      );
      return null;
    }
  }

  Future<void> _loadPreview(
    Map<int, AnimalExcelColumnMapping> mappings, {
    required bool autoMapping,
  }) async {
    final workbook = state.workbook;
    final sheetName = state.selectedSheetName;
    final propertyId = state.selectedPropertyId;
    if (workbook == null || sheetName == null || propertyId == null) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      mappings: mappings,
      usesAutomaticMapping: autoMapping,
    );
    try {
      final preview = await _repository.previewSpreadsheet(
        bytes: workbook.bytes,
        fileName: workbook.fileName,
        sheetName: sheetName,
        propertyId: propertyId,
        mappings: mappings,
      );
      state = state.copyWith(
        step: AnimalsExcelImportStep.preview,
        isLoading: false,
        sheet: preview.sheet,
        mappings: preview.mappings,
        usesAutomaticMapping: autoMapping,
        validation: preview.validation,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Não foi possível analisar as abas da planilha.',
      );
    }
  }
}
