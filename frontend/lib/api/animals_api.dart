import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:cysvet_app/api/api_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/core/network/api_client.dart';
import 'package:cysvet_app/models/animal_history_event_model.dart';
import 'package:cysvet_app/models/animal_history_change_model.dart';
import 'package:cysvet_app/models/animal_summary_model.dart';
import 'package:cysvet_app/models/animal_import_field.dart';
import 'package:cysvet_app/providers/animals_excel_import_state.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';

final animalsRepositoryProvider = Provider<AnimalsRepository>((ref) {
  return AnimalsRepository(ref.watch(apiClientProvider));
});

class AnimalsRepository {
  AnimalsRepository(this._dio);

  final Dio _dio;

  Future<List<AnimalSummaryModel>> list({int? propertyId}) async {
    final response = await _dio.get<Object?>(
      '/api/animals',
      queryParameters: {
        ...?propertyId != null ? {'idPropriedade': propertyId} : null,
      },
    );

    final items = apiList(response.data);
    return items.map(AnimalSummaryModelMapper.fromMap).toList(growable: false);
  }

  Future<AnimalSummaryModel> create(AnimalSummaryModel animal) async {
    final response = await _dio.post<Object?>(
      '/api/animals',
      data: _toRequest(animal),
    );

    return AnimalSummaryModelMapper.fromMap(apiMap(response.data));
  }

  Future<AnimalSummaryModel> update(AnimalSummaryModel animal) async {
    final response = await _dio.put<Object?>(
      '/api/animals/${animal.id}',
      data: _toRequest(animal),
    );

    return AnimalSummaryModelMapper.fromMap(apiMap(response.data));
  }

  Future<AnimalSummaryModel> updateStatus({
    required int id,
    required AnimalStatus status,
  }) async {
    final response = await _dio.patch<Object?>(
      '/api/animals/$id/status',
      data: {'status': status.apiValue},
    );

    return AnimalSummaryModelMapper.fromMap(apiMap(response.data));
  }

  Future<void> delete(int id) async {
    await _dio.delete<Object?>('/api/animals/$id');
  }

  Future<List<AnimalHistoryEventModel>> listHistoryEvents({
    required int animalId,
  }) async {
    final response = await _dio.get<Object?>(
      '/api/events',
      queryParameters: {'idAnimal': animalId},
    );

    final items = apiList(response.data);
    return items.map(AnimalHistoryEventModel.fromMap).toList(growable: false);
  }

  Future<AnimalHistoryPayload> getHistory({required int animalId}) async {
    final response = await _dio.get<Object?>('/api/animals/$animalId/history');
    final map = apiMap(response.data);

    return AnimalHistoryPayload(
      animal: AnimalSummaryModelMapper.fromMap(apiMap(map['animal'])),
      events: apiList(
        map['eventos'],
      ).map(AnimalHistoryEventModel.fromMap).toList(growable: false),
      visits: apiList(
        map['visitas'],
      ).map(VisitSummaryModelMapper.fromMap).toList(growable: false),
      changes: apiList(
        map['alteracoes'],
      ).map(AnimalHistoryChangeModel.fromMap).toList(growable: false),
    );
  }

