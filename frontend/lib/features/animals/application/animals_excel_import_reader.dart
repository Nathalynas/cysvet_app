import 'package:excel/excel.dart';

import '../domain/animal_import_field.dart';
import 'animals_excel_import_state.dart';

class AnimalsExcelImportReader {
  const AnimalsExcelImportReader();

  AnimalExcelWorkbookInfo readWorkbook({
    required List<int> bytes,
    required String fileName,
  }) {
    final excel = Excel.decodeBytes(bytes);
    final sheetNames = excel.tables.keys.toList(growable: false);

    return AnimalExcelWorkbookInfo(
      fileName: fileName,
      bytes: List<int>.from(bytes),
      sheetNames: sheetNames,
    );
  }

  AnimalExcelSheetData readSheet({
    required AnimalExcelWorkbookInfo workbook,
    required String sheetName,
  }) {
    final excel = Excel.decodeBytes(workbook.bytes);
    final sheet = excel.tables[sheetName];
    if (sheet == null) {
      throw StateError('Aba não encontrada: $sheetName.');
    }

    final matrix = _readMatrix(sheet);
    if (matrix.isEmpty) {
      return AnimalExcelSheetData(
        sheetName: sheetName,
        headerRowIndex: 0,
        columns: const [],
        rows: const [],
      );
    }

    final headerRowIndex = _detectHeaderRow(matrix);
    final maxColumns = matrix
        .map((row) => row.length)
        .fold<int>(0, (max, length) => length > max ? length : max);

    final headerRow = matrix[headerRowIndex];
    final columns = List.generate(maxColumns, (index) {
      final header = index < headerRow.length
          ? headerRow[index].displayText.trim()
          : '';
      return header.isEmpty ? 'Coluna ${index + 1}' : header;
    }, growable: false);

    final rows = <AnimalExcelDataRow>[];
    for (
      var rowIndex = headerRowIndex + 1;
      rowIndex < matrix.length;
      rowIndex++
    ) {
      final row = _padRow(matrix[rowIndex], maxColumns);
      if (row.every((cell) => cell.isBlank)) continue;

      rows.add(AnimalExcelDataRow(excelRowNumber: rowIndex + 1, cells: row));
    }

    return AnimalExcelSheetData(
      sheetName: sheetName,
      headerRowIndex: headerRowIndex,
      columns: columns,
      rows: rows,
    );
  }

  List<List<AnimalExcelCellValue>> _readMatrix(Sheet sheet) {
    final rows = sheet.rows;
    if (rows.isEmpty) return const [];

    final maxColumns = sheet.maxColumns;
    return List.generate(rows.length, (rowIndex) {
      final row = rows[rowIndex];
      return List.generate(maxColumns, (columnIndex) {
        final cell = columnIndex < row.length ? row[columnIndex] : null;
        return _readCell(cell?.value);
      }, growable: false);
    }, growable: false);
  }

  AnimalExcelCellValue _readCell(CellValue? value) {
    if (value == null) {
      return const AnimalExcelCellValue(displayText: '');
    }

    return switch (value) {
      TextCellValue() => AnimalExcelCellValue(
        displayText: value.value.toString(),
        rawValue: value.value.toString(),
      ),
      IntCellValue() => AnimalExcelCellValue(
        displayText: value.value.toString(),
        rawValue: value.value,
      ),
      DoubleCellValue() => AnimalExcelCellValue(
        displayText: _formatDouble(value.value),
        rawValue: value.value,
      ),
      BoolCellValue() => AnimalExcelCellValue(
        displayText: value.value ? 'TRUE' : 'FALSE',
        rawValue: value.value,
      ),
      DateCellValue() => AnimalExcelCellValue(
        displayText: _formatDate(value.asDateTimeLocal()),
        rawValue: value.asDateTimeLocal(),
      ),
      DateTimeCellValue() => AnimalExcelCellValue(
        displayText: _formatDate(value.asDateTimeLocal()),
        rawValue: value.asDateTimeLocal(),
      ),
      TimeCellValue() => AnimalExcelCellValue(
        displayText: value.toString(),
        rawValue: value.asDuration(),
      ),
      FormulaCellValue() => _readFormulaCell(value),
    };
  }

  AnimalExcelCellValue _readFormulaCell(FormulaCellValue value) {
    final formula = value.formula.trim();
    final normalized = formula.toUpperCase().replaceAll('#', '');
    final isError = _excelErrors.contains(normalized);
    final displayText = isError ? '#$normalized' : '=$formula';

    return AnimalExcelCellValue(
      displayText: displayText,
      rawValue: formula,
      isError: isError,
    );
  }

  int _detectHeaderRow(List<List<AnimalExcelCellValue>> rows) {
    var bestIndex = 0;
    var bestScore = -1;
    var bestNonEmpty = -1;
    final limit = rows.length < 30 ? rows.length : 30;

    for (var rowIndex = 0; rowIndex < limit; rowIndex++) {
      final row = rows[rowIndex];
      final nonEmpty = row.where((cell) => !cell.isBlank).length;
      if (nonEmpty == 0) continue;

      final matchedFields = <AnimalImportFieldKey>{};
      for (final cell in row) {
        final field = animalImportFieldForHeader(cell.displayText);
        if (field != null) matchedFields.add(field.key);
      }

      final score = matchedFields.length;
      if (score > bestScore ||
          (score == bestScore && nonEmpty > bestNonEmpty)) {
        bestIndex = rowIndex;
        bestScore = score;
        bestNonEmpty = nonEmpty;
      }
    }

    return bestIndex;
  }

  List<AnimalExcelCellValue> _padRow(
    List<AnimalExcelCellValue> row,
    int maxColumns,
  ) {
    if (row.length >= maxColumns) return row;

    return [
      ...row,
      for (var index = row.length; index < maxColumns; index++)
        const AnimalExcelCellValue(displayText: ''),
    ];
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    return '$day/$month/$year';
  }

  String _formatDouble(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  static const _excelErrors = {
    'REF!',
    'VALUE!',
    'DIV/0!',
    'NAME?',
    'N/A',
    'NULL!',
    'NUM!',
  };
}
