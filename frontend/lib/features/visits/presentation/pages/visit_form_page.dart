import 'package:cysvet_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/enums/animal_status.dart';
import '../../../../core/presentation/app_scaffold_messenger.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../animals/data/animals_repository.dart';
import '../../../animals/domain/animal_summary_model.dart';
import '../../../properties/application/properties_provider.dart';
import '../../../properties/domain/property_summary_model.dart';
import '../../data/visits_repository.dart';
import '../../application/visits_provider.dart';
import '../../domain/visit_summary_model.dart';

int? diasEntre(DateTime? dataInicial, DateTime? dataFinal) {
  if (dataInicial == null || dataFinal == null) {
    return null;
  }

  final start = DateUtils.dateOnly(dataInicial);
  final end = DateUtils.dateOnly(dataFinal);
  return end.difference(start).inDays;
}

DateTime? adicionarDias(DateTime? data, int? dias) {
  if (data == null || dias == null) {
    return null;
  }

  return DateUtils.dateOnly(data).add(Duration(days: dias));
}

String? nomeDoMes(DateTime? data) {
  if (data == null || data.month < 1 || data.month > 12) {
    return null;
  }

  const months = [
    'janeiro',
    'fevereiro',
    'marco',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  return months[data.month - 1];
}

double? media(Iterable<num?> lista) {
  final validValues = lista
      .whereType<num>()
      .where((value) => value.isFinite)
      .map((value) => value.toDouble())
      .toList(growable: false);
  if (validValues.isEmpty) {
    return null;
  }

  final total = validValues.fold<double>(0, (sum, value) => sum + value);
  final result = total / validValues.length;
  return result.isFinite ? result : null;
}

List<DateTime> _iaDatesFromEntry(VisitAnimalEntryModel entry) {
  final dates = <DateTime>[
    if (entry.dataPrimeiraIa != null) DateUtils.dateOnly(entry.dataPrimeiraIa!),
    if (entry.dataSegundaIa != null) DateUtils.dateOnly(entry.dataSegundaIa!),
    if (entry.dataTerceiraIa != null) DateUtils.dateOnly(entry.dataTerceiraIa!),
    if (entry.dataQuartaIa != null) DateUtils.dateOnly(entry.dataQuartaIa!),
    if (entry.dataQuintaIa != null) DateUtils.dateOnly(entry.dataQuintaIa!),
    if (entry.dataUltimaIa != null) DateUtils.dateOnly(entry.dataUltimaIa!),
  ];

  dates.sort();
  return dates;
}

class _AnimalIaHistory {
  const _AnimalIaHistory({required this.dates, required this.totalIas});

  factory _AnimalIaHistory.fromDatesAndCount({
    required Iterable<DateTime> dates,
    required int totalIas,
  }) {
    final uniqueDates = <DateTime>[];
    final seen = <String>{};

    for (final rawDate in dates) {
      final date = DateUtils.dateOnly(rawDate);
      final key = '${date.year}-${date.month}-${date.day}';
      if (seen.add(key)) {
        uniqueDates.add(date);
      }
    }

    uniqueDates.sort();
    final resolvedTotal = totalIas > uniqueDates.length
        ? totalIas
        : uniqueDates.length;

    return _AnimalIaHistory(
      dates: List.unmodifiable(uniqueDates),
      totalIas: resolvedTotal,
    );
  }

  static const empty = _AnimalIaHistory(dates: [], totalIas: 0);

  final List<DateTime> dates;
  final int totalIas;

  DateTime? get lastDate => dates.isEmpty ? null : dates.last;

  DateTime? get firstDate => dates.isEmpty ? null : dates.first;

  int get suggestedNextNumber => totalIas + 1;
}

String _animalIdentifier(VisitAnimalEntryModel entry) {
  final code = entry.animalCodigo.trim();
  if (code.isNotEmpty) {
    return code;
  }

  if (entry.animalId != 0) {
    return 'Animal ${entry.animalId}';
  }

  return 'Animal sem identificação';
}

bool _hasVisitIa(VisitAnimalEntryModel entry, _AnimalIaHistory iaHistory) {
  final number = entry.numeroIaRecebida;
  return entry.dataUltimaIa != null &&
      number != null &&
      number > iaHistory.totalIas;
}

VisitAnimalEntryModel _entryWithVisitIaDate({
  required VisitAnimalEntryModel entry,
  required _AnimalIaHistory iaHistory,
  required DateTime? value,
}) {
  if (value == null) {
    return _entryWithHistoricalIas(entry: entry, iaHistory: iaHistory);
  }

  final currentNumber = entry.numeroIaRecebida;
  final visitIaNumber =
      currentNumber != null && currentNumber > iaHistory.totalIas
      ? currentNumber
      : iaHistory.suggestedNextNumber;
  final visitIaDate = DateUtils.dateOnly(value);

  return _entryWithIaDates(
    entry: entry.copyWith(
      dataUltimaIa: visitIaDate,
      numeroIaRecebida: visitIaNumber,
    ),
    dates: [...iaHistory.dates, visitIaDate],
  );
}

VisitAnimalEntryModel _entryWithVisitIaNumber({
  required VisitAnimalEntryModel entry,
  required _AnimalIaHistory iaHistory,
  required String value,
}) {
  if (!_hasVisitIa(entry, iaHistory)) {
    return entry;
  }

  final parsed = int.tryParse(value.trim());
  if (parsed == null || parsed <= iaHistory.totalIas) {
    return entry;
  }

  return entry.copyWith(numeroIaRecebida: parsed);
}

VisitAnimalEntryModel _entryWithHistoricalIas({
  required VisitAnimalEntryModel entry,
  required _AnimalIaHistory iaHistory,
}) {
  return _entryWithIaDates(
    entry: entry.copyWith(
      dataUltimaIa: iaHistory.lastDate,
      numeroIaRecebida: iaHistory.totalIas == 0 ? null : iaHistory.totalIas,
    ),
    dates: iaHistory.dates,
  );
}

VisitAnimalEntryModel _entryWithIaDates({
  required VisitAnimalEntryModel entry,
  required Iterable<DateTime> dates,
}) {
  final sortedDates = _AnimalIaHistory.fromDatesAndCount(
    dates: dates,
    totalIas: 0,
  ).dates;

  return entry.copyWith(
    dataPrimeiraIa: sortedDates.isNotEmpty ? sortedDates[0] : null,
    dataSegundaIa: sortedDates.length > 1 ? sortedDates[1] : null,
    dataTerceiraIa: sortedDates.length > 2 ? sortedDates[2] : null,
    dataQuartaIa: sortedDates.length > 3 ? sortedDates[3] : null,
    dataQuintaIa: sortedDates.length > 4 ? sortedDates[4] : null,
  );
}

typedef _VisitEntryCalculator =
    VisitAnimalEntryModel Function(VisitAnimalEntryModel entry);

class VisitFormPage extends ConsumerStatefulWidget {
  const VisitFormPage({super.key, this.initialPropertyId});

  final int? initialPropertyId;

  @override
  ConsumerState<VisitFormPage> createState() => _VisitFormPageState();
}

class _VisitFormPageState extends ConsumerState<VisitFormPage> {
  static const _situacaoProdutivaOptions = [
    AppDropdownOption<String>(label: 'Nao informado', value: null),
    AppDropdownOption<String>(
      label: 'Lactante',
      value: AnimalProductiveSituation.lactating,
    ),
    AppDropdownOption<String>(
      label: 'Seca',
      value: AnimalProductiveSituation.dry,
    ),
    AppDropdownOption<String>(
      label: 'Novilha',
      value: AnimalProductiveSituation.heifer,
    ),
    AppDropdownOption<String>(
      label: 'Pré-parto',
      value: AnimalProductiveSituation.prepartum,
    ),
    AppDropdownOption<String>(
      label: 'Bezerra',
      value: AnimalProductiveSituation.calf,
    ),
  ];

  static const _situacaoReprodutivaOptions = [
    AppDropdownOption<String>(label: 'Não informado', value: null),
    AppDropdownOption<String>(label: 'Em protocolo', value: 'em protocolo'),
    AppDropdownOption<String>(label: 'Vazia', value: 'vazia'),
    AppDropdownOption<String>(label: 'Liberada', value: 'liberada'),
    AppDropdownOption<String>(label: 'Atrasada', value: 'atrasada'),
    AppDropdownOption<String>(label: 'Aguardando DG', value: 'aguardando dg'),
    AppDropdownOption<String>(label: 'Inseminada ST', value: 'inseminada st'),
    AppDropdownOption<String>(label: 'Prenha', value: 'prenha'),
    AppDropdownOption<String>(label: 'Indução', value: 'inducao'),
    AppDropdownOption<String>(label: 'Descarte', value: 'descarte'),
    AppDropdownOption<String>(label: 'PEV', value: 'pev'),
    AppDropdownOption<String>(label: 'Sem idade', value: 'sem idade'),
    AppDropdownOption<String>(label: 'Bezerra', value: 'bezerra'),
    AppDropdownOption<String>(label: 'Inseminada', value: 'inseminada'),
    AppDropdownOption<String>(label: 'Seca', value: 'seca'),
    AppDropdownOption<String>(label: 'Pendente', value: 'pending'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _dataVisita = TextEditingController();

  int? _propertyId;
  int? _loadedPropertyId;
  int? _selectedAnimalId;
  bool _isLoadingAnimals = false;
  String? _animalsError;
  List<VisitAnimalEntryModel> _animalEntries = const [];
  Map<int, _AnimalIaHistory> _iaHistoryByAnimalId = const {};
  Set<int> _reviewedAnimalIds = const {};

  @override
  void initState() {
    super.initState();
    _dataVisita.text = formatDateInput(DateTime.now());
    _propertyId = widget.initialPropertyId;
    if (_propertyId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadAnimalsForSelectedProperty();
        }
      });
    }
  }

  @override
  void dispose() {
    _dataVisita.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(propertiesProvider);
    final isBusy = ref.watch(visitsBusyProvider);

    return properties.when(
      data: (items) => _buildContent(context, items, isBusy),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Falha ao carregar propriedades.'),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<PropertySummaryModel> properties,
    bool isBusy,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedProperty = _selectedProperty(properties);
    final selectedEntry = _selectedEntry;
    final collectedCount = _reviewedAnimalIds.length;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Nova visita',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Vincule a propriedade, selecione o animal e preencha os dados da visita.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _HeaderFields(
                        propertyId: _propertyId,
                        properties: properties,
                        dataVisitaController: _dataVisita,
                        onVisitDateChanged: (_) => _recalculateAnimalEntries(),
                        onPropertyChanged: (value) {
                          setState(() {
                            if (_propertyId != value) {
                              _propertyId = value;
                              _resetAnimalCollection();
                            }
                          });
                          _loadAnimalsForSelectedProperty();
                        },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SummaryChip(
                            icon: Icons.agriculture_outlined,
                            label: selectedProperty?.nome ?? 'Sem propriedade',
                          ),
                          _SummaryChip(
                            icon: MdiIcons.cow,
                            label: '${_animalEntries.length} animais',
                          ),
                          _SummaryChip(
                            icon: Icons.fact_check_outlined,
                            label: '$collectedCount com coleta',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoadingAnimals)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_animalsError != null)
                  _FeedbackPanel(message: _animalsError!, error: true)
                else if (_propertyId == null)
                  const _FeedbackPanel(
                    message:
                        'Selecione a propriedade para carregar a lista de animais.',
                  )
                else if (_animalEntries.isEmpty)
                  const _FeedbackPanel(
                    message:
                        'Nenhum animal encontrado para a propriedade selecionada.',
                  )
                else
                  _AnimalCollectionLayout(
                    entries: _animalEntries,
                    iaHistoryByAnimalId: _iaHistoryByAnimalId,
                    reviewedAnimalIds: _reviewedAnimalIds,
                    selectedAnimalId: _selectedAnimalId,
                    selectedEntry: selectedEntry,
                    onSelectAnimal: (animalId) {
                      setState(() {
                        _selectedAnimalId = animalId;
                      });
                    },
                    onChanged: _updateAnimalEntry,
                    applyAutomaticCalculations: _applyAutomaticCalculations,
                    onConfirmAnimal: _confirmAnimal,
                    onOpenAnimal: _editAnimalInModal,
                  ),
              ],
            ),
          ),
          _VisitActionsBar(
            isBusy: isBusy,
            isLoadingAnimals: _isLoadingAnimals,
            onCancel: () => context.go('/visitas'),
            onSave: _saveVisit,
          ),
        ],
      ),
    );
  }

  VisitAnimalEntryModel? get _selectedEntry {
    if (_selectedAnimalId == null) {
      return _animalEntries.isEmpty ? null : _animalEntries.first;
    }

    for (final entry in _animalEntries) {
      if (entry.animalId == _selectedAnimalId) {
        return entry;
      }
    }

    return _animalEntries.isEmpty ? null : _animalEntries.first;
  }

  Future<void> _loadAnimalsForSelectedProperty() async {
    final propertyId = _propertyId;
    if (propertyId == null) {
      return;
    }

    if (_loadedPropertyId == propertyId && _animalsError == null) {
      return;
    }

    setState(() {
      _isLoadingAnimals = true;
      _animalsError = null;
    });

    try {
      final animals = await ref
          .read(animalsRepositoryProvider)
          .list(propertyId: propertyId);
      final previousVisits = await _loadPreviousVisitsForProperty(propertyId);
      if (!mounted) {
        return;
      }

      final iaHistoryByAnimalId = _buildIaHistoryByAnimalId(
        animals: animals,
        visits: previousVisits,
      );
      final entries = animals
          .map((animal) => _entryFromAnimal(animal, iaHistoryByAnimalId))
          .toList(growable: false);
      setState(() {
        _loadedPropertyId = propertyId;
        _animalEntries = entries;
        _iaHistoryByAnimalId = iaHistoryByAnimalId;
        _selectedAnimalId = entries.isEmpty ? null : entries.first.animalId;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _animalsError = 'Falha ao carregar os animais da propriedade.';
      });
      showAppError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAnimals = false;
        });
      }
    }
  }

  Future<List<VisitSummaryModel>> _loadPreviousVisitsForProperty(
    int propertyId,
  ) async {
    final localVisits = ref
        .read(localVisitsProvider)
        .values
        .where((visit) => visit.idPropriedade == propertyId)
        .toList(growable: false);

    try {
      final remoteVisits = await ref
          .read(visitsRepositoryProvider)
          .list(propertyId: propertyId);
      return {
        for (final visit in remoteVisits) visit.id: visit,
        for (final visit in localVisits) visit.id: visit,
      }.values.toList(growable: false);
    } catch (error) {
      return localVisits;
    }
  }

  Map<int, _AnimalIaHistory> _buildIaHistoryByAnimalId({
    required List<AnimalSummaryModel> animals,
    required List<VisitSummaryModel> visits,
  }) {
    final result = <int, _AnimalIaHistory>{};

    for (final animal in animals) {
      final dates = <DateTime>[
        if (animal.dataInseminacao != null)
          DateUtils.dateOnly(animal.dataInseminacao!),
      ];
      var totalIas = dates.isEmpty ? 0 : 1;

      for (final visit in visits) {
        for (final entry in visit.animais) {
          if (!_visitEntryBelongsToAnimal(entry, animal)) {
            continue;
          }

          dates.addAll(_iaDatesFromEntry(entry));
          final entryIaCount = entry.numeroIaRecebida;
          if (entryIaCount != null && entryIaCount > totalIas) {
            totalIas = entryIaCount;
          }
        }
      }

      final history = _AnimalIaHistory.fromDatesAndCount(
        dates: dates,
        totalIas: totalIas,
      );
      result[animal.id] = history;
    }

    return result;
  }

  bool _visitEntryBelongsToAnimal(
    VisitAnimalEntryModel entry,
    AnimalSummaryModel animal,
  ) {
    if (animal.id > 0 && entry.animalId == animal.id) {
      return true;
    }

    final externalId = animal.idExterno.trim();
    if (externalId.isNotEmpty && entry.animalIdExterno.trim() == externalId) {
      return true;
    }

    final code = animal.codigo.trim();
    return code.isNotEmpty && entry.animalCodigo.trim() == code;
  }

  Future<void> _saveVisit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    try {
      final properties = ref.read(propertiesProvider).asData?.value ?? const [];
      final property = _selectedProperty(properties);
      final payload = VisitSummaryModel(
        idExterno: const Uuid().v4(),
        idPropriedade: _propertyId ?? 0,
        idExternoPropriedade: property?.idExterno ?? '',
        dataVisita: parseDateInput(_dataVisita.text),
        animais: _animalEntries
            .where((item) => _reviewedAnimalIds.contains(item.animalId))
            .toList(growable: false),
      );

      await ref.read(visitsControllerProvider).save(payload);
      if (mounted) {
        showAppSuccess('Visita salva com sucesso.');
        context.go('/visitas');
      }
    } catch (error) {
      showAppError(error);
    }
  }

  void _resetAnimalCollection() {
    _loadedPropertyId = null;
    _selectedAnimalId = null;
    _animalsError = null;
    _animalEntries = const [];
    _iaHistoryByAnimalId = const {};
    _reviewedAnimalIds = const {};
  }

  void _updateAnimalEntry(VisitAnimalEntryModel updated) {
    final calculated = _applyAutomaticCalculations(updated);
    setState(() {
      _animalEntries = _animalEntries
          .map((entry) {
            if (entry.animalId == calculated.animalId) {
              return calculated;
            }
            return entry;
          })
          .toList(growable: false);
    });
  }

  void _confirmAnimal(int animalId) {
    setState(() {
      _reviewedAnimalIds = {..._reviewedAnimalIds, animalId};
    });
  }

  Future<void> _editAnimalInModal(VisitAnimalEntryModel entry) async {
    final updated = await AppDialog.show<VisitAnimalEntryModel>(
      context: context,
      title: entry.animalCodigo.isEmpty
          ? 'Animal'
          : 'Brinco ${entry.animalCodigo}',
      width: 760,
      useInternalScroll: true,
      fullscreenOnMobile: true,
      content: _AnimalEditorModalContent(
        entry: entry,
        iaHistory:
            _iaHistoryByAnimalId[entry.animalId] ?? _AnimalIaHistory.empty,
        applyAutomaticCalculations: _applyAutomaticCalculations,
      ),
    );

    if (!mounted || updated == null) {
      return;
    }

    _updateAnimalEntry(updated);
    _confirmAnimal(updated.animalId);
  }

  PropertySummaryModel? _selectedProperty(
    List<PropertySummaryModel> properties,
  ) {
    final propertyId = _propertyId;
    if (propertyId == null) {
      return null;
    }

    for (final property in properties) {
      if (property.id == propertyId) {
        return property;
      }
    }

    return null;
  }

  VisitAnimalEntryModel _entryFromAnimal(
    AnimalSummaryModel animal,
    Map<int, _AnimalIaHistory> iaHistoryByAnimalId,
  ) {
    final reproductiveStatus = _visitReproductiveStatus(animal);
    final iaHistory = iaHistoryByAnimalId[animal.id] ?? _AnimalIaHistory.empty;
    final iaDates = iaHistory.dates;

    final entry = VisitAnimalEntryModel(
      animalId: animal.id,
      animalIdExterno: animal.idExterno,
      animalCodigo: animal.codigo,
      animalCategoria: animal.categoria,
      dataNascimento: animal.dataNascimento,
      dataUltimoParto: animal.dataUltimoParto,
      numeroPartos: animal.numeroLactacao > 0 ? animal.numeroLactacao : null,
      situacaoProdutiva: _visitProductiveStatus(animal),
      situacaoReprodutiva: reproductiveStatus,
      dataUltimaIa: iaHistory.lastDate,
      dataPrimeiraIa: iaDates.isEmpty ? null : iaDates[0],
      dataSegundaIa: iaDates.length > 1 ? iaDates[1] : null,
      dataTerceiraIa: iaDates.length > 2 ? iaDates[2] : null,
      dataQuartaIa: iaDates.length > 3 ? iaDates[3] : null,
      dataQuintaIa: iaDates.length > 4 ? iaDates[4] : null,
      numeroIaRecebida: iaHistory.totalIas == 0 ? null : iaHistory.totalIas,
      diagnostico: animal.historicoReprodutivo?.trim().isEmpty == true
          ? null
          : animal.historicoReprodutivo?.trim(),
    );

    return _applyAutomaticCalculations(entry);
  }

  String? _visitProductiveStatus(AnimalSummaryModel animal) {
    final category = animal.categoria.normalize();

    if (category.contains('novilha')) {
      return AnimalProductiveSituation.heifer;
    }

    if (_resolvedReproductiveStatus(animal) == AnimalReproductiveStatus.dry) {
      return AnimalProductiveSituation.dry;
    }

    if (animal.numeroLactacao > 0 || animal.diasEmLactacao != null) {
      return AnimalProductiveSituation.lactating;
    }

    return null;
  }

  String? _visitReproductiveStatus(AnimalSummaryModel animal) {
    final resolved = _resolvedReproductiveStatus(animal);

    if (resolved == AnimalReproductiveStatus.dry) {
      return null;
    }
    if (resolved != AnimalReproductiveStatus.pending) {
      return resolved.apiValue;
    }

    final history = (animal.historicoReprodutivo ?? '').normalize();
    if (history.contains('em protocolo') || history.contains('protocolo')) {
      return AnimalReproductiveStatus.protocol.apiValue;
    }
    if (history.contains('aguardando dg')) {
      return AnimalReproductiveStatus.waitingDiagnosis.apiValue;
    }
    if (history.contains('inseminada st') || history.contains('ia st')) {
      return AnimalReproductiveStatus.inseminatedSt.apiValue;
    }
    if (history.contains('pev')) {
      return AnimalReproductiveStatus.pev.apiValue;
    }
    if (history.contains('liberad')) {
      return AnimalReproductiveStatus.released.apiValue;
    }
    if (history.contains('atrasad')) {
      return AnimalReproductiveStatus.delayed.apiValue;
    }
    if (history.contains('inducao') || history.contains('induz')) {
      return AnimalReproductiveStatus.induction.apiValue;
    }
    if (history.contains('descarte')) {
      return AnimalReproductiveStatus.discard.apiValue;
    }
    if (history.contains('sem idade')) {
      return AnimalReproductiveStatus.noAge.apiValue;
    }
    if (history.contains('bezerra')) {
      return AnimalReproductiveStatus.calf.apiValue;
    }
    return null;
  }

  AnimalReproductiveStatus _resolvedReproductiveStatus(
    AnimalSummaryModel animal,
  ) {
    final savedStatus = animal.statusReprodutivo;
    if (savedStatus != null) {
      return savedStatus;
    }

    if (animal.dataInseminacao != null) {
      return AnimalReproductiveStatus.inseminated;
    }

    final history = (animal.historicoReprodutivo ?? '').normalize();

    if (history.contains('em protocolo') || history.contains('protocolo')) {
      return AnimalReproductiveStatus.protocol;
    }
    if (history.contains('aguardando dg')) {
      return AnimalReproductiveStatus.waitingDiagnosis;
    }
    if (history.contains('inseminada st') || history.contains('ia st')) {
      return AnimalReproductiveStatus.inseminatedSt;
    }
    if (history.contains('pren') || history.contains('confirm')) {
      return AnimalReproductiveStatus.pregnant;
    }
    if (history.contains('insemin')) {
      return AnimalReproductiveStatus.inseminated;
    }
    if (history.contains('seca') || history.contains('dry')) {
      return AnimalReproductiveStatus.dry;
    }
    if (history.contains('liberad')) {
      return AnimalReproductiveStatus.released;
    }
    if (history.contains('atrasad')) {
      return AnimalReproductiveStatus.delayed;
    }
    if (history.contains('inducao') || history.contains('induz')) {
      return AnimalReproductiveStatus.induction;
    }
    if (history.contains('descarte')) {
      return AnimalReproductiveStatus.discard;
    }
    if (history.contains('pev')) {
      return AnimalReproductiveStatus.pev;
    }
    if (history.contains('sem idade')) {
      return AnimalReproductiveStatus.noAge;
    }
    if (history.contains('bezerra')) {
      return AnimalReproductiveStatus.calf;
    }
    if (history.contains('vazia') ||
        history.contains('empty') ||
        history.contains('negativ') ||
        history.contains('toque')) {
      return AnimalReproductiveStatus.empty;
    }

    return AnimalReproductiveStatus.pending;
  }

  void _recalculateAnimalEntries() {
    if (_animalEntries.isEmpty) {
      return;
    }

    setState(() {
      _animalEntries = _animalEntries
          .map(_applyAutomaticCalculations)
          .toList(growable: false);
    });
  }

  VisitAnimalEntryModel _applyAutomaticCalculations(
    VisitAnimalEntryModel entry,
  ) {
    return _VisitAnimalAutomaticCalculator.calculate(
      entry: entry,
      dataAtual: parseDateInput(_dataVisita.text),
    );
  }
}

