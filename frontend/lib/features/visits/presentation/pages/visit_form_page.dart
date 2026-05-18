import 'package:cysvet_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/enums/animal_status.dart';
import '../../../../core/presentation/app_scaffold_messenger.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../animals/data/animals_repository.dart';
import '../../../animals/domain/animal_summary_model.dart';
import '../../../properties/application/properties_provider.dart';
import '../../../properties/domain/property_summary_model.dart';
import '../../application/visits_provider.dart';
import '../../domain/visit_summary_model.dart';

class VisitFormPage extends ConsumerStatefulWidget {
  const VisitFormPage({super.key, this.initialPropertyId});

  final int? initialPropertyId;

  @override
  ConsumerState<VisitFormPage> createState() => _VisitFormPageState();
}

class _VisitFormPageState extends ConsumerState<VisitFormPage> {
  static const _situacaoProdutivaOptions = [
    AppDropdownOption<String>(label: 'Nao informado', value: null),
    AppDropdownOption<String>(label: 'Lactante', value: 'lactante'),
    AppDropdownOption<String>(label: 'Seca', value: 'seca'),
    AppDropdownOption<String>(label: 'Novilha', value: 'novilha'),
  ];

  static const _situacaoReprodutivaOptions = [
    AppDropdownOption<String>(label: 'Nao informado', value: null),
    AppDropdownOption<String>(label: 'Prenha', value: 'prenha'),
    AppDropdownOption<String>(label: 'Inseminada', value: 'inseminada'),
    AppDropdownOption<String>(label: 'Vazia', value: 'vazia'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _dataVisita = TextEditingController();
  final _observacoes = TextEditingController();

  int? _propertyId;
  int? _loadedPropertyId;
  int? _selectedAnimalId;
  bool _isLoadingAnimals = false;
  String? _animalsError;
  List<VisitAnimalEntryModel> _animalEntries = const [];
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
    _observacoes.dispose();
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outline),
            ),
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
                  'Vincule a propriedade e depois selecione um brinco na lista para preencher a coleta do animal.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _HeaderFields(
                  propertyId: _propertyId,
                  properties: properties,
                  dataVisitaController: _dataVisita,
                  observacoesController: _observacoes,
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
                      icon: Icons.pets_outlined,
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
            _FeedbackPanel(
              message: _animalsError!,
              error: true,
            )
          else if (_propertyId == null)
            const _FeedbackPanel(
              message: 'Selecione a propriedade para carregar a lista de animais.',
            )
          else if (_animalEntries.isEmpty)
            const _FeedbackPanel(
              message: 'Nenhum animal encontrado para a propriedade selecionada.',
            )
          else
            _AnimalCollectionLayout(
              entries: _animalEntries,
              reviewedAnimalIds: _reviewedAnimalIds,
              selectedAnimalId: _selectedAnimalId,
              selectedEntry: selectedEntry,
              onSelectAnimal: (animalId) {
                setState(() {
                  _selectedAnimalId = animalId;
                });
              },
              onChanged: _updateAnimalEntry,
              onConfirmAnimal: _confirmAnimal,
              onOpenAnimal: _editAnimalInModal,
            ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              AppButton(
                text: 'Cancelar',
                outlined: true,
                height: 40,
                onPressed: isBusy ? null : () => context.go('/visitas'),
              ),
              AppButton(
                text: 'Salvar visita',
                height: 40,
                loading: isBusy,
                onPressed: _isLoadingAnimals || isBusy ? null : _saveVisit,
              ),
            ],
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
      if (!mounted) {
        return;
      }

