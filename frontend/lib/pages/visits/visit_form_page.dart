import 'package:cysvet_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:cysvet_app/app/app_shell.dart';
import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/core/platform/offline_platform.dart';
import 'package:cysvet_app/core/presentation/app_scaffold_messenger.dart';
import 'package:cysvet_app/core/utils/formatters.dart';
import 'package:cysvet_app/core/widgets/app_button.dart';
import 'package:cysvet_app/core/widgets/app_card.dart';
import 'package:cysvet_app/core/widgets/app_dialog.dart';
import 'package:cysvet_app/core/widgets/app_dropdown.dart';
import 'package:cysvet_app/core/widgets/app_date_field.dart';
import 'package:cysvet_app/core/widgets/app_text_field.dart';
import 'package:cysvet_app/core/widgets/reproductive_status_picker.dart';
import 'package:cysvet_app/core/widgets/responsive_field_grid.dart';
import 'package:cysvet_app/models/animal_summary_model.dart';
import 'package:cysvet_app/providers/animals_provider.dart';
import 'package:cysvet_app/providers/connectivity_provider.dart';
import 'package:cysvet_app/models/indicador_reprodutivo_calculator.dart';
import 'package:cysvet_app/providers/properties_provider.dart';
import 'package:cysvet_app/models/property_summary_model.dart';
import 'package:cysvet_app/models/visit_action_hint.dart';
import 'package:cysvet_app/providers/visit_in_progress_provider.dart';
import 'package:cysvet_app/providers/visits_provider.dart';
import 'package:cysvet_app/local/sync_queue_store.dart';
import 'package:cysvet_app/models/gestational_loss.dart';
import 'package:cysvet_app/models/visit_informed_fields.dart';
import 'package:cysvet_app/providers/offline_first.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';

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

class _AnimalLastBirthSnapshot {
  const _AnimalLastBirthSnapshot({
    required this.lastBirthDate,
    required this.visitDate,
  });

  final DateTime lastBirthDate;
  final DateTime? visitDate;
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
  const VisitFormPage({
    super.key,
    this.initialPropertyId,
    this.editingIdExterno,
  });

  final int? initialPropertyId;

  /// Mobile: `idExterno` da visita salva no aparelho a ser continuada/editada.
  final String? editingIdExterno;

  @override
  ConsumerState<VisitFormPage> createState() => _VisitFormPageState();
}