class _VisitAnimalAutomaticCalculator {
  const _VisitAnimalAutomaticCalculator._();

  static VisitAnimalEntryModel calculate({
    required VisitAnimalEntryModel entry,
    required DateTime? dataAtual,
  }) {
    final situacaoProdutiva = _normalize(entry.situacaoProdutiva);
    final situacaoReprodutiva = _normalize(entry.situacaoReprodutiva);
    final intervalo1e2Ia = diasEntre(entry.dataPrimeiraIa, entry.dataSegundaIa);
    final intervalo2e3Ia = diasEntre(entry.dataSegundaIa, entry.dataTerceiraIa);
    final intervalo3e4Ia = diasEntre(entry.dataTerceiraIa, entry.dataQuartaIa);
    final intervalo4e5Ia = diasEntre(entry.dataQuartaIa, entry.dataQuintaIa);
    final diasPrenhez = _diasPrenhez(
      situacaoProdutiva: situacaoProdutiva,
      situacaoReprodutiva: situacaoReprodutiva,
      dataUltimaIa: entry.dataUltimaIa,
      dataAtual: dataAtual,
    );
    final previsaoSecagem = _previsaoSecagem(
      situacaoProdutiva: situacaoProdutiva,
      situacaoReprodutiva: situacaoReprodutiva,
      dataUltimaIa: entry.dataUltimaIa,
    );
    final dataPreParto = _dataPreParto(
      situacaoReprodutiva: situacaoReprodutiva,
      dataUltimaIa: entry.dataUltimaIa,
    );
    final previsaoParto = _previsaoParto(
      situacaoReprodutiva: situacaoReprodutiva,
      dataUltimaIa: entry.dataUltimaIa,
    );

    return entry.copyWith(
      idadeMeses: _monthsBetween(entry.dataNascimento, dataAtual),
      del: _del(
        situacaoProdutiva: situacaoProdutiva,
        dataUltimoParto: entry.dataUltimoParto,
        dataAtual: dataAtual,
      ),
      idadePrimeiroPartoMeses: _monthsBetween(
        entry.dataNascimento,
        entry.dataPrimeiroParto,
      ),
      idadePrimeiraIa: _idadePrimeiraIa(
        situacaoProdutiva: situacaoProdutiva,
        dataNascimento: entry.dataNascimento,
        dataPrimeiraIa: entry.dataPrimeiraIa,
      ),
      mesParto: _mesParto(entry.numeroPartos, entry.dataUltimoParto),
      anoUltimoParto: entry.dataUltimoParto?.year,
      iepAtual: _iepAtual(
        numeroPartos: entry.numeroPartos,
        dataPartoAnterior: entry.dataPartoAnterior,
        dataUltimoParto: entry.dataUltimoParto,
      ),
      classificacaoPartos: _classificacaoPartos(entry.numeroPartos),
      vacaApta: _vacaApta(situacaoReprodutiva),
      intervalo1e2Ia: intervalo1e2Ia,
      intervalo2e3Ia: intervalo2e3Ia,
      intervalo3e4Ia: intervalo3e4Ia,
      intervalo4e5Ia: intervalo4e5Ia,
      mediaIntervaloIa: _mediaIntervaloIa(
        numeroIaRecebida: entry.numeroIaRecebida,
        situacaoReprodutiva: situacaoReprodutiva,
        intervalos: [
          intervalo1e2Ia,
          intervalo2e3Ia,
          intervalo3e4Ia,
          intervalo4e5Ia,
        ],
      ),
      previsaoRetornoCio: _previsaoRetornoCio(
        situacaoReprodutiva: situacaoReprodutiva,
        dataUltimaIa: entry.dataUltimaIa,
      ),
      diasPrenhez: diasPrenhez,
      delPrimeiraIa: _delPrimeiraIa(
        situacaoProdutiva: situacaoProdutiva,
        situacaoReprodutiva: situacaoReprodutiva,
        dataUltimoParto: entry.dataUltimoParto,
        dataPrimeiraIa: entry.dataPrimeiraIa,
      ),
      periodoServico: _periodoServico(
        situacaoProdutiva: situacaoProdutiva,
        situacaoReprodutiva: situacaoReprodutiva,
        dataUltimoParto: entry.dataUltimoParto,
        dataUltimaIa: entry.dataUltimaIa,
        diasPrenhez: diasPrenhez,
      ),
      diasParaSecar: _diasParaSecar(
        situacaoProdutiva: situacaoProdutiva,
        situacaoReprodutiva: situacaoReprodutiva,
        diasPrenhez: diasPrenhez,
      ),
      previsaoSecagem: previsaoSecagem,
      mesSecagem: _mesSecagem(
        situacaoReprodutiva: situacaoReprodutiva,
        previsaoSecagem: previsaoSecagem,
      ),
      diferencaSecagem: diasEntre(previsaoSecagem, entry.dataSecagemEfetiva),
      periodoLactacao: _periodoLactacao(
        situacaoProdutiva: situacaoProdutiva,
        dataSecagemEfetiva: entry.dataSecagemEfetiva,
        dataUltimoParto: entry.dataUltimoParto,
      ),
      dataPreParto: dataPreParto,
      mesPreParto: _mesPreParto(
        situacaoReprodutiva: situacaoReprodutiva,
        dataPreParto: dataPreParto,
      ),
      duracaoPreParto: _duracaoPreParto(
        situacaoProdutiva: situacaoProdutiva,
        entradaPreParto: entry.entradaPreParto,
        dataUltimoParto: entry.dataUltimoParto,
      ),
      previsaoParto: previsaoParto,
      mesPrevistoParto: _mesPrevistoParto(
        situacaoReprodutiva: situacaoReprodutiva,
        previsaoParto: previsaoParto,
      ),
      iepProjetado: _iepProjetado(
        situacaoProdutiva: situacaoProdutiva,
        situacaoReprodutiva: situacaoReprodutiva,
        previsaoParto: previsaoParto,
        dataUltimoParto: entry.dataUltimoParto,
      ),
      controleLeiteiroComDesconto: _controleLeiteiroComDesconto(
        situacaoProdutiva: situacaoProdutiva,
        controleLeiteiro: entry.controleLeiteiro,
      ),
    );
  }

