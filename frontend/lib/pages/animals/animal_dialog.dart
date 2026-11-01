import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:cysvet_app/core/constants/app_constants.dart';
import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/core/presentation/app_scaffold_messenger.dart';
import 'package:cysvet_app/core/widgets/app_date_field.dart';
import 'package:cysvet_app/core/widgets/app_dialog.dart';
import 'package:cysvet_app/core/widgets/app_dropdown.dart';
import 'package:cysvet_app/core/widgets/app_form.dart';
import 'package:cysvet_app/core/widgets/app_text_field.dart';
import 'package:cysvet_app/core/widgets/reproductive_status_picker.dart';
import 'package:cysvet_app/core/widgets/responsive_field_grid.dart';
import 'package:cysvet_app/filters/animal_filter.dart';
import 'package:cysvet_app/models/property_summary_model.dart';
import 'package:cysvet_app/providers/animals_provider.dart';
import 'package:cysvet_app/models/animal_import_field.dart';
import 'package:cysvet_app/models/animal_summary_model.dart';

class AnimalDialog extends StatelessWidget {
  const AnimalDialog({super.key, required this.properties, this.animal});

  final List<PropertySummaryModel> properties;
  final AnimalSummaryModel? animal;

  static Future<void> show(
    BuildContext context, {
    required List<PropertySummaryModel> properties,
    AnimalSummaryModel? animal,
  }) {
    return AppDialog.show<void>(
      context: context,
      title: animal == null ? 'Novo animal' : 'Editar animal ${animal.codigo}',
      width: 760,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      fullscreenBodyPadding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      headerIndent: 16,
      useInternalScroll: true,
      fullscreenOnMobile: true,
      content: AnimalDialog(animal: animal, properties: properties),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AnimalForm(animal: animal, properties: properties);
  }
}

class _AnimalForm extends ConsumerStatefulWidget {
  const _AnimalForm({required this.properties, this.animal});

  final List<PropertySummaryModel> properties;
  final AnimalSummaryModel? animal;

  @override
  ConsumerState<_AnimalForm> createState() => _AnimalFormState();
}

class _AnimalFormState extends ConsumerState<_AnimalForm> {
  final _codigo = TextEditingController();
  final _lactacao = TextEditingController();
  final _touroIa = TextEditingController();
  final _historico = TextEditingController();

  int? _propertyId;
  DateTime? _nascimento;
  DateTime? _parto;
  DateTime? _inseminacao;
  AnimalReproductiveStatus _reproductiveStatus =
      AnimalReproductiveStatus.pending;
  String? _productiveSituation;

  @override
  void initState() {
    super.initState();

    final animal = widget.animal;

    _codigo.text = animal?.codigo ?? '';
    _lactacao.text = (animal?.numeroLactacao ?? 0).toString();
    _touroIa.text = animal?.touroIa ?? '';
    _historico.text = animal?.historicoReprodutivo ?? '';
    _nascimento = animal?.dataNascimento;
    _parto = animal?.dataUltimoParto;
    _inseminacao = animal?.dataInseminacao;
    _propertyId = animal?.idPropriedade ?? _defaultPropertyId();
    _reproductiveStatus = _resolveReproductiveStatus(animal);
    _productiveSituation = animal?.situacaoProdutiva;
    // "Seca" é situação produtiva: a vaca seca continua prenha, vazia etc.
    if (_reproductiveStatus == AnimalReproductiveStatus.dry) {
      _reproductiveStatus = AnimalReproductiveStatus.pending;
      _productiveSituation ??= AnimalProductiveSituation.dry;
    }
  }

  /// Animal novo já vem na propriedade filtrada na lista ou na única que há.
  int? _defaultPropertyId() {
    final ids = widget.properties.map((property) => property.id).toSet();
    final filtered = ref.read(animalsPropertyFilterProvider);
    if (filtered != null && ids.contains(filtered)) return filtered;
    return ids.length == 1 ? ids.single : null;
  }

