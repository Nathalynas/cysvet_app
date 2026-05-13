import 'package:uuid/uuid.dart';

import '../../../core/enums/animal_status.dart';
import '../../properties/domain/property_summary_model.dart';
import '../domain/animal_summary_model.dart';

class AnimalCsvImportResult {
  const AnimalCsvImportResult({required this.animals, required this.errors});

  final List<AnimalSummaryModel> animals;
  final List<AnimalCsvImportError> errors;

  bool get hasErrors => errors.isNotEmpty;
}

class AnimalCsvImportError {
  const AnimalCsvImportError({required this.line, required this.message});

  final int line;
  final String message;
}

class AnimalsCsvImporter {
  const AnimalsCsvImporter();

  AnimalCsvImportResult parse({
    required String content,
    required List<PropertySummaryModel> properties,
  }) {
    final rows = _parseRows(content);
    final errors = <AnimalCsvImportError>[];
    final animals = <AnimalSummaryModel>[];

    if (rows.isEmpty) {
      return const AnimalCsvImportResult(
        animals: [],
        errors: [AnimalCsvImportError(line: 1, message: 'Arquivo vazio.')],
      );
    }

    final headers = rows.first.map(_normalizeHeader).toList(growable: false);
    final columnIndex = _buildColumnIndex(headers);
    final missingColumns = _requiredColumns.where((column) {
      return columnIndex[column] == null;
    }).toList();

    if (missingColumns.isNotEmpty) {
      return AnimalCsvImportResult(
        animals: const [],
        errors: [
          AnimalCsvImportError(
            line: 1,
            message:
                'Colunas obrigatorias ausentes: ${missingColumns.join(', ')}.',
          ),
        ],
      );
    }

    for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      if (row.every((value) => value.trim().isEmpty)) continue;

      final line = rowIndex + 1;
      final codigo = _read(row, columnIndex, 'codigo');
      final categoria = _read(row, columnIndex, 'categoria');
      final sexo = _read(row, columnIndex, 'sexo');
      final dataNascimentoRaw = _read(row, columnIndex, 'dataNascimento');
      final statusRaw = _read(row, columnIndex, 'status');
      final propriedadeRaw = _read(row, columnIndex, 'propriedade');

      final rowErrors = <String>[];
      if (codigo.isEmpty) rowErrors.add('codigo/brinco vazio');
      if (categoria.isEmpty) rowErrors.add('categoria/especie vazia');
      if (sexo.isEmpty) rowErrors.add('sexo vazio');

      final dataNascimento = _parseDate(dataNascimentoRaw);
      if (dataNascimentoRaw.isNotEmpty && dataNascimento == null) {
        rowErrors.add('dataNascimento invalida');
      }

      final status = _parseStatus(statusRaw);
      if (statusRaw.isNotEmpty && status == null) {
        rowErrors.add('status invalido');
      }

      final property = _findProperty(properties, propriedadeRaw);
      if (property == null) {
        rowErrors.add('propriedade nao encontrada');
      }

      if (rowErrors.isNotEmpty) {
        errors.add(
          AnimalCsvImportError(line: line, message: rowErrors.join('; ')),
        );
        continue;
      }

      animals.add(
        AnimalSummaryModel(
          idExterno: const Uuid().v4(),
          idPropriedade: property!.id,
          idExternoPropriedade: property.idExterno,
          codigo: codigo,
          categoria: categoria,
          sexo: sexo,
          dataNascimento: dataNascimento,
          numeroLactacao: 0,
          status: status ?? AnimalStatus.active,
        ),
      );
    }

    return AnimalCsvImportResult(animals: animals, errors: errors);
  }

  Map<String, int> _buildColumnIndex(List<String> headers) {
    final result = <String, int>{};

    for (var index = 0; index < headers.length; index++) {
      final header = headers[index];
      final canonical = _columnAliases[header];
      if (canonical != null) result[canonical] = index;
    }

    return result;
  }

  String _read(List<String> row, Map<String, int> columnIndex, String column) {
    final index = columnIndex[column];
    if (index == null || index >= row.length) return '';
    return row[index].trim();
  }

  List<List<String>> _parseRows(String content) {
    final rows = <List<String>>[];
    final currentRow = <String>[];
    final currentValue = StringBuffer();
    var inQuotes = false;

    for (var index = 0; index < content.length; index++) {
      final char = content[index];
      final next = index + 1 < content.length ? content[index + 1] : '';

      if (char == '"') {
        if (inQuotes && next == '"') {
          currentValue.write('"');
          index++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }

      if (!inQuotes && (char == ',' || char == ';')) {
        currentRow.add(currentValue.toString());
        currentValue.clear();
        continue;
      }

      if (!inQuotes && (char == '\n' || char == '\r')) {
        if (char == '\r' && next == '\n') index++;
        currentRow.add(currentValue.toString());
        currentValue.clear();
        rows.add(List<String>.from(currentRow));
        currentRow.clear();
        continue;
      }

      currentValue.write(char);
    }

    if (currentValue.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentValue.toString());
      rows.add(currentRow);
    }

    return rows;
  }

  DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso;

    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(trimmed);
    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  AnimalStatus? _parseStatus(String value) {
    final normalized = _normalizeHeader(value);
    if (normalized.isEmpty) return AnimalStatus.active;

    return switch (normalized) {
      'ativo' || 'atvo' => AnimalStatus.active,
      'vendido' => AnimalStatus.sold,
      'obito' || 'óbito' => AnimalStatus.death,
      'inativo' || 'arquivado' => AnimalStatus.inactive,
      _ => null,
    };
  }

  PropertySummaryModel? _findProperty(
    List<PropertySummaryModel> properties,
    String value,
  ) {
    final normalized = _normalizeHeader(value);
    if (normalized.isEmpty) return null;

    for (final property in properties) {
      if (_normalizeHeader(property.nome) == normalized ||
          _normalizeHeader(property.idExterno) == normalized ||
          property.id.toString() == value.trim()) {
        return property;
      }
    }

    return null;
  }

  String _normalizeHeader(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static const _requiredColumns = {
    'codigo',
    'categoria',
    'sexo',
    'dataNascimento',
    'status',
    'propriedade',
  };

  static const _columnAliases = {
    'codigo': 'codigo',
    'brinco': 'codigo',
    'id': 'codigo',
    'categoria': 'categoria',
    'especie': 'categoria',
    'sexo': 'sexo',
    'datanascimento': 'dataNascimento',
    'nascimento': 'dataNascimento',
    'status': 'status',
    'propriedade': 'propriedade',
    'fazenda': 'propriedade',
  };
}