  static int? _del({
    required String? situacaoProdutiva,
    required DateTime? dataUltimoParto,
    required DateTime? dataAtual,
  }) {
    if (situacaoProdutiva != AnimalProductiveSituation.lactating) {
      return null;
    }

    return diasEntre(dataUltimoParto, dataAtual);
  }

  static double? _idadePrimeiraIa({
    required String? situacaoProdutiva,
    required DateTime? dataNascimento,
    required DateTime? dataPrimeiraIa,
  }) {
    if (situacaoProdutiva != AnimalProductiveSituation.heifer) {
      return null;
    }

    return _monthsBetween(dataNascimento, dataPrimeiraIa);
  }

  static String? _mesParto(int? numeroPartos, DateTime? dataUltimoParto) {
    if (numeroPartos == null || numeroPartos < 1) {
      return null;
    }

    return nomeDoMes(dataUltimoParto);
  }

  static double? _iepAtual({
    required int? numeroPartos,
    required DateTime? dataPartoAnterior,
    required DateTime? dataUltimoParto,
  }) {
    if (numeroPartos == null || numeroPartos < 2) {
      return null;
    }

    return _monthsBetween(dataPartoAnterior, dataUltimoParto);
  }

  static String? _classificacaoPartos(int? numeroPartos) {
    if (numeroPartos == 1) {
      return 'Primipara';
    }
    if (numeroPartos != null && numeroPartos >= 2) {
      return 'Multipara';
    }
    return null;
  }

