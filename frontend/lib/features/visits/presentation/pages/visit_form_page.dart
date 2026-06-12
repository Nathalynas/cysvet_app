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
      if (!mounted) {
        return;
      }

      final entries = animals.map(_entryFromAnimal).toList(growable: false);
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
      _animalEntries = _animalEntries
          .map((entry) {
            if (entry.animalId == updated.animalId) {
              return updated;
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
      content: _AnimalEditorModalContent(entry: entry),
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
            validator: (value) {
              if (parseDateInput(value ?? '') == null) {
                return 'Informe uma data válida';
              }
              return null;
            },
          ),
          AppTextField(
            label: 'Observações gerais',
            controller: observacoesController,
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
            onChanged: widget.onChanged,
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
          _AnimalEditorFields(entry: selectedEntry, onChanged: onChanged),
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
  const _AnimalEditorFields({required this.entry, required this.onChanged});

  final VisitAnimalEntryModel entry;
  final ValueChanged<VisitAnimalEntryModel> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EditorSection(
          title: 'Informações reprodutivas',
          child: _EditorGrid(
            children: [
              AppDropdown<String>(
                value: entry.situacaoProdutiva,
                labelText: 'Situação produtiva',
                onChanged: (value) =>
                    onChanged(entry.copyWith(situacaoProdutiva: value)),
                options: _VisitFormPageState._situacaoProdutivaOptions,
              ),
              AppDropdown<String>(
                value: entry.situacaoReprodutiva,
                labelText: 'Situação reprodutiva',
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
            ],
          ),
        ),
        const SizedBox(height: 22),
        _EditorSection(
          title: 'Diagnóstico',
          child: AppTextField(
            label: 'Diagnóstico / Histórico',
            initialValue: entry.diagnostico ?? '',
            onChanged: (value) => onChanged(
              entry.copyWith(
                diagnostico: value.trim().isEmpty ? null : value.trim(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        _EditorSection(
          title: 'Inseminação e parto',
          child: _EditorGrid(
            children: [
              _DateInputField(
                label: 'Data da última IA',
                value: entry.dataUltimaIa,
                onChanged: (value) =>
                    onChanged(entry.copyWith(dataUltimaIa: value)),
              ),
              AppTextField(
                label: 'Número da IA recebida',
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
                onChanged: (value) =>
                    onChanged(entry.copyWith(diasPrenhez: _parseInt(value))),
              ),
              AppTextField(
                label: 'DEL',
                initialValue: _formatInt(entry.del),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    onChanged(entry.copyWith(del: _parseInt(value))),
              ),
              AppTextField(
                label: 'Dias p/ secar',
                initialValue: _formatInt(entry.diasParaSecar),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    onChanged(entry.copyWith(diasParaSecar: _parseInt(value))),
              ),
              _DateInputField(
                label: 'Previsão secagem',
                value: entry.previsaoSecagem,
                onChanged: (value) =>
                    onChanged(entry.copyWith(previsaoSecagem: value)),
              ),
              _DateInputField(
                label: 'Data pré-parto',
                value: entry.dataPreParto,
                onChanged: (value) =>
                    onChanged(entry.copyWith(dataPreParto: value)),
              ),
              _DateInputField(
                label: 'Previsão parto',
                value: entry.previsaoParto,
                onChanged: (value) =>
                    onChanged(entry.copyWith(previsaoParto: value)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatInt(int? value) => value?.toString() ?? '';

  static int? _parseInt(String value) => int.tryParse(value.trim());
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