  @override
  void dispose() {
    _codigo.dispose();
    _lactacao.dispose();
    _touroIa.dispose();
    _historico.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = ref.watch(animalsBusyProvider);
    final animal = widget.animal;
    final codigoField = AnimalImportFieldKey.codigo.spec;
    final nascimentoField = AnimalImportFieldKey.dataNascimento.spec;
    final propertyField = AnimalImportFieldKey.idPropriedade.spec;
    final lactacaoField = AnimalImportFieldKey.numeroLactacao.spec;
    final touroIaField = AnimalImportFieldKey.touroIa.spec;
    final historicoField = AnimalImportFieldKey.historicoReprodutivo.spec;

    return AppForm(
      internalScroll: true,
      isLoading: isBusy,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      fieldsSpacing: 24,
      actionsSpacing: 10,
      actionButtonHeight: 44,
      actionButtonFontSize: 15,
      actionButtonPadding: const EdgeInsets.symmetric(horizontal: 18),
      submitText: animal == null ? 'Cadastrar animal' : 'Salvar',
      onCancel: () => Navigator.of(context).maybePop(),
      onSubmit: () async {
        final navigator = Navigator.of(context);

        try {
          final property = _selectedProperty();

          final payload = AnimalSummaryModel(
            id: animal?.id ?? 0,
            idExterno: animal?.idExterno ?? const Uuid().v4(),
            idPropriedade: _propertyId ?? 0,
            idExternoPropriedade:
                property?.idExterno ?? animal?.idExternoPropriedade ?? '',
            codigo: _codigo.text.trim(),
            dataNascimento: _nascimento,
            numeroLactacao: int.tryParse(_lactacao.text.trim()) ?? 0,
            dataUltimoParto: _parto,
            dataInseminacao: _inseminacao,
            touroIa: _touroIa.text.trim(),
            historicoReprodutivo: _historico.text.trim(),
            statusReprodutivo: _reproductiveStatus,
            situacaoProdutiva: _productiveSituation,
            status: animal?.status ?? AnimalStatus.active,
          );

          await ref.read(animalsControllerProvider).save(payload);

          if (mounted) {
            await navigator.maybePop();
            showAppSuccess('Animal salvo com sucesso.');
          }
        } catch (error) {
          showAppError(error);
        }
      },
      fields: [
        _Section(
          title: 'Identificação',
          child: ResponsiveFieldGrid(
            children: [
              AppTextField(
                label: codigoField.label,
                controller: _codigo,
                required: codigoField.required,
                autofocus: animal == null,
              ),
              AppDropdown<int>(
                value: _propertyId,
                labelText: propertyField.label,
                required: propertyField.required,
                searchable: true,
                onChanged: (value) => setState(() => _propertyId = value),
                options: widget.properties
                    .map(
                      (item) =>
                          AppDropdownOption(label: item.nome, value: item.id),
                    )
                    .toList(growable: false),
              ),
              AppDateField(
                label: nascimentoField.label,
                value: _nascimento,
                required: nascimentoField.required,
                onChanged: (value) => setState(() => _nascimento = value),
              ),
            ],
          ),
        ),
        _Section(
          title: 'Situação',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReproductiveStatusPicker(
                value: _reproductiveStatus == AnimalReproductiveStatus.pending
                    ? null
                    : _reproductiveStatus.apiValue,
                onChanged: (value) => setState(() {
                  _reproductiveStatus = value == null
                      ? AnimalReproductiveStatus.pending
                      : AnimalReproductiveStatus.fromApiValue(value);
                }),
              ),
              const SizedBox(height: 16),
              _ProductiveSituationPicker(
                value: _productiveSituation,
                onChanged: (value) =>
                    setState(() => _productiveSituation = value),
              ),
            ],
          ),
        ),
        _Section(
          title: 'Reprodução',
          child: ResponsiveFieldGrid(
            children: [
              _LactationField(
                label: lactacaoField.label,
                controller: _lactacao,
              ),
              AppDateField(
                label: 'Data do último parto',
                value: _parto,
                showToday: true,
                onChanged: (value) => setState(() => _parto = value),
              ),
              AppDateField(
                label: 'Data da última IA',
                value: _inseminacao,
                showToday: true,
                onChanged: (value) => setState(() => _inseminacao = value),
              ),
              AppTextField(label: touroIaField.label, controller: _touroIa),
            ],
          ),
        ),
        _Section(
          title: 'Observações',
          child: AppTextField(
            label: historicoField.label,
            hint: 'Decisões, histórico, cuidados com o animal',
            controller: _historico,
            maxLines: 3,
          ),
        ),
      ],
    );
  }

  PropertySummaryModel? _selectedProperty() {
    for (final property in widget.properties) {
      if (property.id == _propertyId) {
        return property;
      }
    }

    return null;
  }

  AnimalReproductiveStatus _resolveReproductiveStatus(
    AnimalSummaryModel? animal,
  ) {
    final savedStatus = animal?.statusReprodutivo;
    if (savedStatus != null) {
      return savedStatus;
    }

    if (animal?.dataInseminacao != null) {
      return AnimalReproductiveStatus.inseminated;
    }

    final history = (animal?.historicoReprodutivo ?? '').normalize();

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
        history.contains('negativ')) {
      return AnimalReproductiveStatus.empty;
    }

    return AnimalReproductiveStatus.pending;
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

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

/// Situação produtiva em botões; tocar na marcada desmarca.
class _ProductiveSituationPicker extends StatelessWidget {
  const _ProductiveSituationPicker({
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Situação produtiva',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final situation in AnimalProductiveSituation.values)
              ChoiceChip(
                label: Text(AnimalProductiveSituation.label(situation)),
                selected: value == situation,
                onSelected: (selected) =>
                    onChanged(selected ? situation : null),
              ),
          ],
        ),
      ],
    );
  }
}

/// Número de lactações com botões de menos e mais.
class _LactationField extends StatelessWidget {
  const _LactationField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  void _step(int delta) {
    final current = int.tryParse(controller.text.trim()) ?? 0;
    final next = current + delta;
    if (next < 0) return;
    controller.text = next.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      controller: controller,
      keyboardType: TextInputType.number,
      prefixIcon: IconButton(
        tooltip: 'Menos uma lactação',
        icon: const Icon(Icons.remove),
        onPressed: () => _step(-1),
      ),
      suffixIcon: IconButton(
        tooltip: 'Mais uma lactação',
        icon: const Icon(Icons.add),
        onPressed: () => _step(1),
      ),
    );
  }
}