  static bool? _vacaApta(String? situacaoReprodutiva) {
    const fitStatuses = {
      AnimalReproductiveStatus.protocol,
      AnimalReproductiveStatus.empty,
      AnimalReproductiveStatus.released,
      AnimalReproductiveStatus.delayed,
      AnimalReproductiveStatus.waitingDiagnosis,
      AnimalReproductiveStatus.inseminatedSt,
    };
    const unfitStatuses = {
      AnimalReproductiveStatus.pregnant,
      AnimalReproductiveStatus.induction,
      AnimalReproductiveStatus.discard,
      AnimalReproductiveStatus.pev,
      AnimalReproductiveStatus.noAge,
      AnimalReproductiveStatus.calf,
    };

    if (_isAnyReproductiveStatus(situacaoReprodutiva, fitStatuses)) {
      return true;
    }
    if (_isAnyReproductiveStatus(situacaoReprodutiva, unfitStatuses)) {
      return false;
    }
    return null;
  }

  static double? _mediaIntervaloIa({
    required int? numeroIaRecebida,
    required String? situacaoReprodutiva,
    required Iterable<int?> intervalos,
  }) {
    const excludedStatuses = {
      AnimalReproductiveStatus.pev,
      AnimalReproductiveStatus.induction,
      AnimalReproductiveStatus.noAge,
      AnimalReproductiveStatus.discard,
    };
    if (numeroIaRecebida == null ||
        numeroIaRecebida < 2 ||
        _isAnyReproductiveStatus(situacaoReprodutiva, excludedStatuses)) {
      return null;
    }

    return media(intervalos);
  }

