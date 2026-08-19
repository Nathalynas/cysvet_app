import '../../../core/constants/app_constants.dart';
import '../../../core/enums/animal_status.dart';
import '../../properties/domain/property_summary_model.dart';

enum AnimalImportFieldType {
  text,
  integer,
  date,
  property,
  reproductiveStatus,
}

enum AnimalImportFieldKey {
  codigo,
  categoria,
  dataNascimento,
  idPropriedade,
  statusReprodutivo,
  numeroLactacao,
  dataUltimoParto,
  dataInseminacao,
  historicoReprodutivo,
}

class AnimalImportFieldSpec {
  const AnimalImportFieldSpec({
    required this.key,
    required this.label,
    required this.type,
    required this.required,
    required this.aliases,
  });

  final AnimalImportFieldKey key;
  final String label;
  final AnimalImportFieldType type;
  final bool required;
  final List<String> aliases;
}

const animalImportFields = <AnimalImportFieldSpec>[
  AnimalImportFieldSpec(
    key: AnimalImportFieldKey.codigo,
    label: 'Brinco/ID',
    type: AnimalImportFieldType.text,
    required: true,
    aliases: [
      'brinco',
      'id',
      'codigo',
      'cod animal',
      'animal',
      'matriz',
      'matriz n',
      'matriz numero',
      'numero',
      'n animal',
    ],
  ),
  AnimalImportFieldSpec(
    key: AnimalImportFieldKey.categoria,
    label: 'Espécie',
    type: AnimalImportFieldType.text,
    required: true,
    aliases: [
      'especie',
      'categoria',
      'categoria zootecnica',
      'vaca novilha',
      'tipo',
    ],
  ),
  AnimalImportFieldSpec(
    key: AnimalImportFieldKey.dataNascimento,
    label: 'Data de nascimento',
    type: AnimalImportFieldType.date,
    required: true,
    aliases: [
      'data de nascimento',
      'data nascimento',
      'data nasci',
      'nascimento',
      'dt nascimento',
      'data nasc',
    ],
  ),
  AnimalImportFieldSpec(
    key: AnimalImportFieldKey.idPropriedade,
    label: 'Propriedade vinculada',
    type: AnimalImportFieldType.property,
    required: true,
    aliases: [
      'propriedade',
      'fazenda',
      'farm',
      'id propriedade',
      'propriedade vinculada',
    ],
  ),
  AnimalImportFieldSpec(
    key: AnimalImportFieldKey.statusReprodutivo,
    label: 'Status reprodutivo',
    type: AnimalImportFieldType.reproductiveStatus,
    required: true,
    aliases: [
      'status reprodutivo',
      'situacao reprodutiva',
      'situacao produtiva',
      'diagnostico',
      'diagnostico 1',
      'diagnostco 1',
      'resultado',
      'repr',
    ],
  ),
  AnimalImportFieldSpec(
    key: AnimalImportFieldKey.numeroLactacao,
    label: 'Número de lactação',
    type: AnimalImportFieldType.integer,
    required: true,
    aliases: [
      'numero de lactacao',
      'n lactacao',
      'lactacao',
      'numero lactacao',
      'numero de partos',
      'n de partos',
      'partos',
      'del',
    ],
  ),
  AnimalImportFieldSpec(
    key: AnimalImportFieldKey.dataUltimoParto,
    label: 'Data do parto',
    type: AnimalImportFieldType.date,
    required: false,
    aliases: [
      'data do parto',
      'data ultimo parto',
      'ultimo parto',
      'data up',
      'up',
      'parto anterior',
    ],
  ),
  AnimalImportFieldSpec(
    key: AnimalImportFieldKey.dataInseminacao,
    label: 'Data da inseminação',
    type: AnimalImportFieldType.date,
    required: false,
    aliases: [
      'data da inseminacao',
      'data inseminacao',
      'data ia',
      'data ia ultima',
      'ultima ia',
      'inseminacao',
    ],
  ),
  AnimalImportFieldSpec(
    key: AnimalImportFieldKey.historicoReprodutivo,
    label: 'Histórico',
    type: AnimalImportFieldType.text,
    required: false,
    aliases: [
      'historico',
      'historico reprodutivo',
      'observacao',
      'observacoes',
      'obs',
      'motivo',
    ],
  ),
];

extension AnimalImportFieldKeySpec on AnimalImportFieldKey {
  AnimalImportFieldSpec get spec {
    return animalImportFields.firstWhere((field) => field.key == this);
  }
}

List<AnimalImportFieldSpec> get requiredAnimalImportFields {
  return animalImportFields.where((field) => field.required).toList();
}

AnimalImportFieldSpec? animalImportFieldForHeader(String header) {
  final normalized = normalizeAnimalImportToken(header);
  if (normalized.isEmpty) return null;

  for (final field in animalImportFields) {
    final label = normalizeAnimalImportToken(field.label);
    if (normalized == label) return field;

    for (final alias in field.aliases) {
      final normalizedAlias = normalizeAnimalImportToken(alias);
      if (normalized == normalizedAlias) return field;
    }
  }

  for (final field in animalImportFields) {
    final specificAliases = field.aliases.where((alias) {
      return normalizeAnimalImportToken(alias).length >= 6;
    });

    for (final alias in specificAliases) {
      final normalizedAlias = normalizeAnimalImportToken(alias);
      if (normalized.contains(normalizedAlias)) return field;
    }
  }

  return null;
}

String normalizeAnimalImportToken(String value) {
  return value
      .trim()
      .normalize()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

AnimalReproductiveStatus? parseAnimalImportReproductiveStatus(String value) {
  final normalized = normalizeAnimalImportToken(value);
  if (normalized.isEmpty) return null;

  for (final status in AnimalReproductiveStatus.editableValues) {
    final candidates = [
      status.apiValue,
      status.label,
      ...status.aliases,
    ].map(normalizeAnimalImportToken);

    if (candidates.contains(normalized)) {
      return status;
    }
  }

  return null;
}

PropertySummaryModel? findAnimalImportProperty(
  List<PropertySummaryModel> properties,
  String value,
) {
  final normalized = normalizeAnimalImportToken(value);
  if (normalized.isEmpty) return null;

  for (final property in properties) {
    if (property.id.toString() == value.trim() ||
        normalizeAnimalImportToken(property.nome) == normalized ||
        normalizeAnimalImportToken(property.idExterno) == normalized) {
      return property;
    }
  }

  return null;
}
