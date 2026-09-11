import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:cysvet_app/core/constants/app_constants.dart';
import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/core/presentation/app_scaffold_messenger.dart';
import 'package:cysvet_app/core/utils/formatters.dart';
import 'package:cysvet_app/core/widgets/app_dialog.dart';
import 'package:cysvet_app/core/widgets/app_dropdown.dart';
import 'package:cysvet_app/core/widgets/app_form.dart';
import 'package:cysvet_app/core/widgets/app_text_field.dart';
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
      title: animal == null ? 'Novo animal' : 'Editar animal',
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
  final _nascimento = TextEditingController();
  final _lactacao = TextEditingController();
  final _parto = TextEditingController();
  final _inseminacao = TextEditingController();
  final _touroIa = TextEditingController();
  final _historico = TextEditingController();

  int? _propertyId;
  AnimalReproductiveStatus _reproductiveStatus =
      AnimalReproductiveStatus.pending;

  @override
  void initState() {
    super.initState();

    final animal = widget.animal;

    _codigo.text = animal?.codigo ?? '';
    _nascimento.text = formatDateInput(animal?.dataNascimento);
    _lactacao.text = (animal?.numeroLactacao ?? 0).toString();
    _parto.text = formatDateInput(animal?.dataUltimoParto);
    _inseminacao.text = formatDateInput(animal?.dataInseminacao);
    _touroIa.text = animal?.touroIa ?? '';
    _historico.text = animal?.historicoReprodutivo ?? '';
    _propertyId = animal?.idPropriedade;
    _reproductiveStatus = _resolveReproductiveStatus(animal);
  }

  @override
  void dispose() {
    _codigo.dispose();
    _nascimento.dispose();
    _lactacao.dispose();
    _parto.dispose();
    _inseminacao.dispose();
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
    final reproductiveStatusField = AnimalImportFieldKey.statusReprodutivo.spec;
    final lactacaoField = AnimalImportFieldKey.numeroLactacao.spec;
    final partoField = AnimalImportFieldKey.dataUltimoParto.spec;
    final inseminacaoField = AnimalImportFieldKey.dataInseminacao.spec;
    final touroIaField = AnimalImportFieldKey.touroIa.spec;
    final historicoField = AnimalImportFieldKey.historicoReprodutivo.spec;

    return AppForm(
      internalScroll: true,
      isLoading: isBusy,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      fieldsSpacing: 14,
      actionsSpacing: 10,
      actionButtonHeight: 38,
      actionButtonFontSize: 14,
      actionButtonPadding: const EdgeInsets.symmetric(horizontal: 14),
      submitText: 'Salvar',
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
            dataNascimento: parseDateInput(_nascimento.text),
            numeroLactacao: int.tryParse(_lactacao.text.trim()) ?? 0,
            dataUltimoParto: parseDateInput(_parto.text),
            dataInseminacao: parseDateInput(_inseminacao.text),
            touroIa: _touroIa.text.trim(),
            historicoReprodutivo: _historico.text.trim(),
            statusReprodutivo: _reproductiveStatus,
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
        AppTextField(
          label: codigoField.label,
          controller: _codigo,
          required: codigoField.required,
        ),
        AppTextField(
          label: nascimentoField.label,
          hint: 'DD/MM/AAAA',
          controller: _nascimento,
          required: nascimentoField.required,
          keyboardType: TextInputType.number,
          inputFormatters: const [DateInputFormatter()],
          validator: (value) {
            if (parseDateInput(value ?? '') == null) {
              return 'Informe uma data valida';
            }
            return null;
          },
        ),
      ],
      rightFields: [
        AppDropdown<int>(
          value: _propertyId,
          labelText: propertyField.label,
          required: propertyField.required,
          searchable: true,
          onChanged: (value) => setState(() => _propertyId = value),
          options: widget.properties
              .map(
                (item) => AppDropdownOption(label: item.nome, value: item.id),
              )
              .toList(growable: false),
        ),
        AppDropdown<AnimalReproductiveStatus>(
          value: _reproductiveStatus,
          labelText: reproductiveStatusField.label,
          required: reproductiveStatusField.required,
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _reproductiveStatus = value;
            });
          },
          options: AnimalReproductiveStatus.editableValues
              .map((item) => AppDropdownOption(label: item.label, value: item))
              .toList(growable: false),
        ),
        AppTextField(
          label: lactacaoField.label,
          controller: _lactacao,
          required: lactacaoField.required,
          keyboardType: TextInputType.number,
        ),
        AppTextField(
          label: partoField.label,
          hint: 'DD/MM/AAAA',
          controller: _parto,
          keyboardType: TextInputType.number,
          inputFormatters: const [DateInputFormatter()],
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return null;
            }
            if (parseDateInput(value ?? '') == null) {
              return 'Informe uma data valida';
            }
            return null;
          },
        ),
        AppTextField(
          label: inseminacaoField.label,
          hint: 'DD/MM/AAAA',
          controller: _inseminacao,
          keyboardType: TextInputType.number,
          inputFormatters: const [DateInputFormatter()],
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return null;
            }
            if (parseDateInput(value ?? '') == null) {
              return 'Informe uma data valida';
            }
            return null;
          },
        ),
        AppTextField(label: touroIaField.label, controller: _touroIa),
        AppTextField(
          label: historicoField.label,
          controller: _historico,
          maxLines: 3,
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