  static DateTime? _previsaoRetornoCio({
    required String? situacaoReprodutiva,
    required DateTime? dataUltimaIa,
  }) {
    const excludedStatuses = {
      AnimalReproductiveStatus.pregnant,
      AnimalReproductiveStatus.pev,
      AnimalReproductiveStatus.induction,
      AnimalReproductiveStatus.discard,
      AnimalReproductiveStatus.noAge,
      AnimalReproductiveStatus.calf,
      AnimalReproductiveStatus.released,
      AnimalReproductiveStatus.delayed,
    };
    if (_isAnyReproductiveStatus(situacaoReprodutiva, excludedStatuses)) {
      return null;
    }

    return adicionarDias(dataUltimaIa, 21);
  }

  static int? _diasPrenhez({
    required String? situacaoProdutiva,
    required String? situacaoReprodutiva,
    required DateTime? dataUltimaIa,
    required DateTime? dataAtual,
  }) {
    const excludedReproductiveStatuses = {
      AnimalReproductiveStatus.empty,
      AnimalReproductiveStatus.induction,
      AnimalReproductiveStatus.discard,
      AnimalReproductiveStatus.pev,
      AnimalReproductiveStatus.noAge,
      AnimalReproductiveStatus.delayed,
      AnimalReproductiveStatus.released,
    };

    if (situacaoProdutiva == AnimalProductiveSituation.calf ||
        _isAnyReproductiveStatus(
          situacaoReprodutiva,
          excludedReproductiveStatuses,
        )) {
      return null;
    }

    return diasEntre(dataUltimaIa, dataAtual);
  }

  static int? _delPrimeiraIa({
    required String? situacaoProdutiva,
    required String? situacaoReprodutiva,
    required DateTime? dataUltimoParto,
    required DateTime? dataPrimeiraIa,
  }) {
    const excludedReproductiveStatuses = {
      AnimalReproductiveStatus.induction,
      AnimalReproductiveStatus.discard,
      AnimalReproductiveStatus.pev,
      AnimalReproductiveStatus.noAge,
      AnimalReproductiveStatus.delayed,
      AnimalReproductiveStatus.released,
    };
    const excludedProductiveStatuses = {
      AnimalProductiveSituation.heifer,
      AnimalProductiveSituation.prepartum,
    };
    if (_isAnyReproductiveStatus(
          situacaoReprodutiva,
          excludedReproductiveStatuses,
        ) ||
        excludedProductiveStatuses.contains(situacaoProdutiva)) {
      return null;
    }

    return diasEntre(dataUltimoParto, dataPrimeiraIa);
  }

  static int? _periodoServico({
    required String? situacaoProdutiva,
    required String? situacaoReprodutiva,
    required DateTime? dataUltimoParto,
    required DateTime? dataUltimaIa,
    required int? diasPrenhez,
  }) {
    const excludedProductiveStatuses = {
      AnimalProductiveSituation.heifer,
      AnimalProductiveSituation.prepartum,
    };
    if (!_isPregnant(situacaoReprodutiva) ||
        excludedProductiveStatuses.contains(situacaoProdutiva) ||
        diasPrenhez == null) {
      return null;
    }

    return diasEntre(dataUltimoParto, dataUltimaIa);
  }

  static int? _diasParaSecar({
    required String? situacaoProdutiva,
    required String? situacaoReprodutiva,
    required int? diasPrenhez,
  }) {
    if (situacaoProdutiva == AnimalProductiveSituation.heifer ||
        !_isPregnant(situacaoReprodutiva) ||
        diasPrenhez == null) {
      return null;
    }

    return 220 - diasPrenhez;
  }

  static DateTime? _previsaoSecagem({
    required String? situacaoProdutiva,
    required String? situacaoReprodutiva,
    required DateTime? dataUltimaIa,
  }) {
    if (situacaoProdutiva == AnimalProductiveSituation.heifer ||
        !_isPregnant(situacaoReprodutiva)) {
      return null;
    }

    return adicionarDias(dataUltimaIa, 220);
  }

  static String? _mesSecagem({
    required String? situacaoReprodutiva,
    required DateTime? previsaoSecagem,
  }) {
    if (!_isPregnant(situacaoReprodutiva)) {
      return null;
    }

    return nomeDoMes(previsaoSecagem);
  }

  static int? _periodoLactacao({
    required String? situacaoProdutiva,
    required DateTime? dataSecagemEfetiva,
    required DateTime? dataUltimoParto,
  }) {
    if (situacaoProdutiva != AnimalProductiveSituation.dry) {
      return null;
    }

    return diasEntre(dataUltimoParto, dataSecagemEfetiva);
  }

  static DateTime? _dataPreParto({
    required String? situacaoReprodutiva,
    required DateTime? dataUltimaIa,
  }) {
    if (!_isPregnant(situacaoReprodutiva)) {
      return null;
    }

    return adicionarDias(dataUltimaIa, 252);
  }

