import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/enums/property_status.dart';
import '../../../../core/presentation/app_scaffold_messenger.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../application/brazilian_locations_provider.dart';
import '../../application/properties_provider.dart';
import '../../domain/property_summary_model.dart';

class PropertyDialog extends StatelessWidget {
  const PropertyDialog({super.key, this.property});

  final PropertySummaryModel? property;

  static Future<void> show(
    BuildContext context, {
    PropertySummaryModel? property,
  }) {
    return AppDialog.show<void>(
      context: context,
      title: property == null ? 'Nova propriedade' : 'Editar propriedade',
      width: 720,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      fullscreenBodyPadding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      headerIndent: 16,
      useInternalScroll: true,
      fullscreenOnMobile: true,
      content: PropertyDialog(property: property),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PropertyForm(property: property);
  }
}

class _PropertyForm extends ConsumerStatefulWidget {
  const _PropertyForm({this.property});

  final PropertySummaryModel? property;

  @override
  ConsumerState<_PropertyForm> createState() => _PropertyFormState();
}

class _PropertyFormState extends ConsumerState<_PropertyForm> {
  final _nome = TextEditingController();
  final _responsavel = TextEditingController();
  final _contato = TextEditingController();
  final _observacoes = TextEditingController();
  String? _estado;
  String? _cidade;
  late PropertyStatus _status;

  @override
  void initState() {
    super.initState();
    final property = widget.property;
    _nome.text = property?.nome ?? '';
    _responsavel.text = property?.nomeProprietario ?? '';
    _contato.text = property?.contato ?? '';
    _estado = property?.estado;
    _cidade = property?.cidade;
    _observacoes.text = property?.observacoes ?? '';
    _status = property?.status ?? PropertyStatus.active;
  }

  @override
  void dispose() {
    _nome.dispose();
    _responsavel.dispose();
    _contato.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = ref.watch(propertiesBusyProvider);
    final property = widget.property;

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
          final payload = PropertySummaryModel(
            id: property?.id ?? 0,
            idExterno: property?.idExterno ?? const Uuid().v4(),
            nome: _nome.text.trim(),
            nomeProprietario: _responsavel.text.trim(),
            contato: _contato.text.trim(),
            estado: _estado?.trim(),
            cidade: _cidade?.trim(),
            observacoes: _observacoes.text.trim(),
            status: _status,
          );
          await ref.read(propertiesControllerProvider).save(payload);
          if (mounted) {
            await navigator.maybePop();
            showAppSuccess('Propriedade salva com sucesso.');
          }
        } catch (error) {
          showAppError(error);
        }
      },
      fields: [
        AppTextField(
          label: 'Nome da propriedade',
          controller: _nome,
          required: true,
        ),
        AppTextField(
          label: 'Responsável',
          controller: _responsavel,
          required: true,
        ),
        AppTextField(
          label: 'Contato',
          controller: _contato,
          required: true,
          keyboardType: TextInputType.phone,
          inputFormatters: const [PhoneInputFormatter()],
        ),
        _BrazilianLocationFields(
          estado: _estado,
          cidade: _cidade,
          onEstadoChanged: (value) {
            setState(() {
              _estado = value;
              _cidade = null;
            });
          },
          onCidadeChanged: (value) => setState(() => _cidade = value),
        ),
      ],
      rightFields: [
        AppDropdown<PropertyStatus>(
          value: _status,
          labelText: 'Status',
          required: true,
          onChanged: (value) => setState(() => _status = value ?? _status),
          options: PropertyStatus.values
              .map((item) => AppDropdownOption(label: item.label, value: item))
              .toList(growable: false),
        ),
        AppTextField(
          label: 'Observações',
          controller: _observacoes,
          maxLines: 4,
        ),
      ],
    );
  }
}

class _BrazilianLocationFields extends ConsumerWidget {
  const _BrazilianLocationFields({
    required this.estado,
    required this.cidade,
    required this.onEstadoChanged,
    required this.onCidadeChanged,
  });

  final String? estado;
  final String? cidade;
  final ValueChanged<String?> onEstadoChanged;
  final ValueChanged<String?> onCidadeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasEstado = estado != null && estado!.isNotEmpty;
    final hasCidade = cidade != null && cidade!.isNotEmpty;
    final locations = ref.watch(brazilianLocationsProvider);

    return FormField<bool>(
      initialValue: hasEstado && hasCidade,
      validator: (_) {
        if (!hasEstado || !hasCidade) return 'Informe estado e cidade';
        return null;
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            locations.when(
              data: (data) {
                final cities = data.citiesFor(estado);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppDropdown<String>(
                      value: estado,
                      labelText: 'Estado',
                      nullLabel: 'Selecione o estado',
                      searchable: true,
                      required: true,
                      onChanged: (value) {
                        onEstadoChanged(value);
                        field.didChange(
                          value != null && value.isNotEmpty && hasCidade,
                        );
                      },
                      options: data.states
                          .map(
                            (state) =>
                                AppDropdownOption(label: state, value: state),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 16),
                    AppDropdown<String>(
                      value: cities.contains(cidade) ? cidade : null,
                      labelText: 'Cidade',
                      nullLabel: hasEstado
                          ? 'Selecione a cidade'
                          : 'Selecione o estado primeiro',
                      searchable: true,
                      required: true,
                      onChanged: hasEstado
                          ? (value) {
                              onCidadeChanged(value);
                              field.didChange(
                                hasEstado && value != null && value.isNotEmpty,
                              );
                            }
                          : (_) {},
                      options: cities
                          .map(
                            (city) =>
                                AppDropdownOption(label: city, value: city),
                          )
                          .toList(growable: false),
                    ),
                  ],
                );
              },
              loading: () => AppDropdown<String>(
                value: null,
                labelText: 'Estado',
                nullLabel: 'Carregando estados...',
                onChanged: (_) {},
                options: const [],
              ),
              error: (_, _) => Text(
                'Nao foi possivel carregar estados e cidades.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  field.errorText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
