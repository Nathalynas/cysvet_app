import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/enums/animal_status.dart';
import '../../../../core/presentation/app_scaffold_messenger.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../properties/domain/property_summary_model.dart';
import '../../application/animals_provider.dart';
import '../../domain/animal_summary_model.dart';

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
  static const _sexoOptions = ['Masculino', 'Feminino'];

  final _codigo = TextEditingController();
  final _especie = TextEditingController();
  final _nascimento = TextEditingController();
  final _lactacao = TextEditingController();
  final _parto = TextEditingController();
  final _inseminacao = TextEditingController();
  final _historico = TextEditingController();

  String? _sexo;
  int? _propertyId;
  AnimalReproductiveStatus _reproductiveStatus =
      AnimalReproductiveStatus.pending;

  @override
  void initState() {
    super.initState();

    final animal = widget.animal;

    _codigo.text = animal?.codigo ?? '';
    _especie.text = animal?.categoria ?? '';
    _sexo = _normalizeSexo(animal?.sexo);
    _nascimento.text = formatDateInput(animal?.dataNascimento);
    _lactacao.text = (animal?.numeroLactacao ?? 0).toString();
    _parto.text = formatDateInput(animal?.dataUltimoParto);
    _inseminacao.text = formatDateInput(animal?.dataInseminacao);
    _historico.text = animal?.historicoReprodutivo ?? '';
    _propertyId = animal?.idPropriedade;
    _reproductiveStatus = _resolveReproductiveStatus(animal);
  }

  @override
  void dispose() {
    _codigo.dispose();
    _especie.dispose();
    _nascimento.dispose();
    _lactacao.dispose();
    _parto.dispose();
    _inseminacao.dispose();
    _historico.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = ref.watch(animalsBusyProvider);
    final animal = widget.animal;

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
            categoria: _especie.text.trim(),
            sexo: _sexo,
            dataNascimento: parseDateInput(_nascimento.text),
            numeroLactacao: int.tryParse(_lactacao.text.trim()) ?? 0,
            dataUltimoParto: parseDateInput(_parto.text),
            dataInseminacao: parseDateInput(_inseminacao.text),
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
        AppTextField(label: 'Brinco/ID', controller: _codigo, required: true),
        AppTextField(label: 'Espécie', controller: _especie, required: true),
        AppDropdown<String>(
          value: _sexo,
          labelText: 'Sexo',
          required: true,
          onChanged: (value) => setState(() => _sexo = value),
          options: _sexoOptions
              .map((item) => AppDropdownOption(label: item, value: item))
              .toList(growable: false),
        ),
        AppTextField(
          label: 'Data de nascimento',
          hint: 'DD/MM/AAAA',
          controller: _nascimento,
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
      ],
      rightFields: [
        AppDropdown<int>(
          value: _propertyId,
          labelText: 'Propriedade vinculada',
          required: true,
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
          labelText: 'Status reprodutivo',
          required: true,
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _reproductiveStatus = value;
            });
          },
          options: AnimalReproductiveStatus.values
              .map((item) => AppDropdownOption(label: item.label, value: item))
              .toList(growable: false),
        ),
        AppTextField(
          label: 'Número de lactação',
          controller: _lactacao,
          required: true,
          keyboardType: TextInputType.number,
        ),
        AppTextField(
          label: 'Data do parto',
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
          label: 'Data da inseminação',
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
        AppTextField(label: 'Histórico', controller: _historico, maxLines: 3),
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

  String? _normalizeSexo(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();

    switch (normalized) {
      case 'masculino':
      case 'macho':
        return 'Masculino';
      case 'feminino':
      case 'femea':
      case 'fêmea':
        return 'Feminino';
      default:
        return null;
    }
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