  static String? _mesPreParto({
    required String? situacaoReprodutiva,
    required DateTime? dataPreParto,
  }) {
    if (!_isPregnant(situacaoReprodutiva)) {
      return null;
    }

    return nomeDoMes(dataPreParto);
  }

  static int? _duracaoPreParto({
    required String? situacaoProdutiva,
    required DateTime? entradaPreParto,
    required DateTime? dataUltimoParto,
  }) {
    if (situacaoProdutiva != AnimalProductiveSituation.lactating) {
      return null;
    }

    return diasEntre(entradaPreParto, dataUltimoParto);
  }

  static DateTime? _previsaoParto({
    required String? situacaoReprodutiva,
    required DateTime? dataUltimaIa,
  }) {
    if (!_isPregnant(situacaoReprodutiva)) {
      return null;
    }

    return adicionarDias(dataUltimaIa, 282);
  }

  static String? _mesPrevistoParto({
    required String? situacaoReprodutiva,
    required DateTime? previsaoParto,
  }) {
    if (!_isPregnant(situacaoReprodutiva)) {
      return null;
    }

    return nomeDoMes(previsaoParto);
  }

  static double? _iepProjetado({
    required String? situacaoProdutiva,
    required String? situacaoReprodutiva,
    required DateTime? previsaoParto,
    required DateTime? dataUltimoParto,
  }) {
    const excludedProductiveStatuses = {
      AnimalProductiveSituation.heifer,
      AnimalProductiveSituation.prepartum,
    };
    if (excludedProductiveStatuses.contains(situacaoProdutiva) ||
        !_isPregnant(situacaoReprodutiva)) {
      return null;
    }

    return _monthsBetween(dataUltimoParto, previsaoParto);
  }

  static double? _controleLeiteiroComDesconto({
    required String? situacaoProdutiva,
    required double? controleLeiteiro,
  }) {
    const excludedProductiveStatuses = {
      AnimalProductiveSituation.dry,
      AnimalProductiveSituation.prepartum,
      AnimalProductiveSituation.heifer,
    };
    if (controleLeiteiro == null ||
        excludedProductiveStatuses.contains(situacaoProdutiva)) {
      return null;
    }

    final result = controleLeiteiro * 0.70;
    return result.isFinite ? result : null;
  }

  static double? _monthsBetween(DateTime? start, DateTime? end) {
    final days = diasEntre(start, end);
    if (days == null) {
      return null;
    }

    final result = days / 30;
    return result.isFinite ? result : null;
  }

  static bool _isPregnant(String? value) {
    return _isReproductiveStatus(value, AnimalReproductiveStatus.pregnant);
  }

  static bool _isAnyReproductiveStatus(
    String? value,
    Set<AnimalReproductiveStatus> statuses,
  ) {
    return statuses.any((status) => _isReproductiveStatus(value, status));
  }

  static bool _isReproductiveStatus(
    String? value,
    AnimalReproductiveStatus status,
  ) {
    final normalized = _normalize(value);
    if (normalized == null) {
      return false;
    }

    if (normalized == status.apiValue.normalize() ||
        normalized == status.label.normalize()) {
      return true;
    }

    return status.aliases.any((alias) => normalized == alias.normalize());
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim().normalize();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

class _HeaderFields extends StatelessWidget {
  const _HeaderFields({
    required this.propertyId,
    required this.properties,
    required this.dataVisitaController,
    required this.onVisitDateChanged,
    required this.onPropertyChanged,
  });

  final int? propertyId;
  final List<PropertySummaryModel> properties;
  final TextEditingController dataVisitaController;
  final ValueChanged<String> onVisitDateChanged;
  final ValueChanged<int?> onPropertyChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 900;
        final fields = [
          AppDropdown<int>(
            value: propertyId,
            labelText: 'Propriedade vinculada',
            required: true,
            searchable: true,
            onChanged: onPropertyChanged,
            options: properties
                .map(
                  (property) => AppDropdownOption(
                    label: property.nome,
                    value: property.id,
                  ),
                )
                .toList(growable: false),
          ),
          AppTextField(
            label: 'Data da visita',
            hint: 'DD/MM/AAAA',
            controller: dataVisitaController,
            required: true,
            keyboardType: TextInputType.number,
            inputFormatters: const [DateInputFormatter()],
            onChanged: onVisitDateChanged,
            validator: (value) {
              if (parseDateInput(value ?? '') == null) {
                return 'Informe uma data válida';
              }
              return null;
            },
          ),
        ];

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _withSpacing(fields, 12),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: fields[0]),
            const SizedBox(width: 12),
            SizedBox(width: 180, child: fields[1]),
          ],
        );
      },
    );
  }

  List<Widget> _withSpacing(List<Widget> widgets, double spacing) {
    final children = <Widget>[];

    for (var index = 0; index < widgets.length; index++) {
      if (index > 0) {
        children.add(SizedBox(height: spacing));
      }
      children.add(widgets[index]);
    }

    return children;
  }
}

class _VisitActionsBar extends StatelessWidget {
  const _VisitActionsBar({
    required this.isBusy,
    required this.isLoadingAnimals,
    required this.onCancel,
    required this.onSave,
  });

  final bool isBusy;
  final bool isLoadingAnimals;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 1, color: colorScheme.outline),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children: [
                    AppButton(
                      text: 'Cancelar',
                      outlined: true,
                      height: 40,
                      onPressed: isBusy ? null : onCancel,
                    ),
                    AppButton(
                      text: 'Salvar visita',
                      height: 40,
                      loading: isBusy,
                      onPressed: isLoadingAnimals || isBusy ? null : onSave,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimalCollectionLayout extends StatefulWidget {
  const _AnimalCollectionLayout({
    required this.entries,
    required this.iaHistoryByAnimalId,
    required this.reviewedAnimalIds,
    required this.selectedAnimalId,
    required this.selectedEntry,
    required this.onSelectAnimal,
    required this.onChanged,
    required this.applyAutomaticCalculations,
    required this.onConfirmAnimal,
    required this.onOpenAnimal,
  });

  final List<VisitAnimalEntryModel> entries;
  final Map<int, _AnimalIaHistory> iaHistoryByAnimalId;
  final Set<int> reviewedAnimalIds;
  final int? selectedAnimalId;
  final VisitAnimalEntryModel? selectedEntry;
  final ValueChanged<int> onSelectAnimal;
  final ValueChanged<VisitAnimalEntryModel> onChanged;
  final _VisitEntryCalculator applyAutomaticCalculations;
  final ValueChanged<int> onConfirmAnimal;
  final ValueChanged<VisitAnimalEntryModel> onOpenAnimal;

  @override
  State<_AnimalCollectionLayout> createState() =>
      _AnimalCollectionLayoutState();
}

class _AnimalCollectionLayoutState extends State<_AnimalCollectionLayout> {
  final _editorKey = GlobalKey();
  double? _editorHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 920;
        final listPane = _AnimalListPane(
          entries: widget.entries,
          reviewedAnimalIds: widget.reviewedAnimalIds,
          selectedAnimalId: widget.selectedAnimalId,
          height: stacked ? null : _editorHeight,
          onSelectAnimal: stacked ? null : widget.onSelectAnimal,
          onOpenAnimal: stacked ? widget.onOpenAnimal : null,
        );
        final editorPane = KeyedSubtree(
          key: _editorKey,
          child: _AnimalEditorPane(
            entry: widget.selectedEntry,
            iaHistory: widget.selectedEntry == null
                ? _AnimalIaHistory.empty
                : widget.iaHistoryByAnimalId[widget.selectedEntry!.animalId] ??
                      _AnimalIaHistory.empty,
            onChanged: widget.onChanged,
            applyAutomaticCalculations: widget.applyAutomaticCalculations,
            onConfirmAnimal: widget.onConfirmAnimal,
            reviewed:
                widget.selectedEntry != null &&
                widget.reviewedAnimalIds.contains(
                  widget.selectedEntry!.animalId,
                ),
          ),
        );

        if (stacked) {
          return listPane;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncEditorHeight();
        });

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 320, child: listPane),
            const SizedBox(width: 16),
            Expanded(child: editorPane),
          ],
        );
      },
    );
  }

  void _syncEditorHeight() {
    if (!mounted) {
      return;
    }

    final renderObject = _editorKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return;
    }

    final height = renderObject.size.height;
    if (height <= 0) {
      return;
    }

    if (_editorHeight == null || (height - _editorHeight!).abs() > 0.5) {
      setState(() {
        _editorHeight = height;
      });
    }
  }
}