      final entries = animals
          .map(_entryFromAnimal)
          .toList(growable: false);
      setState(() {
        _loadedPropertyId = propertyId;
        _animalEntries = entries;
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
        observacoes: _observacoes.text.trim(),
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
    _reviewedAnimalIds = const {};
  }

  void _updateAnimalEntry(VisitAnimalEntryModel updated) {
    setState(() {
      _animalEntries = _animalEntries.map((entry) {
        if (entry.animalId == updated.animalId) {
          return updated;
        }
        return entry;
      }).toList(growable: false);
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
      title: entry.animalCodigo.isEmpty ? 'Animal' : 'Brinco ${entry.animalCodigo}',
      width: 760,
      useInternalScroll: true,
      fullscreenOnMobile: true,
      content: _AnimalEditorModalContent(entry: entry),
    );

    if (!mounted || updated == null) {
      return;
    }

    _updateAnimalEntry(updated);
    _confirmAnimal(updated.animalId);
  }

  PropertySummaryModel? _selectedProperty(List<PropertySummaryModel> properties) {
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

  VisitAnimalEntryModel _entryFromAnimal(AnimalSummaryModel animal) {
    final reproductiveStatus = _visitReproductiveStatus(animal);

    return VisitAnimalEntryModel(
      animalId: animal.id,
      animalIdExterno: animal.idExterno,
      animalCodigo: animal.codigo,
      animalCategoria: animal.categoria,
      idadeMeses: _ageInMonths(animal.dataNascimento),
      situacaoProdutiva: _visitProductiveStatus(animal),
      situacaoReprodutiva: reproductiveStatus,
      diagnostico: animal.historicoReprodutivo?.trim().isEmpty == true
          ? null
          : animal.historicoReprodutivo?.trim(),
      del: animal.diasEmLactacao,
    );
  }

  String? _visitProductiveStatus(AnimalSummaryModel animal) {
    final category = animal.categoria.normalize();

    if (category.contains('novilha')) {
      return 'novilha';
    }

    if (_resolvedReproductiveStatus(animal) == AnimalReproductiveStatus.dry) {
      return 'seca';
    }

    if (animal.numeroLactacao > 0 || animal.diasEmLactacao != null) {
      return 'lactante';
    }

    return null;
  }

  String? _visitReproductiveStatus(AnimalSummaryModel animal) {
    final resolved = _resolvedReproductiveStatus(animal);

    switch (resolved) {
      case AnimalReproductiveStatus.pregnant:
        return 'prenha';
      case AnimalReproductiveStatus.empty:
        return 'vazia';
      case AnimalReproductiveStatus.inseminated:
        return 'inseminada';
      case AnimalReproductiveStatus.pending:
        final history = (animal.historicoReprodutivo ?? '').normalize();
        if (history.contains('aguardando dg')) {
          return 'aguardando dg';
        }
        if (history.contains('pev')) {
          return 'pev';
        }
        if (history.contains('liberad')) {
          return 'liberada';
        }
        if (history.contains('descarte')) {
          return 'descarte';
        }
        return null;
      case AnimalReproductiveStatus.dry:
        return null;
    }
  }

  AnimalReproductiveStatus _resolvedReproductiveStatus(
    AnimalSummaryModel animal,
  ) {
    final savedStatus = animal.statusReprodutivo;
    if (savedStatus != null) {
      return savedStatus;
    }

    final history = (animal.historicoReprodutivo ?? '').normalize();

    if (history.contains('pren') || history.contains('confirm')) {
      return AnimalReproductiveStatus.pregnant;
    }
    if (history.contains('insemin')) {
      return AnimalReproductiveStatus.inseminated;
    }
    if (history.contains('seca') || history.contains('dry')) {
      return AnimalReproductiveStatus.dry;
    }
    if (history.contains('vazia') ||
        history.contains('empty') ||
        history.contains('negativ') ||
        history.contains('toque')) {
      return AnimalReproductiveStatus.empty;
    }

    return AnimalReproductiveStatus.pending;
  }

  int? _ageInMonths(DateTime? birthDate) {
    if (birthDate == null) {
      return null;
    }

    final now = DateTime.now();
    var months =
        (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
    if (now.day < birthDate.day) {
      months -= 1;
    }
    return months < 0 ? 0 : months;
  }
}

class _HeaderFields extends StatelessWidget {
  const _HeaderFields({
    required this.propertyId,
    required this.properties,
    required this.dataVisitaController,
    required this.observacoesController,
    required this.onPropertyChanged,
  });

  final int? propertyId;
  final List<PropertySummaryModel> properties;
  final TextEditingController dataVisitaController;
  final TextEditingController observacoesController;
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
                  (property) =>
                      AppDropdownOption(label: property.nome, value: property.id),
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
            validator: (value) {
              if (parseDateInput(value ?? '') == null) {
                return 'Informe uma data valida';
              }
              return null;
            },
          ),
          AppTextField(
            label: 'Observacoes gerais',
            controller: observacoesController,
            maxLines: 3,
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
            const SizedBox(width: 12),
            Expanded(child: fields[2]),
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

class _AnimalCollectionLayout extends StatelessWidget {
  const _AnimalCollectionLayout({
    required this.entries,
    required this.reviewedAnimalIds,
    required this.selectedAnimalId,
    required this.selectedEntry,
    required this.onSelectAnimal,
    required this.onChanged,
    required this.onConfirmAnimal,
    required this.onOpenAnimal,
  });

  final List<VisitAnimalEntryModel> entries;
  final Set<int> reviewedAnimalIds;
  final int? selectedAnimalId;
  final VisitAnimalEntryModel? selectedEntry;
  final ValueChanged<int> onSelectAnimal;
  final ValueChanged<VisitAnimalEntryModel> onChanged;
  final ValueChanged<int> onConfirmAnimal;
  final ValueChanged<VisitAnimalEntryModel> onOpenAnimal;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 920;
        final listPane = _AnimalListPane(
          entries: entries,
          reviewedAnimalIds: reviewedAnimalIds,
          selectedAnimalId: selectedAnimalId,
          onSelectAnimal: stacked ? null : onSelectAnimal,
          onOpenAnimal: stacked ? onOpenAnimal : null,
        );
        final editorPane = _AnimalEditorPane(
          entry: selectedEntry,
          onChanged: onChanged,
          onConfirmAnimal: onConfirmAnimal,
          reviewed: selectedEntry != null &&
              reviewedAnimalIds.contains(selectedEntry!.animalId),
        );

        if (stacked) {
          return listPane;
        }

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
}

class _AnimalListPane extends StatelessWidget {
  const _AnimalListPane({
    required this.entries,
    required this.reviewedAnimalIds,
    required this.selectedAnimalId,
    this.onSelectAnimal,
    this.onOpenAnimal,
  });

  final List<VisitAnimalEntryModel> entries;
  final Set<int> reviewedAnimalIds;
  final int? selectedAnimalId;
  final ValueChanged<int>? onSelectAnimal;
  final ValueChanged<VisitAnimalEntryModel>? onOpenAnimal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Text(
              'Brincos',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 480,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: entries.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final selected = entry.animalId == selectedAnimalId ||
                    (selectedAnimalId == null && index == 0);

                return ListTile(
                  selected: selected,
                  selectedTileColor:
                      colorScheme.primaryContainer.withValues(alpha: 0.45),
                  title: Text(
                    entry.animalCodigo.isEmpty
                        ? 'Sem brinco'
                        : entry.animalCodigo,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    _buildSubtitle(entry),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: reviewedAnimalIds.contains(entry.animalId)
                      ? Icon(
                          Icons.check_circle,
                          size: 18,
                          color: colorScheme.primary,
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: () {
                    if (onOpenAnimal != null) {
                      onOpenAnimal!(entry);
                      return;
                    }
                    onSelectAnimal?.call(entry.animalId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle(VisitAnimalEntryModel entry) {
    final parts = <String>[
      if (entry.situacaoProdutiva?.isNotEmpty == true)
        entry.situacaoProdutiva!,
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

class _AnimalEditorPane extends StatelessWidget {
  const _AnimalEditorPane({
    required this.entry,
    required this.onChanged,
    required this.onConfirmAnimal,
    required this.reviewed,
  });

  final VisitAnimalEntryModel? entry;
  final ValueChanged<VisitAnimalEntryModel> onChanged;
  final ValueChanged<int> onConfirmAnimal;
  final bool reviewed;

  @override
  Widget build(BuildContext context) {
    if (entry == null) {
      return const _FeedbackPanel(
        message: 'Selecione um animal na lista para editar os dados da visita.',
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      key: ValueKey(entry!.animalId),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            entry!.animalCodigo.isEmpty ? 'Animal sem brinco' : entry!.animalCodigo,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const SizedBox(height: 16),
          _AnimalEditorFields(
            entry: entry!,
            onChanged: onChanged,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              if (reviewed)
                Text(
                  'Animal confirmado na visita',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              AppButton(
                text: reviewed ? 'Atualizar confirmacao' : 'Confirmar animal',
                height: 40,
                onPressed: () => onConfirmAnimal(entry!.animalId),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimalEditorFields extends StatelessWidget {
  const _AnimalEditorFields({
    required this.entry,
    required this.onChanged,
  });

  final VisitAnimalEntryModel entry;
  final ValueChanged<VisitAnimalEntryModel> onChanged;

  @override
  Widget build(BuildContext context) {
    return _EditorGrid(
      children: [
        AppDropdown<String>(
          value: entry.situacaoProdutiva,
          labelText: 'Situacao produtiva',
          onChanged: (value) =>
              onChanged(entry.copyWith(situacaoProdutiva: value)),
          options: _VisitFormPageState._situacaoProdutivaOptions,
        ),
        AppDropdown<String>(
          value: entry.situacaoReprodutiva,
          labelText: 'Situacao reprodutiva',
          onChanged: (value) =>
              onChanged(entry.copyWith(situacaoReprodutiva: value)),
          options: _VisitFormPageState._situacaoReprodutivaOptions,
        ),
        AppTextField(
          label: 'Decisão',
          initialValue: entry.decisao ?? '',
          onChanged: (value) => onChanged(
            entry.copyWith(
              decisao: value.trim().isEmpty ? null : value.trim(),
            ),
          ),
        ),
        AppTextField(
          label: 'Diagnóstico / Histórico',
          initialValue: entry.diagnostico ?? '',
          maxLines: 2,
          onChanged: (value) => onChanged(
            entry.copyWith(
              diagnostico: value.trim().isEmpty ? null : value.trim(),
            ),
          ),
        ),
        _DateInputField(
          label: 'Data ultima IA',
          value: entry.dataUltimaIa,
          onChanged: (value) =>
              onChanged(entry.copyWith(dataUltimaIa: value)),
        ),
        AppTextField(
          label: 'No IA recebida',
          initialValue: _formatInt(entry.numeroIaRecebida),
          keyboardType: TextInputType.number,
          onChanged: (value) => onChanged(
            entry.copyWith(numeroIaRecebida: _parseInt(value)),
          ),
        ),
        AppTextField(
          label: 'Dias prenhez',
          initialValue: _formatInt(entry.diasPrenhez),
          keyboardType: TextInputType.number,
          onChanged: (value) => onChanged(
            entry.copyWith(diasPrenhez: _parseInt(value)),
          ),
        ),
        AppTextField(
          label: 'DEL',
          initialValue: _formatInt(entry.del),
          keyboardType: TextInputType.number,
          onChanged: (value) => onChanged(entry.copyWith(del: _parseInt(value))),
        ),
        AppTextField(
          label: 'Dias p/ secar',
          initialValue: _formatInt(entry.diasParaSecar),
          keyboardType: TextInputType.number,
          onChanged: (value) => onChanged(
            entry.copyWith(diasParaSecar: _parseInt(value)),
          ),
        ),
        _DateInputField(
          label: 'Previsao secagem',
          value: entry.previsaoSecagem,
          onChanged: (value) =>
              onChanged(entry.copyWith(previsaoSecagem: value)),
        ),
        _DateInputField(
          label: 'Data pre-parto',
          value: entry.dataPreParto,
          onChanged: (value) =>
              onChanged(entry.copyWith(dataPreParto: value)),
        ),
        _DateInputField(
          label: 'Previsao parto',
          value: entry.previsaoParto,
          onChanged: (value) =>
              onChanged(entry.copyWith(previsaoParto: value)),
        ),
      ],
    );
  }

  static String _formatInt(int? value) => value?.toString() ?? '';

  static int? _parseInt(String value) => int.tryParse(value.trim());
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
  const _AnimalEditorModalContent({required this.entry});

  final VisitAnimalEntryModel entry;

  @override
  State<_AnimalEditorModalContent> createState() =>
      _AnimalEditorModalContentState();
}

class _AnimalEditorModalContentState extends State<_AnimalEditorModalContent> {
  late VisitAnimalEntryModel _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.entry;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Preencha e confirme os dados deste animal para marcar a coleta.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        _AnimalEditorFields(
          entry: _draft,
          onChanged: (value) => setState(() {
            _draft = value;
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
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      hint: 'DD/MM/AAAA',
      initialValue: formatDateInput(value),
      keyboardType: TextInputType.number,
      inputFormatters: const [DateInputFormatter()],
      onChanged: (text) => onChanged(parseDateInput(text)),
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({
    required this.message,
    this.error = false,
  });

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
  const _SummaryChip({
    required this.icon,
    required this.label,
  });

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
