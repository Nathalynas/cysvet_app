import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../properties/domain/property_summary_model.dart';
import '../domain/animal_import_field.dart';
import 'animals_excel_import_reader.dart';
import 'animals_excel_import_state.dart';
import 'animals_excel_import_validator.dart';

final animalsExcelImportControllerProvider =
    NotifierProvider<AnimalsExcelImportController, AnimalsExcelImportState>(
      AnimalsExcelImportController.new,
    );

class AnimalsExcelImportController extends Notifier<AnimalsExcelImportState> {
  final _reader = const AnimalsExcelImportReader();
  final _validator = const AnimalsExcelImportValidator();

  @override
  AnimalsExcelImportState build() {
    return const AnimalsExcelImportState();
  }

  void reset() {
    state = const AnimalsExcelImportState();
  }

  Future<void> loadFile({
    required List<int> bytes,
    required String fileName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final workbook = _reader.readWorkbook(bytes: bytes, fileName: fileName);
      if (workbook.sheetNames.isEmpty) {
        throw StateError('A planilha não possui abas disponíveis.');
      }

      state = AnimalsExcelImportState(
        step: AnimalsExcelImportStep.selectSheet,
        workbook: workbook,
        selectedSheetName: workbook.sheetNames.first,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Não foi possível ler o arquivo .xlsx.',
      );
    }
  }

  void selectSheet(String sheetName) {
    state = state.copyWith(
      selectedSheetName: sheetName,
      clearSheet: true,
      clearValidation: true,
      mappings: const {},
      clearError: true,
    );
  }

  Future<void> openSelectedSheet({
    required List<PropertySummaryModel> properties,
  }) async {
    final workbook = state.workbook;
    final sheetName = state.selectedSheetName;
    if (workbook == null || sheetName == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final sheet = _reader.readSheet(workbook: workbook, sheetName: sheetName);
      final mappings = _initialMappings(sheet);
      final validation = _validator.validate(
        sheet: sheet,
        mappings: mappings,
        properties: properties,
      );

      state = state.copyWith(
        step: AnimalsExcelImportStep.preview,
        isLoading: false,
        sheet: sheet,
        mappings: mappings,
        validation: validation,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Não foi possível abrir a aba selecionada.',
      );
    }
  }

  void mapColumn({
    required int columnIndex,
    required AnimalImportFieldKey field,
    required List<PropertySummaryModel> properties,
  }) {
    final sheet = state.sheet;
    if (sheet == null) return;

    final updated = <int, AnimalExcelColumnMapping>{...state.mappings};
    for (final entry in updated.entries.toList()) {
      if (entry.value.field == field) {
        updated[entry.key] = const AnimalExcelColumnMapping();
      }
    }

    updated[columnIndex] = AnimalExcelColumnMapping(field: field);
    _setMappings(updated, properties);
  }

  void ignoreColumn({
    required int columnIndex,
    required List<PropertySummaryModel> properties,
  }) {
    final updated = <int, AnimalExcelColumnMapping>{...state.mappings};
    updated[columnIndex] = const AnimalExcelColumnMapping(ignored: true);
    _setMappings(updated, properties);
  }

  void unmapColumn({
    required int columnIndex,
    required List<PropertySummaryModel> properties,
  }) {
    final updated = <int, AnimalExcelColumnMapping>{...state.mappings};
    updated[columnIndex] = const AnimalExcelColumnMapping();
    _setMappings(updated, properties);
  }

  void backToSheetSelection() {
    state = state.copyWith(
      step: AnimalsExcelImportStep.selectSheet,
      clearSheet: true,
      clearValidation: true,
      mappings: const {},
    );
  }

  Map<int, AnimalExcelColumnMapping> _initialMappings(
    AnimalExcelSheetData sheet,
  ) {
    final mappings = <int, AnimalExcelColumnMapping>{};
    final usedFields = <AnimalImportFieldKey>{};

    for (var index = 0; index < sheet.columns.length; index++) {
      final field = animalImportFieldForHeader(sheet.columns[index]);
      if (field == null || usedFields.contains(field.key)) {
        mappings[index] = const AnimalExcelColumnMapping();
        continue;
      }

      usedFields.add(field.key);
      mappings[index] = AnimalExcelColumnMapping(field: field.key);
    }

    return mappings;
  }

  void _setMappings(
    Map<int, AnimalExcelColumnMapping> mappings,
    List<PropertySummaryModel> properties,
  ) {
    final sheet = state.sheet;
    if (sheet == null) return;

    state = state.copyWith(
      mappings: mappings,
      validation: _validator.validate(
        sheet: sheet,
        mappings: mappings,
        properties: properties,
      ),
    );
  }
}