class _AnimalListPane extends StatefulWidget {
  const _AnimalListPane({
    required this.entries,
    required this.reviewedAnimalIds,
    required this.selectedAnimalId,
    this.height,
    this.onSelectAnimal,
    this.onOpenAnimal,
  });

  final List<VisitAnimalEntryModel> entries;
  final Set<int> reviewedAnimalIds;
  final int? selectedAnimalId;
  final double? height;
  final ValueChanged<int>? onSelectAnimal;
  final ValueChanged<VisitAnimalEntryModel>? onOpenAnimal;

  @override
  State<_AnimalListPane> createState() => _AnimalListPaneState();
}

class _AnimalListPaneState extends State<_AnimalListPane> {
  late final TextEditingController _searchController;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleEntries = _visibleEntries;
    final hasFixedHeight = widget.height != null;
    final entriesList = visibleEntries.isEmpty
        ? _AnimalListEmptyState(expanded: hasFixedHeight)
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            primary: false,
            shrinkWrap: !hasFixedHeight,
            itemCount: visibleEntries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final entry = visibleEntries[index];
              final selected =
                  entry.animalId == widget.selectedAnimalId ||
                  (widget.selectedAnimalId == null &&
                      widget.entries.isNotEmpty &&
                      entry.animalId == widget.entries.first.animalId);

              return _AnimalListItem(
                entry: entry,
                selected: selected,
                reviewed: widget.reviewedAnimalIds.contains(entry.animalId),
                subtitle: _buildSubtitle(entry),
                onTap: () {
                  if (widget.onOpenAnimal != null) {
                    widget.onOpenAnimal!(entry);
                    return;
                  }
                  widget.onSelectAnimal?.call(entry.animalId);
                },
              );
            },
          );
    final listBody = hasFixedHeight
        ? Expanded(child: entriesList)
        : ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 480),
            child: entriesList,
          );

    final card = AppCard(
      padding: EdgeInsets.zero,
      borderRadius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Text(
              'Brincos',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: AppTextField(
              controller: _searchController,
              label: 'Buscar brinco',
              hint: 'Digite o brinco',
              clearable: true,
              prefixIcon: const Icon(Icons.search_outlined),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
          ),
          const Divider(height: 1),
          listBody,
        ],
      ),
    );

    final height = widget.height;
    if (height == null) {
      return card;
    }

    return SizedBox(height: height, child: card);
  }

  List<VisitAnimalEntryModel> get _visibleEntries {
    final query = _searchTerm.trim().normalize();
    if (query.isEmpty) {
      return widget.entries;
    }

    return widget.entries
        .where((entry) {
          final searchText = [
            entry.animalId.toString(),
            entry.animalCodigo,
            entry.animalCategoria,
            entry.situacaoProdutiva ?? '',
            entry.situacaoReprodutiva ?? '',
          ].join(' ').normalize();

          return searchText.contains(query);
        })
        .toList(growable: false);
  }

  void _handleSearchChanged() {
    if (_searchTerm == _searchController.text) {
      return;
    }

    setState(() {
      _searchTerm = _searchController.text;
    });
  }

  String _buildSubtitle(VisitAnimalEntryModel entry) {
    final parts = <String>[
      if (entry.situacaoProdutiva?.isNotEmpty == true) entry.situacaoProdutiva!,
      if (entry.situacaoReprodutiva?.isNotEmpty == true)
        entry.situacaoReprodutiva!,
      if (entry.animalCategoria.isNotEmpty) entry.animalCategoria,
    ];

    if (parts.isEmpty) {
      return 'Toque para preencher os dados';
    }

    return parts.join(' | ');
  }
}

