import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/presentation/app_scaffold_messenger.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../properties/domain/property_summary_model.dart';
import '../../application/visits_provider.dart';
import '../../domain/visit_summary_model.dart';

class VisitDialog extends StatelessWidget {
  const VisitDialog({
    super.key,
    required this.properties,
    this.initialPropertyId,
  });

  final List<PropertySummaryModel> properties;
  final int? initialPropertyId;

  static Future<void> show(
    BuildContext context, {
    required List<PropertySummaryModel> properties,
    int? initialPropertyId,
  }) {
    return AppDialog.show<void>(
      context: context,
      title: 'Nova visita',
      width: 720,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      fullscreenBodyPadding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      headerIndent: 16,
      useInternalScroll: true,
      fullscreenOnMobile: true,
      content: VisitDialog(
        properties: properties,
        initialPropertyId: initialPropertyId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _VisitForm(
      properties: properties,
      initialPropertyId: initialPropertyId,
    );
  }
}

class _VisitForm extends ConsumerStatefulWidget {
  const _VisitForm({required this.properties, this.initialPropertyId});

  final List<PropertySummaryModel> properties;
  final int? initialPropertyId;

  @override
  ConsumerState<_VisitForm> createState() => _VisitFormState();
}

class _VisitFormState extends ConsumerState<_VisitForm> {
  final _dataVisita = TextEditingController();
  final _observacoes = TextEditingController();
  int? _propertyId;

  @override
  void initState() {
    super.initState();
    _dataVisita.text = formatDateInput(DateTime.now());
    _propertyId = _hasProperty(widget.initialPropertyId)
        ? widget.initialPropertyId
        : null;
  }

  @override
  void dispose() {
    _dataVisita.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = ref.watch(visitsBusyProvider);

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
          final payload = VisitSummaryModel(
            idExterno: const Uuid().v4(),
            idPropriedade: _propertyId ?? 0,
            idExternoPropriedade: property?.idExterno ?? '',
            dataVisita: parseDateInput(_dataVisita.text),
            observacoes: _observacoes.text.trim(),
          );
          await ref.read(visitsControllerProvider).save(payload);
          if (mounted) {
            await navigator.maybePop();
            showAppSuccess('Visita salva com sucesso.');
          }
        } catch (error) {
          showAppError(error);
        }
      },
      fields: [
        AppDropdown<int>(
          value: _propertyId,
          labelText: 'Propriedade vinculada',
          required: true,
          searchable: true,
          onChanged: (value) => setState(() => _propertyId = value),
          options: widget.properties
              .map(
                (property) =>
                    AppDropdownOption(label: property.nome, value: property.id),
              )
              .toList(growable: false),
        ),
        AppTextField(
          label: 'Data da visita',
          hint: 'DD/MM/AAAA',
          controller: _dataVisita,
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
        AppTextField(
          label: 'Observacoes',
          controller: _observacoes,
          maxLines: 5,
        ),
      ],
    );
  }

  bool _hasProperty(int? id) {
    if (id == null) return false;
    return widget.properties.any((property) => property.id == id);
  }

  PropertySummaryModel? _selectedProperty() {
    for (final property in widget.properties) {
      if (property.id == _propertyId) {
        return property;
      }
    }

    return null;
  }
}