class _VisitFormPageState extends ConsumerState<VisitFormPage> {
  static const _situacaoProdutivaOptions = [
    AppDropdownOption<String>(label: 'Não informado', value: null),
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

  /// Visita local sendo editada (mobile). Mantém o mesmo `idExterno` para que
  /// salvar de novo atualize o registro em vez de criar outro.
  VisitSummaryModel? _editingVisit;
  bool _isEditingDraft = false;

  /// Reservado ao abrir: tentar salvar de novo não cria outra visita.
  String _newVisitIdExterno = const Uuid().v4();

  /// Método do DG da visita, lembrado no aparelho entre visitas.
  String _metodoDg = 'ultrassom';
  static const _metodoDgKey = 'metodo_dg';

  Future<void> _loadMetodoDg() async {
    if (ref.read(offlineScopeProvider) == null) return;
    try {
      final saved = await ref.read(syncQueueStoreProvider).readMeta(_metodoDgKey);
      if (mounted && saved != null && metodosDiagnostico.containsKey(saved)) {
        setState(() => _metodoDg = saved);
      }
    } catch (_) {
      // Preferência é só conveniência.
    }
  }

  void _setMetodoDg(String value) {
    setState(() => _metodoDg = value);
    if (ref.read(offlineScopeProvider) == null) return;
    ref.read(syncQueueStoreProvider).writeMeta(_metodoDgKey, value).ignore();
  }

  /// Esta tela reabriu a visita que tinha ficado em andamento.
  bool _resumed = false;

  @override
  void initState() {
    super.initState();
    _dataVisita.text = formatDateInput(DateTime.now());
    _propertyId = widget.initialPropertyId;
    _dataVisita.addListener(_rememberProgress);
    _loadMetodoDg();
    if (_restoreProgress()) {
      _resumed = true;
    } else if (widget.editingIdExterno != null) {
      _isLoadingAnimals = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadEditingVisit(widget.editingIdExterno!);
      });
    } else if (_propertyId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadAnimalsForSelectedProperty();
        }
      });
    }
  }

  @override
  void dispose() {
    _dataVisita
      ..removeListener(_rememberProgress)
      ..dispose();
    super.dispose();
  }

  // Toda mudança de estado da coleta fica guardada para o usuário poder sair
  // da visita, ir a outra tela e voltar do ponto onde parou.
  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _rememberProgress();
  }

  String get _route => widget.editingIdExterno == null
      ? '/visitas/nova'
      : '/visitas/editar/${widget.editingIdExterno}';

  void _rememberProgress() {
    if (!mounted || _propertyId == null || _isLoadingAnimals) return;
    final properties = ref.read(propertiesProvider).asData?.value ?? const [];
    ref
        .read(visitInProgressProvider.notifier)
        .remember(
          VisitInProgress(
            route: _route,
            propertyId: _propertyId,
            propertyName: _selectedProperty(properties)?.nome,
            dataVisita: _dataVisita.text,
            entries: _animalEntries,
            reviewedAnimalIds: _reviewedAnimalIds,
            selectedAnimalId: _selectedAnimalId,
            editing: _editingVisit,
            isEditingDraft: _isEditingDraft,
            newIdExterno: _newVisitIdExterno,
            iaHistory: {
              for (final item in _iaHistoryByAnimalId.entries)
                item.key: VisitIaHistorySnapshot(
                  dates: item.value.dates,
                  totalIas: item.value.totalIas,
                ),
            },
          ),
        );
  }

  /// Reabre a visita em andamento se ela é desta mesma tela (nova visita ou a
  /// mesma visita em edição) e da mesma propriedade, quando informada.
  bool _restoreProgress() {
    final saved = ref.read(visitInProgressProvider);
    if (saved == null || saved.route != _route) return false;
    final property = widget.initialPropertyId;
    if (property != null && property != saved.propertyId) return false;

    _propertyId = saved.propertyId;
    _loadedPropertyId = saved.propertyId;
    _dataVisita.text = saved.dataVisita;
    _animalEntries = saved.entries;
    _reviewedAnimalIds = saved.reviewedAnimalIds;
    _selectedAnimalId = saved.selectedAnimalId;
    _editingVisit = saved.editing;
    _isEditingDraft = saved.isEditingDraft;
    _newVisitIdExterno = saved.newIdExterno ?? _newVisitIdExterno;
    _iaHistoryByAnimalId = {
      for (final item in saved.iaHistory.entries)
        item.key: _AnimalIaHistory(
          dates: List.unmodifiable(item.value.dates),
          totalIas: item.value.totalIas,
        ),
    };
    return true;
  }

  void _discardProgress() {
    ref.read(visitInProgressProvider.notifier).clear();
  }

  /// "Cancelar": sai da visita e oferece desfazer, que reabre a visita onde
  /// estava (antes, um toque apagava tudo sem volta).
  void _cancelVisit() {
    final notifier = ref.read(visitInProgressProvider.notifier);
    final router = GoRouter.of(context);
    final saved = ref.read(visitInProgressProvider);
    notifier.clear();
    router.go('/visitas');
    if (saved != null && saved.collectedCount > 0) {
      showAppUndo(
        'Visita cancelada (${saved.collectedCount} '
        '${saved.collectedCount == 1 ? 'animal coletado' : 'animais coletados'}).',
        onUndo: () {
          notifier.remember(saved);
          router.go(saved.route);
        },
      );
    }
  }

  /// Descarta a visita reaberta e começa outra do zero.
  void _startOver() {
    _discardProgress();
    setState(() {
      _resumed = false;
      _editingVisit = null;
      _newVisitIdExterno = const Uuid().v4();
      _isEditingDraft = false;
      _propertyId = widget.initialPropertyId;
      _dataVisita.text = formatDateInput(DateTime.now());
      _resetAnimalCollection();
    });
    if (_propertyId != null) _loadAnimalsForSelectedProperty();
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
              padding: EdgeInsets.zero,
              children: [
                PageTitle(title: _pageTitle, backRoute: '/visitas'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        borderRadius: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _pageTitle,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (_resumed &&
                                widget.editingIdExterno == null) ...[
                              _ResumedNotice(onStartOver: _startOver),
                              const SizedBox(height: 10),
                            ],
                            Text(
                              'Escolha a propriedade e toque nos animais. '
                              'Quem precisa de ação aparece primeiro.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _HeaderFields(
                              propertyId: _propertyId,
                              properties: properties,
                              metodoDg: _metodoDg,
                              onMetodoDgChanged: _setMetodoDg,
                              dataVisitaController: _dataVisita,
                              onVisitDateChanged: (_) =>
                                  _recalculateAnimalEntries(),
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
                                  label:
                                      selectedProperty?.nome ??
                                      'Sem propriedade',
                                ),
                                _SummaryChip(
                                  icon: MdiIcons.cow,
                                  label: '${_animalEntries.length} animais',
                                ),
                                _SummaryChip(
                                  icon: Icons.fact_check_outlined,
                                  label: '$collectedCount com coleta',
                                ),
                                if (_actionCount > 0)
                                  _SummaryChip(
                                    icon: Icons.priority_high_rounded,
                                    label: '$_actionCount precisam de ação',
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
                          entries: _orderedEntries,
                          hintsByAnimalId: _hintsByAnimalId,
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
                          applyAutomaticCalculations:
                              _applyAutomaticCalculations,
                          onConfirmAnimal: _confirmAnimal,
                          onOpenAnimal: _editAnimalInModal,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _VisitActionsBar(
            isBusy: isBusy,
            isLoadingAnimals: _isLoadingAnimals,
            onCancel: _cancelVisit,
            onSave: _saveVisit,
            // Rascunho só no app mobile e enquanto a visita não foi finalizada.
            onSaveDraft:
                isOfflineFirstPlatform &&
                    (_editingVisit == null || _isEditingDraft)
                ? () => _saveVisit(asDraft: true)
                : null,
          ),
        ],
      ),
    );
  }

  String get _pageTitle {
    if (_editingVisit == null) return 'Nova visita';
    return _isEditingDraft ? 'Continuar visita' : 'Editar visita';
  }

  Future<void> _loadEditingVisit(String idExterno) async {
    try {
      final record = await ref
          .read(visitsControllerProvider)
          .findLocal(idExterno);
      if (!mounted) return;
      if (record == null) {
        setState(() => _isLoadingAnimals = false);
        showAppWarning('Visita não encontrada no aparelho.');
        return;
      }

      final visit = record.visit;
      setState(() {
        _editingVisit = visit;
        _isEditingDraft = record.isDraft;
        _propertyId = visit.idPropriedade == 0 ? null : visit.idPropriedade;
        if (visit.dataVisita != null) {
          _dataVisita.text = formatDateInput(visit.dataVisita!);
        }
        if (_propertyId == null) _isLoadingAnimals = false;
      });
      await _loadAnimalsForSelectedProperty();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingAnimals = false);
      showAppError(error);
    }
  }

  /// Reaplica os eventos já registrados na visita editada sobre a lista de
  /// animais da propriedade.
  ({List<VisitAnimalEntryModel> entries, Set<int> reviewedIds})
  _applyEditingEntries(int propertyId, List<VisitAnimalEntryModel> entries) {
    final editing = _editingVisit;
    if (editing == null || editing.idPropriedade != propertyId) {
      return (entries: entries, reviewedIds: const <int>{});
    }

    final reviewedIds = <int>{};
    final merged = entries
        .map((entry) {
          for (final saved in editing.animais) {
            if (_sameAnimalEntry(saved, entry)) {
              reviewedIds.add(entry.animalId);
              return saved.copyWith(animalId: entry.animalId);
            }
          }
          return entry;
        })
        .toList(growable: false);
    return (entries: merged, reviewedIds: reviewedIds);
  }

  bool _sameAnimalEntry(VisitAnimalEntryModel a, VisitAnimalEntryModel b) {
    if (a.animalId != 0 && a.animalId == b.animalId) return true;
    final externalId = a.animalIdExterno.trim();
    if (externalId.isNotEmpty && externalId == b.animalIdExterno.trim()) {
      return true;
    }
    final code = a.animalCodigo.trim();
    return code.isNotEmpty && code == b.animalCodigo.trim();
  }

  /// Avisos do "o que fazer hoje" por animal, na data da visita.
  Map<int, List<VisitActionHint>> get _hintsByAnimalId {
    final dataVisita = parseDateInput(_dataVisita.text);
    return {
      for (final entry in _animalEntries)
        entry.animalId: visitActionHints(entry, dataVisita: dataVisita),
    };
  }

  int get _actionCount =>
      _hintsByAnimalId.values.where((hints) => hints.isNotEmpty).length;

  /// Quem precisa de ação primeiro (atrasados antes), depois o resto na
  /// ordem do brinco.
  List<VisitAnimalEntryModel> get _orderedEntries {
    final hints = _hintsByAnimalId;
    int rank(VisitAnimalEntryModel entry) {
      final list = hints[entry.animalId] ?? const [];
      if (list.isEmpty) return 2;
      return list.first.urgent ? 0 : 1;
    }

    final indexed = _animalEntries.indexed.toList()
      ..sort((a, b) {
        final byRank = rank(a.$2).compareTo(rank(b.$2));
        return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
      });
    return [for (final item in indexed) item.$2];
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
          .read(animalsControllerProvider)
          .listByProperty(propertyId);
      final previousVisits = await ref
          .read(visitsControllerProvider)
          .listByProperty(
            propertyId,
            excludeIdExterno: _editingVisit?.idExterno,
          );
      if (!mounted) {
        return;
      }

      final iaHistoryByAnimalId = _buildIaHistoryByAnimalId(
        animals: animals,
        visits: previousVisits,
      );
      final lastBirthByAnimalId = _buildLastBirthByAnimalId(
        animals: animals,
        visits: previousVisits,
      );
      final editing = _applyEditingEntries(
        propertyId,
        animals
            .map(
              (animal) => _entryFromAnimal(
                animal,
                iaHistoryByAnimalId: iaHistoryByAnimalId,
                lastBirthByAnimalId: lastBirthByAnimalId,
              ),
            )
            .toList(growable: false),
      );
      final entries = editing.entries;
      setState(() {
        _loadedPropertyId = propertyId;
        _animalEntries = entries;
        if (editing.reviewedIds.isNotEmpty) {
          _reviewedAnimalIds = editing.reviewedIds;
        }
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

  Map<int, DateTime> _buildLastBirthByAnimalId({
    required List<AnimalSummaryModel> animals,
    required List<VisitSummaryModel> visits,
  }) {
    final result = <int, _AnimalLastBirthSnapshot>{};

    for (final animal in animals) {
      final backendLastBirth = animal.dataUltimoParto;
      if (backendLastBirth != null) {
        result[animal.id] = _AnimalLastBirthSnapshot(
          lastBirthDate: DateUtils.dateOnly(backendLastBirth),
          visitDate: null,
        );
      }

      for (final visit in visits) {
        final visitDate = visit.dataVisita == null
            ? null
            : DateUtils.dateOnly(visit.dataVisita!);

        for (final entry in visit.animais) {
          if (!_visitEntryBelongsToAnimal(entry, animal)) {
            continue;
          }

          final lastBirth = entry.dataUltimoParto;
          if (lastBirth == null) {
            continue;
          }

          final candidate = _AnimalLastBirthSnapshot(
            lastBirthDate: DateUtils.dateOnly(lastBirth),
            visitDate: visitDate,
          );
          final current = result[animal.id];
          if (_shouldReplaceLastBirth(current: current, candidate: candidate)) {
            result[animal.id] = candidate;
          }
        }
      }
    }

    return {
      for (final entry in result.entries) entry.key: entry.value.lastBirthDate,
    };
  }

  bool _shouldReplaceLastBirth({
    required _AnimalLastBirthSnapshot? current,
    required _AnimalLastBirthSnapshot candidate,
  }) {
    if (current == null) {
      return true;
    }

    final currentVisitDate = current.visitDate;
    final candidateVisitDate = candidate.visitDate;
    if (currentVisitDate == null && candidateVisitDate != null) {
      return true;
    }
    if (currentVisitDate != null && candidateVisitDate != null) {
      if (candidateVisitDate.isAfter(currentVisitDate)) {
        return true;
      }
      if (candidateVisitDate.isBefore(currentVisitDate)) {
        return false;
      }
    }

    return candidate.lastBirthDate.isAfter(current.lastBirthDate);
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

  Future<void> _saveVisit({bool asDraft = false}) async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    try {
      final properties = ref.read(propertiesProvider).asData?.value ?? const [];
      final property = _selectedProperty(properties);
      final editing = _editingVisit;
      final payload = VisitSummaryModel(
        id: editing?.id ?? 0,
        idExterno: editing?.idExterno ?? _newVisitIdExterno,
        idPropriedade: _propertyId ?? 0,
        idExternoPropriedade:
            property?.idExterno ?? editing?.idExternoPropriedade ?? '',
        dataVisita: parseDateInput(_dataVisita.text),
        observacoes: editing?.observacoes,
        idUsuario: editing?.idUsuario,
        nomeUsuario: editing?.nomeUsuario,
        animais: _animalEntries
            .where((item) => _reviewedAnimalIds.contains(item.animalId))
            .map((item) => item.copyWith(metodoDiagnostico: _metodoDg))
            .toList(growable: false),
      );

      final controller = ref.read(visitsControllerProvider);
      if (asDraft) {
        await controller.saveDraft(payload);
      } else {
        await controller.save(payload);
      }
      if (mounted) {
        _discardProgress();
        showAppSuccess(_savedMessage(asDraft: asDraft));
        context.go('/visitas');
      }
    } catch (error) {
      showAppError(error);
    }
  }

  String _savedMessage({required bool asDraft}) {
    if (!isOfflineFirstPlatform) return 'Visita salva com sucesso.';
    if (asDraft) return 'Rascunho salvo no aparelho.';
    if (ref.read(isOfflineProvider)) {
      return 'Visita salva no aparelho. Será sincronizada quando a conexão voltar.';
    }
    return 'Visita salva. Sincronizando com o servidor...';
  }

  void _resetAnimalCollection() {
    _loadedPropertyId = null;
    _selectedAnimalId = null;
    _animalsError = null;
    _animalEntries = const [];
    _iaHistoryByAnimalId = const {};
    _reviewedAnimalIds = const {};
  }

  // Mexer em qualquer campo do animal já conta como coleta: antes era preciso
  // tocar em "Confirmar animal" e a mudança (ex.: prenha) se perdia sem aviso.
  void _updateAnimalEntry(VisitAnimalEntryModel updated) {
    final calculated = _applyAutomaticCalculations(updated);
    setState(() {
      _reviewedAnimalIds = {..._reviewedAnimalIds, calculated.animalId};
      _animalEntries = _animalEntries
          .map((entry) {
            if (entry.animalId == calculated.animalId) {
              // Marca o que o veterinário mexeu: só isso vira evento.
              return withInformedChanges(entry, calculated);
            }
            return entry;
          })
          .toList(growable: false);
    });
  }

  void _confirmAnimal(int animalId) {
    setState(() {
      _reviewedAnimalIds = {..._reviewedAnimalIds, animalId};
      _animalEntries = _animalEntries
          .map(
            (entry) => entry.animalId == animalId
                ? withConfirmedSituation(entry)
                : entry,
          )
          .toList(growable: false);
    });
  }

  /// Animal da visita pelo brinco digitado: o exato, ou o único que contém o
  /// texto. Os animais entram no brete fora de ordem, então o veterinário vai
  /// pelo brinco, não por "próximo da lista".
  VisitAnimalEntryModel? _findByCode(String value) {
    final query = value.trim().normalize();
    if (query.isEmpty) return null;
    final exact = _animalEntries.where(
      (entry) => entry.animalCodigo.trim().normalize() == query,
    );
    if (exact.isNotEmpty) return exact.first;
    final partial = _animalEntries
        .where((entry) => entry.animalCodigo.normalize().contains(query))
        .toList(growable: false);
    return partial.length == 1 ? partial.single : null;
  }

  /// Mobile: um animal por vez. Ao terminar, o veterinário digita o brinco
  /// da próxima vaca que entrou no brete e ela abre direto (a atual é salva).
  Future<void> _editAnimalInModal(VisitAnimalEntryModel entry) async {
    VisitAnimalEntryModel? current = entry;
    while (current != null && mounted) {
      final collected = _reviewedAnimalIds.length;
      final total = _animalEntries.length;
      final shown = current;
      final wasReviewed = _reviewedAnimalIds.contains(shown.animalId);
      final result = await AppDialog.show<_ModalResult>(
        context: context,
        title: shown.animalCodigo.isEmpty
            ? 'Animal'
            : 'Brinco ${shown.animalCodigo}',
        width: 760,
        useInternalScroll: true,
        fullscreenOnMobile: true,
        content: _AnimalEditorModalContent(
          entry: shown,
          iaHistory:
              _iaHistoryByAnimalId[shown.animalId] ?? _AnimalIaHistory.empty,
          hints: _hintsByAnimalId[shown.animalId] ?? const [],
          applyAutomaticCalculations: _applyAutomaticCalculations,
          // Cada mudança vai direto para a visita (e para o aparelho), para
          // não se perder se o sistema fechar o app com o animal aberto.
          onDraftChanged: _updateAnimalEntry,
          progressLabel: '$collected de $total coletados',
          findByCode: (code) {
            final found = _findByCode(code);
            return found == null || found.animalId == shown.animalId
                ? null
                : found;
          },
        ),
      );

      if (!mounted) return;
      final edited = _animalEntries.firstWhere(
        (item) => item.animalId == shown.animalId,
        orElse: () => shown,
      );
      final editedWasReviewed = _reviewedAnimalIds.contains(shown.animalId);
      void restore(VisitAnimalEntryModel value, {required bool reviewed}) {
        if (!mounted) return;
        setState(() {
          _animalEntries = [
            for (final entry in _animalEntries)
              entry.animalId == shown.animalId ? value : entry,
          ];
          _reviewedAnimalIds = reviewed
              ? {..._reviewedAnimalIds, shown.animalId}
              : ({..._reviewedAnimalIds}..remove(shown.animalId));
        });
      }

      final label = shown.animalCodigo.isEmpty
          ? 'do animal'
          : 'do brinco ${shown.animalCodigo}';
      if (result == null) {
        // Voltar do Android, X ou toque fora: mantém o que foi marcado (já
        // aplicado a cada mudança) e oferece desfazer, em vez de perder.
        if (edited != shown) {
          showAppUndo(
            'Alterações $label mantidas.',
            onUndo: () => restore(shown, reviewed: wasReviewed),
          );
        }
        return;
      }
      if (result.discard) {
        restore(shown, reviewed: wasReviewed);
        if (edited != shown) {
          showAppUndo(
            'Mudanças $label descartadas.',
            onUndo: () => restore(edited, reviewed: editedWasReviewed),
          );
        }
        return;
      }
      _updateAnimalEntry(result.entry);
      final nextId = result.nextAnimalId;
      current = nextId == null
          ? null
          : _animalEntries
                .where((item) => item.animalId == nextId)
                .firstOrNull;
    }
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
    AnimalSummaryModel animal, {
    required Map<int, _AnimalIaHistory> iaHistoryByAnimalId,
    required Map<int, DateTime> lastBirthByAnimalId,
  }) {
    final reproductiveStatus = _visitReproductiveStatus(animal);
    final iaHistory = iaHistoryByAnimalId[animal.id] ?? _AnimalIaHistory.empty;
    final iaDates = iaHistory.dates;
    final lastBirthDate =
        lastBirthByAnimalId[animal.id] ?? animal.dataUltimoParto;

    final entry = VisitAnimalEntryModel(
      // Veio do cadastro do aparelho: nada informado ainda nesta visita.
      camposInformados: const [],
      animalId: animal.id,
      animalIdExterno: animal.idExterno,
      animalCodigo: animal.codigo,
      animalCategoria: _resolvedReproductiveStatus(animal).label,
      dataNascimento: animal.dataNascimento,
      dataUltimoParto: lastBirthDate,
      numeroPartos: animal.numeroLactacao > 0 ? animal.numeroLactacao : null,
      situacaoProdutiva: _visitProductiveStatus(
        animal,
        dataUltimoParto: lastBirthDate,
      ),
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

  String? _visitProductiveStatus(
    AnimalSummaryModel animal, {
    required DateTime? dataUltimoParto,
  }) {
    final situacao = animal.situacaoProdutiva;
    if (situacao != null && situacao.isNotEmpty) {
      return situacao;
    }

    final category = _resolvedReproductiveStatus(animal).label.normalize();

    if (category.contains('novilha')) {
      return AnimalProductiveSituation.heifer;
    }

    if (_resolvedReproductiveStatus(animal) == AnimalReproductiveStatus.dry) {
      return AnimalProductiveSituation.dry;
    }

    if (animal.numeroLactacao > 0 || dataUltimoParto != null) {
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
    if (history.contains('bezerra') || history.contains('novilha')) {
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
    if (history.contains('bezerra') || history.contains('novilha')) {
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
    return IndicadorReprodutivoCalculator.applyAutomaticCalculations(
      entry: entry,
      dataAtual: dataAtual,
    );
  }
}

class _HeaderFields extends StatelessWidget {
  const _HeaderFields({
    required this.propertyId,
    required this.properties,
    required this.metodoDg,
    required this.onMetodoDgChanged,
    required this.dataVisitaController,
    required this.onVisitDateChanged,
    required this.onPropertyChanged,
  });

  final int? propertyId;
  final List<PropertySummaryModel> properties;
  final TextEditingController dataVisitaController;
  final ValueChanged<String> onVisitDateChanged;
  final ValueChanged<int?> onPropertyChanged;
  final String metodoDg;
  final ValueChanged<String> onMetodoDgChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFields(),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('DG por'),
            const SizedBox(width: 12),
            Expanded(
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
                segments: [
                  for (final item in metodosDiagnostico.entries)
                    ButtonSegment(value: item.key, label: Text(item.value)),
                ],
                selected: {metodoDg},
                onSelectionChanged: (value) => onMetodoDgChanged(value.first),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFields() {
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
    this.onSaveDraft,
  });

  final bool isBusy;
  final bool isLoadingAnimals;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  /// Só informado no mobile (rascunho local).
  final VoidCallback? onSaveDraft;

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
                    if (onSaveDraft != null)
                      AppButton(
                        text: 'Salvar rascunho',
                        outlined: true,
                        height: 40,
                        onPressed: isLoadingAnimals || isBusy
                            ? null
                            : onSaveDraft,
                      ),
                    AppButton(
                      text: onSaveDraft != null
                          ? 'Finalizar visita'
                          : 'Salvar visita',
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
    required this.hintsByAnimalId,
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
  final Map<int, List<VisitActionHint>> hintsByAnimalId;
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
          hintsByAnimalId: widget.hintsByAnimalId,
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
            hints: widget.selectedEntry == null
                ? const []
                : widget.hintsByAnimalId[widget.selectedEntry!.animalId] ??
                      const [],
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
    required this.hintsByAnimalId,
    required this.reviewedAnimalIds,
    required this.selectedAnimalId,
    this.height,
    this.onSelectAnimal,
    this.onOpenAnimal,
  });

  final List<VisitAnimalEntryModel> entries;
  final Map<int, List<VisitActionHint>> hintsByAnimalId;
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
  bool _onlyActions = false;

  // Brinco costuma ser número: teclado numérico, com troca para letras.
  bool _numericKeyboard = true;

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
                hints: widget.hintsByAnimalId[entry.animalId] ?? const [],
                onTap: () => _open(entry),
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
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    // A troca de teclado só vale ao recriar o campo.
                    key: ValueKey('visit-search-$_numericKeyboard'),
                    controller: _searchController,
                    label: 'Buscar brinco',
                    hint: 'Digite o brinco e toque em ir',
                    clearable: true,
                    keyboardType: _numericKeyboard
                        ? TextInputType.number
                        : TextInputType.text,
                    textInputAction: TextInputAction.go,
                    onSubmitted: _openSearchResult,
                    prefixIcon: const Icon(Icons.search_outlined),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: _numericKeyboard
                      ? 'Usar teclado com letras'
                      : 'Usar teclado numérico',
                  onPressed: () =>
                      setState(() => _numericKeyboard = !_numericKeyboard),
                  icon: Icon(
                    _numericKeyboard
                        ? Icons.abc_rounded
                        : Icons.dialpad_rounded,
                  ),
                ),
              ],
            ),
          ),
          if (_actionTotal > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  selected: _onlyActions,
                  onSelected: (value) => setState(() => _onlyActions = value),
                  avatar: _onlyActions
                      ? null
                      : const Icon(Icons.priority_high_rounded, size: 18),
                  label: Text('Só quem precisa de ação ($_actionTotal)'),
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

  int get _actionTotal => widget.entries
      .where(
        (entry) => widget.hintsByAnimalId[entry.animalId]?.isNotEmpty == true,
      )
      .length;

  void _open(VisitAnimalEntryModel entry) {
    if (widget.onOpenAnimal != null) {
      widget.onOpenAnimal!(entry);
      return;
    }
    widget.onSelectAnimal?.call(entry.animalId);
  }

  /// "Ir" no teclado: abre o brinco exato digitado, ou o único encontrado.
  void _openSearchResult(String value) {
    final query = value.trim().normalize();
    if (query.isEmpty) return;
    final exact = widget.entries.where(
      (entry) => entry.animalCodigo.trim().normalize() == query,
    );
    final visible = _visibleEntries;
    final target = exact.isNotEmpty
        ? exact.first
        : visible.length == 1
        ? visible.first
        : null;
    if (target == null) return;
    _searchController.clear();
    _open(target);
  }

  List<VisitAnimalEntryModel> get _visibleEntries {
    final query = _searchTerm.trim().normalize();
    final base = _onlyActions
        ? widget.entries
              .where(
                (entry) =>
                    widget.hintsByAnimalId[entry.animalId]?.isNotEmpty == true,
              )
              .toList(growable: false)
        : widget.entries;
    if (query.isEmpty) {
      return base;
    }

    return base
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
      return 'Toque para preencher';
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
    required this.hints,
    required this.onTap,
  });

  final VisitAnimalEntryModel entry;
  final bool selected;
  final bool reviewed;
  final String subtitle;
  final List<VisitActionHint> hints;
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
                          if (_listKeyNumbers(entry).isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _listKeyNumbers(entry),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (hints.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _ActionHints(hints: hints),
                          ],
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

/// "DEL 145 d · IA 29/09/2026 · Prenhez 100 d", sem os que não se aplicam.
String _listKeyNumbers(VisitAnimalEntryModel entry) {
  return _visitKeyNumbers(entry)
      .where((number) => number.value != '--')
      .map(
        (number) => number.label == 'Última IA'
            ? 'IA ${number.value}'
            : '${number.label} ${number.value}',
      )
      .join(' · ');
}

class _AnimalEditorPane extends StatelessWidget {
  const _AnimalEditorPane({
    required this.entry,
    required this.hints,
    required this.iaHistory,
    required this.onChanged,
    required this.applyAutomaticCalculations,
    required this.onConfirmAnimal,
    required this.reviewed,
  });

  final VisitAnimalEntryModel? entry;
  final List<VisitActionHint> hints;
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
          if (hints.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ActionHints(hints: hints),
          ],
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

    // Mudar qualquer campo já marca a coleta; o botão confirma o animal sem
    // mudanças (ex.: situação conferida). O próximo é escolhido pelo brinco.
    return AppButton(
      text: reviewed ? 'Animal confirmado' : 'Confirmar animal',
      height: 48,
      icon: Icon(
        reviewed ? Icons.check_circle : Icons.check_rounded,
        size: 18,
        color: colorScheme.onPrimary,
      ),
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
              reviewed ? 'Coletado' : 'Sem coleta',
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
    final visitIaDateField = AppDateField(
      key: ValueKey('visit-ia-date-${entry.animalId}-$hasVisitIa-$visitIaDate'),
      label: 'Data da nova IA',
      value: visitIaDate,
      showToday: true,
      onChanged: (value) => emitChanged(
        _entryWithVisitIaDate(entry: entry, iaHistory: iaHistory, value: value),
      ),
    );
    final hasDetails =
        entry.diagnostico?.isNotEmpty == true ||
        entry.dataSecagemEfetiva != null ||
        entry.entradaPreParto != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReproductiveStatusPicker(
          value: entry.situacaoReprodutiva,
          onChanged: (value) =>
              emitChanged(withReproductiveStatus(entry, value)),
        ),
        if (AnimalReproductiveStatus.fromApiValue(entry.situacaoReprodutiva) ==
            AnimalReproductiveStatus.empty) ...[
          const SizedBox(height: 12),
          _GestationalLossSection(entry: entry, onChanged: emitChanged),
        ],
        const SizedBox(height: 14),
        _CalculatedSummary(entry: entry, iaHistory: iaHistory),
        const SizedBox(height: 14),
        ResponsiveFieldGrid(
          children: [
            AppDropdown<String>(
              value: entry.situacaoProdutiva,
              labelText: 'Situação produtiva',
              onChanged: (value) =>
                  emitChanged(entry.copyWith(situacaoProdutiva: value)),
              options: _VisitFormPageState._situacaoProdutivaOptions,
            ),
            visitIaDateField,
            AppDateField(
              label: 'Data último parto',
              value: entry.dataUltimoParto,
              showToday: true,
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
          ],
        ),
        const SizedBox(height: 8),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey('visit-details-${entry.animalId}'),
            initiallyExpanded: hasDetails,
            maintainState: true,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 4, bottom: 8),
            title: const Text('Mais detalhes'),
            subtitle: const Text('Diagnóstico, nº da IA, secagem, pré-parto'),
            children: [
              ResponsiveFieldGrid(
                children: [
                  AppTextField(
                    label: 'Diagnóstico',
                    initialValue: entry.diagnostico ?? '',
                    onChanged: (value) => emitChanged(
                      entry.copyWith(
                        diagnostico: value.trim().isEmpty ? null : value.trim(),
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
                  AppDateField(
                    label: 'Secagem efetiva',
                    value: entry.dataSecagemEfetiva,
                    onChanged: (value) => emitChanged(
                      entry.copyWith(
                        dataSecagemEfetiva: value,
                        situacaoProdutiva:
                            AnimalProductiveSituation.afterDryOff(
                              entry.situacaoProdutiva,
                              value,
                            ),
                      ),
                    ),
                  ),
                  AppDateField(
                    label: 'Entrada pré-parto',
                    value: entry.entradaPreParto,
                    onChanged: (value) =>
                        emitChanged(entry.copyWith(entradaPreParto: value)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatInt(int? value) => value?.toString() ?? '';
}

class _AnimalEditorModalContent extends StatefulWidget {
  const _AnimalEditorModalContent({
    required this.entry,
    required this.iaHistory,
    required this.hints,
    required this.applyAutomaticCalculations,
    required this.onDraftChanged,
    required this.progressLabel,
    required this.findByCode,
  });

  final VisitAnimalEntryModel entry;
  final _AnimalIaHistory iaHistory;
  final List<VisitActionHint> hints;
  final _VisitEntryCalculator applyAutomaticCalculations;
  final ValueChanged<VisitAnimalEntryModel> onDraftChanged;
  final String progressLabel;

  /// Animal da visita com o brinco digitado (nulo se não achar ou se é o
  /// mesmo que está aberto).
  final VisitAnimalEntryModel? Function(String code) findByCode;

  @override
  State<_AnimalEditorModalContent> createState() =>
      _AnimalEditorModalContentState();
}

class _AnimalEditorModalContentState extends State<_AnimalEditorModalContent> {
  late VisitAnimalEntryModel _draft;
  final _nextCode = TextEditingController();
  String? _nextError;

  @override
  void dispose() {
    _nextCode.dispose();
    super.dispose();
  }

  void _finish() => Navigator.of(context).pop(_ModalResult(_draft));

  void _openNext() {
    final code = _nextCode.text.trim();
    if (code.isEmpty) return;
    final next = widget.findByCode(code);
    if (next == null) {
      setState(() => _nextError = 'Brinco $code não encontrado nesta visita');
      return;
    }
    Navigator.of(
      context,
    ).pop(_ModalResult(_draft, nextAnimalId: next.animalId));
  }

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
          '${widget.progressLabel} · cada mudança já fica salva.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (widget.hints.isNotEmpty) ...[
          const SizedBox(height: 10),
          _ActionHints(hints: widget.hints),
        ],
        const SizedBox(height: 16),
        _AnimalEditorFields(
          entry: _draft,
          iaHistory: widget.iaHistory,
          applyAutomaticCalculations: widget.applyAutomaticCalculations,
          onChanged: (value) {
            setState(() => _draft = widget.applyAutomaticCalculations(value));
            widget.onDraftChanged(_draft);
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Próximo brinco',
          hint: 'Digite o brinco da vaca que entrou',
          controller: _nextCode,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.go,
          onChanged: (_) {
            if (_nextError != null) setState(() => _nextError = null);
          },
          onSubmitted: (_) => _openNext(),
          suffixIcon: IconButton(
            tooltip: 'Abrir brinco',
            icon: const Icon(Icons.arrow_forward_rounded),
            onPressed: _openNext,
          ),
        ),
        if (_nextError != null) ...[
          const SizedBox(height: 4),
          Text(
            _nextError!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 12),
        AppButton(
          text: 'Concluir animal',
          height: 52,
          expanded: true,
          onPressed: _finish,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.center,
          child: TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(_ModalResult(_draft, discard: true)),
            child: const Text('Descartar mudanças deste animal'),
          ),
        ),
      ],
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

/// Resultado do modal do animal no mobile: o que foi preenchido e para onde ir
/// (-1 anterior, 0 fechar, 1 próximo).
/// Perda gestacional da vaca vista vazia. Vem pré-marcada quando ela estava
/// prenha (reabsorção até 45 dias de gestação, aborto depois).
class _GestationalLossSection extends StatelessWidget {
  const _GestationalLossSection({required this.entry, required this.onChanged});

  final VisitAnimalEntryModel entry;
  final ValueChanged<VisitAnimalEntryModel> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = entry.tipoPerda;
    Widget chip(String? value, String label) => ChoiceChip(
      label: Text(label),
      selected: selected == value,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      onSelected: (_) => onChanged(
        entry.copyWith(
          tipoPerda: value,
          causaPerda: value == null ? null : entry.causaPerda,
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Perda gestacional', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              chip(null, 'Não houve perda'),
              for (final item in gestationalLossTypes.entries)
                chip(item.key, item.value),
            ],
          ),
          if (selected != null) ...[
            const SizedBox(height: 8),
            AppTextField(
              label: 'Causa suspeita (opcional)',
              initialValue: entry.causaPerda ?? '',
              onChanged: (value) => onChanged(
                entry.copyWith(
                  causaPerda: value.trim().isEmpty ? null : value.trim(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModalResult {
  const _ModalResult(this.entry, {this.nextAnimalId, this.discard = false});

  final VisitAnimalEntryModel entry;

  /// Brinco digitado em "Próximo brinco": abre esse animal em seguida.
  final int? nextAnimalId;

  /// Tocou em "Descartar mudanças deste animal" (o voltar mantém).
  final bool discard;
}

/// Números calculados em uma linha, em vez de campos somente leitura.
class _CalculatedSummary extends StatelessWidget {
  const _CalculatedSummary({required this.entry, required this.iaHistory});

  final VisitAnimalEntryModel entry;
  final _AnimalIaHistory iaHistory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = <String>[
      if (entry.diasParaSecar != null)
        entry.diasParaSecar! < 0
            ? 'Secagem atrasada ${-entry.diasParaSecar!} d'
            : 'Secar em ${entry.diasParaSecar} d',
      if (entry.previsaoParto != null)
        'Parto ${formatDateInput(entry.previsaoParto)}',
      if (entry.idadeMeses != null)
        'Idade ${entry.idadeMeses!.toStringAsFixed(0)} meses',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final (index, number) in _visitKeyNumbers(
              entry,
              ultimaIa: iaHistory.lastDate,
            ).indexed) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(child: _KeyNumberTile(number: number)),
            ],
          ],
        ),
        if (secondary.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            secondary.join('  ·  '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Os três números que o veterinário confere em toda vaca.
typedef _KeyNumber = ({String label, String value});

List<_KeyNumber> _visitKeyNumbers(
  VisitAnimalEntryModel entry, {
  DateTime? ultimaIa,
}) {
  final ia = ultimaIa ?? entry.dataUltimaIa;
  final dias = entry.diasPrenhez;
  final prenha =
      AnimalReproductiveStatus.fromApiValue(entry.situacaoReprodutiva) ==
      AnimalReproductiveStatus.pregnant;
  return [
    (label: 'DEL', value: entry.del == null ? '--' : '${entry.del} d'),
    (label: 'Última IA', value: ia == null ? '--' : formatDateInput(ia)),
    // Inseminada sem DG ainda não é prenhez: "Pós-IA" para não confundir.
    (
      label: prenha || dias == null ? 'Prenhez' : 'Pós-IA',
      value: dias == null ? '--' : '$dias d',
    ),
  ];
}

class _KeyNumberTile extends StatelessWidget {
  const _KeyNumberTile({required this.number});

  final _KeyNumber number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              number.value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avisos do "o que fazer hoje" (ex.: "Fazer DG · IA há 35 dias").
class _ActionHints extends StatelessWidget {
  const _ActionHints({required this.hints});

  final List<VisitActionHint> hints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final hint in hints)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hint.urgent
                  ? colorScheme.errorContainer
                  : colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              hint.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: hint.urgent
                    ? colorScheme.onErrorContainer
                    : colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _ResumedNotice extends StatelessWidget {
  const _ResumedNotice({required this.onStartOver});

  final VoidCallback onStartOver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history_rounded,
            size: 18,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Continuando a visita que ficou aberta.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onStartOver,
            child: const Text('Começar outra'),
          ),
        ],
      ),
    );
  }
}