class _AnimalListEmptyState extends StatelessWidget {
  const _AnimalListEmptyState({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.all(18),
      child: Text(
        'Nenhum brinco encontrado.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );

    if (!expanded) {
      return content;
    }

    return Center(child: content);
  }
}

class _AnimalListItem extends StatelessWidget {
  const _AnimalListItem({
    required this.entry,
    required this.selected,
    required this.reviewed,
    required this.subtitle,
    required this.onTap,
  });

  final VisitAnimalEntryModel entry;
  final bool selected;
  final bool reviewed;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedBackground = theme.brightness == Brightness.dark
        ? colorScheme.secondary.withValues(alpha: 0.28)
        : colorScheme.secondary.withValues(alpha: 0.72);
    final title = entry.animalCodigo;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Material(
        color: selected ? selectedBackground : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              if (selected)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 4, color: colorScheme.primary),
                ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selected
                        ? colorScheme.primary.withValues(alpha: 0.18)
                        : colorScheme.outline.withValues(alpha: 0.16),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.fromLTRB(selected ? 16 : 12, 10, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: selected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    reviewed
                        ? Icon(
                            Icons.check_circle,
                            size: 20,
                            color: colorScheme.primary,
                          )
                        : Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimalEditorPane extends StatelessWidget {
  const _AnimalEditorPane({
    required this.entry,
    required this.iaHistory,
    required this.onChanged,
    required this.applyAutomaticCalculations,
    required this.onConfirmAnimal,
    required this.reviewed,
  });

  final VisitAnimalEntryModel? entry;
  final _AnimalIaHistory iaHistory;
  final ValueChanged<VisitAnimalEntryModel> onChanged;
  final _VisitEntryCalculator applyAutomaticCalculations;
  final ValueChanged<int> onConfirmAnimal;
  final bool reviewed;

  @override
  Widget build(BuildContext context) {
    if (entry == null) {
      return const _FeedbackPanel(
        message: 'Selecione um animal na lista para editar os dados da visita.',
      );
    }

    final selectedEntry = entry!;

    return AppCard(
      key: ValueKey(selectedEntry.animalId),
      padding: const EdgeInsets.all(16),
      borderRadius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AnimalEditorHeader(entry: selectedEntry, reviewed: reviewed),
          const SizedBox(height: 18),
          _AnimalEditorFields(
            entry: selectedEntry,
            iaHistory: iaHistory,
            onChanged: onChanged,
            applyAutomaticCalculations: applyAutomaticCalculations,
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: _AnimalConfirmationButton(
              animalId: selectedEntry.animalId,
              reviewed: reviewed,
              onConfirmAnimal: onConfirmAnimal,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimalEditorHeader extends StatelessWidget {
  const _AnimalEditorHeader({required this.entry, required this.reviewed});

  final VisitAnimalEntryModel entry;
  final bool reviewed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = entry.animalCodigo;
    final identity = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.secondary.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.28 : 0.8,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(MdiIcons.cow, color: colorScheme.primary, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _AnimalVisitStatusBadge(reviewed: reviewed),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [identity],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Expanded(child: identity)],
        );
      },
    );
  }
}

class _AnimalConfirmationButton extends StatelessWidget {
  const _AnimalConfirmationButton({
    required this.animalId,
    required this.reviewed,
    required this.onConfirmAnimal,
  });

  final int animalId;
  final bool reviewed;
  final ValueChanged<int> onConfirmAnimal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppButton(
      text: reviewed ? 'Atualizar confirmação' : 'Confirmar animal',
      height: 40,
      outlined: reviewed,
      icon: reviewed
          ? Icon(Icons.refresh_rounded, size: 18, color: colorScheme.primary)
          : null,
      borderColor: reviewed ? colorScheme.outline : null,
      textColor: reviewed ? colorScheme.primary : null,
      onPressed: () => onConfirmAnimal(animalId),
    );
  }
}

class _AnimalVisitStatusBadge extends StatelessWidget {
  const _AnimalVisitStatusBadge({required this.reviewed});

  final bool reviewed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = reviewed
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final backgroundColor = reviewed
        ? colorScheme.secondary.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.28 : 0.78,
          )
        : colorScheme.surfaceContainerHighest;
    final borderColor = reviewed
        ? colorScheme.primary.withValues(alpha: 0.28)
        : colorScheme.outline.withValues(alpha: 0.45);
    final icon = reviewed
        ? Icons.check_circle_outline_rounded
        : Icons.hourglass_bottom_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              reviewed ? 'Confirmado na visita' : 'Aguardando confirmação',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimalEditorFields extends StatelessWidget {
  const _AnimalEditorFields({
    required this.entry,
    required this.iaHistory,
    required this.onChanged,
    required this.applyAutomaticCalculations,
  });

  final VisitAnimalEntryModel entry;
  final _AnimalIaHistory iaHistory;
  final ValueChanged<VisitAnimalEntryModel> onChanged;
  final _VisitEntryCalculator applyAutomaticCalculations;

  @override
  Widget build(BuildContext context) {
    void emitChanged(VisitAnimalEntryModel value) {
      onChanged(applyAutomaticCalculations(value));
    }

    final hasVisitIa = _hasVisitIa(entry, iaHistory);
    final visitIaDate = hasVisitIa ? entry.dataUltimaIa : null;
    final visitIaNumber = hasVisitIa
        ? entry.numeroIaRecebida
        : iaHistory.suggestedNextNumber;
    final animalIdentifier = _animalIdentifier(entry);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EditorSection(
          title: 'Dados do animal',
          child: _EditorGrid(
            children: [
              AppTextField(
                key: ValueKey('animal-id-${entry.animalId}-$animalIdentifier'),
                label: 'Identificação / número',
                initialValue: animalIdentifier,
                readOnly: true,
              ),
              AppDropdown<String>(
                value: entry.situacaoProdutiva,
                labelText: 'Situação produtiva',
                onChanged: (value) =>
                    emitChanged(entry.copyWith(situacaoProdutiva: value)),
                options: _VisitFormPageState._situacaoProdutivaOptions,
              ),
              AppDropdown<String>(
                value: entry.situacaoReprodutiva,
                labelText: 'Situação reprodutiva',
                onChanged: (value) =>
                    emitChanged(entry.copyWith(situacaoReprodutiva: value)),
                options: _VisitFormPageState._situacaoReprodutivaOptions,
              ),
              _DateInputField(
                label: 'Data último parto',
                value: entry.dataUltimoParto,
                onChanged: (value) =>
                    emitChanged(entry.copyWith(dataUltimoParto: value)),
              ),
              AppTextField(
                label: 'Decisão',
                initialValue: entry.decisao ?? '',
                onChanged: (value) => emitChanged(
                  entry.copyWith(
                    decisao: value.trim().isEmpty ? null : value.trim(),
                  ),
                ),
              ),
              AppTextField(
                label: 'Diagnóstico',
                initialValue: entry.diagnostico ?? '',
                onChanged: (value) => emitChanged(
                  entry.copyWith(
                    diagnostico: value.trim().isEmpty ? null : value.trim(),
                  ),
                ),
              ),
              _calculatedText('Idade (meses)', _formatDouble(entry.idadeMeses)),
              _calculatedText('DEL', _formatInt(entry.del)),
              _calculatedText('Dias prenhez', _formatInt(entry.diasPrenhez)),
              _calculatedText('Dias p/ secar', _formatInt(entry.diasParaSecar)),
              _calculatedText(
                'Previsão parto',
                formatDateInput(entry.previsaoParto),
              ),
              _calculatedText(
                'Última IA (histórico)',
                formatDateInput(iaHistory.lastDate),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _EditorSection(
          title: 'Inseminação Artificial',
          child: _EditorGrid(
            children: [
              _DateInputField(
                key: ValueKey(
                  'visit-ia-date-${entry.animalId}-$hasVisitIa-$visitIaDate',
                ),
                label: 'Data da nova IA',
                value: visitIaDate,
                onChanged: (value) => emitChanged(
                  _entryWithVisitIaDate(
                    entry: entry,
                    iaHistory: iaHistory,
                    value: value,
                  ),
                ),
              ),
              AppTextField(
                key: ValueKey(
                  'visit-ia-number-${entry.animalId}-$hasVisitIa-$visitIaNumber',
                ),
                label: 'Número da IA da visita',
                initialValue: _formatInt(visitIaNumber),
                keyboardType: TextInputType.number,
                readOnly: !hasVisitIa,
                onChanged: (value) => emitChanged(
                  _entryWithVisitIaNumber(
                    entry: entry,
                    iaHistory: iaHistory,
                    value: value,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _EditorSection(
          title: 'Secagem e pré-parto',
          child: _EditorGrid(
            children: [
              _DateInputField(
                label: 'Secagem efetiva',
                value: entry.dataSecagemEfetiva,
                onChanged: (value) =>
                    emitChanged(entry.copyWith(dataSecagemEfetiva: value)),
              ),
              _DateInputField(
                label: 'Entrada pré-parto',
                value: entry.entradaPreParto,
                onChanged: (value) =>
                    emitChanged(entry.copyWith(entradaPreParto: value)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatInt(int? value) => value?.toString() ?? '';

  static String _formatDouble(double? value) {
    if (value == null || !value.isFinite) return '';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  Widget _calculatedText(String label, String value) {
    return AppTextField(
      key: ValueKey('visit-calc-${entry.animalId}-$label-$value'),
      label: label,
      initialValue: value,
      readOnly: true,
    );
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _EditorGrid extends StatelessWidget {
  const _EditorGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth >= 980
            ? 3
            : maxWidth >= 640
            ? 2
            : 1;
        final spacing = 12.0;
        final itemWidth = (maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(growable: false),
        );
      },
    );
  }
}

class _AnimalEditorModalContent extends StatefulWidget {
  const _AnimalEditorModalContent({
    required this.entry,
    required this.iaHistory,
    required this.applyAutomaticCalculations,
  });

  final VisitAnimalEntryModel entry;
  final _AnimalIaHistory iaHistory;
  final _VisitEntryCalculator applyAutomaticCalculations;

  @override
  State<_AnimalEditorModalContent> createState() =>
      _AnimalEditorModalContentState();
}

class _AnimalEditorModalContentState extends State<_AnimalEditorModalContent> {
  late VisitAnimalEntryModel _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.applyAutomaticCalculations(widget.entry);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Preencha e confirme os dados da visita.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        _AnimalEditorFields(
          entry: _draft,
          iaHistory: widget.iaHistory,
          applyAutomaticCalculations: widget.applyAutomaticCalculations,
          onChanged: (value) => setState(() {
            _draft = widget.applyAutomaticCalculations(value);
          }),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.end,
          children: [
            AppButton(
              text: 'Cancelar',
              outlined: true,
              height: 40,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            AppButton(
              text: 'Confirmar animal',
              height: 40,
              onPressed: () => Navigator.of(context).pop(_draft),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateInputField extends StatelessWidget {
  const _DateInputField({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      hint: 'DD/MM/AAAA',
      initialValue: formatDateInput(value),
      keyboardType: TextInputType.number,
      inputFormatters: const [DateInputFormatter()],
      onChanged: onChanged == null
          ? null
          : (text) => onChanged!(parseDateInput(text)),
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({required this.message, this.error = false});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: error
            ? colorScheme.errorContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: error ? colorScheme.error : colorScheme.outline,
        ),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: error
              ? colorScheme.onErrorContainer
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
