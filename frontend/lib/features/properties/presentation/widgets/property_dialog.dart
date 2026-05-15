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
import '../../application/ibge_provider.dart';
import '../../application/properties_provider.dart';
import '../../domain/ibge_municipio_model.dart';
import '../../domain/ibge_uf_model.dart';
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
        _IbgeLocationFields(
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

class _IbgeLocationFields extends ConsumerWidget {
  const _IbgeLocationFields({
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
    final ufs = ref.watch(ibgeUfsProvider);

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
            ufs.when(
              data: (data) {
                final selectedUf = _selectedUf(data, estado);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppDropdown<String>(
                      value: selectedUf?.sigla,
                      labelText: 'Estado',
                      nullLabel: 'Selecione o estado',
                      searchable: true,
                      required: true,
                      onChanged: (value) {
                        onEstadoChanged(value);
                        field.didChange(false);
                      },
                      options: data
                          .map(
                            (uf) => AppDropdownOption(
                              label: uf.label,
                              value: uf.sigla,
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 16),
                    _MunicipioDropdown(
                      uf: selectedUf,
                      cidade: cidade,
                      onCidadeChanged: (value) {
                        onCidadeChanged(value);
                        field.didChange(value != null && value.isNotEmpty);
                      },
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

  IbgeUfModel? _selectedUf(List<IbgeUfModel> ufs, String? value) {
    for (final uf in ufs) {
      if (uf.matches(value)) return uf;
    }

    return null;
  }
}

class _MunicipioDropdown extends ConsumerWidget {
  const _MunicipioDropdown({
    required this.uf,
    required this.cidade,
    required this.onCidadeChanged,
  });

  final IbgeUfModel? uf;
  final String? cidade;
  final ValueChanged<String?> onCidadeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedUf = uf;
    if (selectedUf == null) {
      return AppDropdown<String>(
        value: null,
        labelText: 'Cidade',
        nullLabel: 'Selecione o estado primeiro',
        searchable: true,
        required: true,
        onChanged: (_) {},
        options: const [],
      );
    }

    final municipios = ref.watch(ibgeMunicipiosProvider(selectedUf.sigla));

    return municipios.when(
      data: (data) {
        final selectedMunicipio = _selectedMunicipio(data, cidade);

        return AppDropdown<String>(
          value: selectedMunicipio?.nome,
          labelText: 'Cidade',
          nullLabel: 'Selecione a cidade',
          searchable: true,
          required: true,
          onChanged: onCidadeChanged,
          options: data
              .map(
                (municipio) => AppDropdownOption(
                  label: municipio.nome,
                  value: municipio.nome,
                ),
              )
              .toList(growable: false),
        );
      },
      loading: () => AppDropdown<String>(
        value: null,
        labelText: 'Cidade',
        nullLabel: 'Carregando cidades...',
        searchable: true,
        required: true,
        onChanged: (_) {},
        options: const [],
      ),
      error: (_, _) => Text(
        'Nao foi possivel carregar cidades.',
        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
      ),
    );
  }

  IbgeMunicipioModel? _selectedMunicipio(
    List<IbgeMunicipioModel> municipios,
    String? value,
  ) {
    for (final municipio in municipios) {
      if (municipio.matches(value)) return municipio;
    }

    return null;
  }
}
