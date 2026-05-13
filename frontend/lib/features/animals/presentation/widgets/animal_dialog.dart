import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

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
      useInternalScroll: true,
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
  final _especie = TextEditingController();
  final _sexo = TextEditingController();
  final _nascimento = TextEditingController();
  final _lactacao = TextEditingController();
  final _historico = TextEditingController();
  late AnimalStatus _status;
  int? _propertyId;

  @override
  void initState() {
    super.initState();
    final animal = widget.animal;
    _codigo.text = animal?.codigo ?? '';
    _especie.text = animal?.categoria ?? '';
    _sexo.text = animal?.sexo ?? '';
    _nascimento.text = formatDateInput(animal?.dataNascimento);
    _lactacao.text = (animal?.numeroLactacao ?? 0).toString();
    _historico.text = animal?.historicoReprodutivo ?? '';
    _status = animal?.status ?? AnimalStatus.active;
    _propertyId = animal?.idPropriedade;
  }

  @override
  void dispose() {
    _codigo.dispose();
    _especie.dispose();
    _sexo.dispose();
    _nascimento.dispose();
    _lactacao.dispose();
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
            sexo: _sexo.text.trim(),
            dataNascimento: parseDateInput(_nascimento.text),
            numeroLactacao: int.tryParse(_lactacao.text.trim()) ?? 0,
            historicoReprodutivo: _historico.text.trim(),
            status: _status,
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
        AppTextField(label: 'Sexo', controller: _sexo, required: true),
        AppTextField(
          label: 'Data de nascimento',
          hint: 'DD/MM/AAAA',
          controller: _nascimento,
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
        AppDropdown<AnimalStatus>(
          value: _status,
          labelText: 'Status',
          required: true,
          onChanged: (value) => setState(() => _status = value ?? _status),
          options: AnimalStatus.values
              .map((item) => AppDropdownOption(label: item.label, value: item))
              .toList(growable: false),
        ),
        AppTextField(
          label: 'Número de lactação',
          controller: _lactacao,
          required: true,
          keyboardType: TextInputType.number,
        ),
        AppTextField(label: 'Histórico', controller: _historico, maxLines: 3),
      ],
    );
  }

  PropertySummaryModel? _selectedProperty() {
    for (final property in widget.properties) {
      if (property.id == _propertyId) return property;
    }

    return null;
  }
}