  Future<List<String>> inspectSpreadsheet({
    required List<int> bytes,
    required String fileName,
  }) async {
    final response = await _dio.post<Object?>(
      '/api/animals/import/xlsx/inspect',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      }),
    );
    if (response.data is! List) return const [];
    return (response.data as List)
        .map((item) => item.toString())
        .toList(growable: false);
  }

  Future<AnimalSpreadsheetPreview> previewSpreadsheet({
    required List<int> bytes,
    required String fileName,
    required String sheetName,
    required int propertyId,
    required Map<int, AnimalExcelColumnMapping> mappings,
  }) async {
    final response = await _dio.post<Object?>(
      '/api/animals/import/xlsx/preview',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
        'sheetName': sheetName,
        'idPropriedade': propertyId,
        'mappings': mappings.isEmpty
            ? null
            : jsonEncode(
                Map<String, String>.fromEntries(
                  mappings.entries
                      .where(
                        (entry) =>
                            !entry.value.ignored && entry.value.field != null,
                      )
                      .map(
                        (entry) =>
                            MapEntry('${entry.key}', entry.value.field!.name),
                      ),
                ),
              ),
      }),
    );
    return AnimalSpreadsheetPreview.fromMap(apiMap(response.data));
  }

  Future<AnimalSpreadsheetImportResult> importSpreadsheet({
    required List<int> bytes,
    required String fileName,
    required String sheetName,
    required int propertyId,
    required Map<int, AnimalExcelColumnMapping> mappings,
    required bool useAutomaticMapping,
  }) async {
    final encodedMappings = Map<String, String>.fromEntries(
      mappings.entries
          .where((entry) => !entry.value.ignored && entry.value.field != null)
          .map((entry) => MapEntry('${entry.key}', entry.value.field!.name)),
    );
    final response = await _dio.post<Object?>(
      '/api/animals/import/xlsx',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
        'sheetName': sheetName,
        'idPropriedade': propertyId,
        'mappings': useAutomaticMapping ? null : jsonEncode(encodedMappings),
      }),
    );
    final map = apiMap(response.data);
    return AnimalSpreadsheetImportResult(
      importedRows: (map['importedRows'] as num?)?.toInt() ?? 0,
      invalidRows: (map['invalidRows'] as num?)?.toInt() ?? 0,
      pendingRows: (map['pendingRows'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> _toRequest(AnimalSummaryModel animal) {
    return {
      'idExterno': animal.idExterno,
      'idPropriedade': animal.idPropriedade == 0 ? null : animal.idPropriedade,
      'idExternoPropriedade': animal.idExternoPropriedade.isEmpty
          ? null
          : animal.idExternoPropriedade,
      'codigo': animal.codigo,
      'dataNascimento': apiDate(animal.dataNascimento),
      'numeroLactacao': animal.numeroLactacao,
      'dataUltimoParto': apiDate(animal.dataUltimoParto),
      'dataInseminacao': apiDate(animal.dataInseminacao),
      'touroIa': animal.touroIa,
      'historicoReprodutivo': animal.historicoReprodutivo,
      'statusReprodutivo': animal.statusReprodutivo?.apiValue,
      'status': animal.status.apiValue,
      'dataAtualizacaoCliente': DateTime.now().toUtc().toIso8601String(),
    };
  }
}

class AnimalSpreadsheetPreview {
  const AnimalSpreadsheetPreview({
    required this.sheet,
    required this.mappings,
    required this.validation,
  });
  final AnimalExcelSheetData sheet;
  final Map<int, AnimalExcelColumnMapping> mappings;
  final AnimalExcelValidationResult validation;

  factory AnimalSpreadsheetPreview.fromMap(Map<String, dynamic> map) {
    final columns = (map['columns'] as List? ?? const [])
        .map((item) => item.toString())
        .toList(growable: false);
    final rows = (map['rows'] as List? ?? const [])
        .whereType<Map>()
        .map((item) {
          final row = item.map((key, value) => MapEntry(key.toString(), value));
          final issues = (row['issues'] as List? ?? const [])
              .whereType<Map>()
              .map(
                (issue) => AnimalExcelCellIssue(
                  columnIndex: (issue['columnIndex'] as num?)?.toInt() ?? 0,
                  message: issue['message']?.toString() ?? '',
                ),
              )
              .toList(growable: false);
          final status = switch (row['status']) {
            'valid' => AnimalsExcelRowStatus.valid,
            'invalid' => AnimalsExcelRowStatus.invalid,
            _ => AnimalsExcelRowStatus.pending,
          };
          return AnimalExcelRowValidation(
            rowIndex: 0,
            excelRowNumber: (row['excelRowNumber'] as num?)?.toInt() ?? 0,
            status: status,
            issues: issues,
          );
        })
        .toList(growable: false);
    final sheetRows = (map['rows'] as List? ?? const [])
        .whereType<Map>()
        .map((item) {
          final row = item.map((key, value) => MapEntry(key.toString(), value));
          return AnimalExcelDataRow(
            excelRowNumber: (row['excelRowNumber'] as num?)?.toInt() ?? 0,
            cells: (row['cells'] as List? ?? const [])
                .whereType<Map>()
                .map(
                  (cell) => AnimalExcelCellValue(
                    displayText: cell['displayText']?.toString() ?? '',
                    isError: cell['error'] == true,
                  ),
                )
                .toList(growable: false),
          );
        })
        .toList(growable: false);
    final rawMappings = map['mappings'] as Map? ?? const {};
    final mappings = <int, AnimalExcelColumnMapping>{
      for (var i = 0; i < columns.length; i++)
        i: AnimalExcelColumnMapping(
          field: AnimalImportFieldKey.values
              .where(
                (field) =>
                    rawMappings['$i'] == field.name ||
                    rawMappings[i] == field.name,
              )
              .firstOrNull,
        ),
    };
    final missing = (map['missingRequiredFields'] as List? ?? const [])
        .map(
          (key) => AnimalImportFieldKey.values
              .where((field) => field.name == key)
              .firstOrNull,
        )
        .whereType<AnimalImportFieldKey>()
        .map((key) => key.spec)
        .toList(growable: false);
    return AnimalSpreadsheetPreview(
      sheet: AnimalExcelSheetData(
        sheetName: map['sheetName']?.toString() ?? '',
        headerRowIndex: (map['headerRowIndex'] as num?)?.toInt() ?? 0,
        columns: columns,
        rows: sheetRows,
      ),
      mappings: mappings,
      validation: AnimalExcelValidationResult(
        rows: rows,
        missingRequiredFields: missing,
        validRows: (map['validRows'] as num?)?.toInt(),
        pendingRows: (map['pendingRows'] as num?)?.toInt(),
        invalidRows: (map['invalidRows'] as num?)?.toInt(),
      ),
    );
  }
}

class AnimalSpreadsheetImportResult {
  const AnimalSpreadsheetImportResult({
    required this.importedRows,
    required this.invalidRows,
    required this.pendingRows,
  });
  final int importedRows;
  final int invalidRows;
  final int pendingRows;
}

class AnimalHistoryPayload {
  const AnimalHistoryPayload({
    required this.animal,
    required this.events,
    required this.visits,
    required this.changes,
  });

  final AnimalSummaryModel animal;
  final List<AnimalHistoryEventModel> events;
  final List<VisitSummaryModel> visits;
  final List<AnimalHistoryChangeModel> changes;
}
