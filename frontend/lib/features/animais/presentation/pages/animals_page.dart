import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/presentation/async_value_view.dart';
import '../../../../core/utils/formatters.dart';
import '../../../propriedades/application/properties_provider.dart';
import '../../../propriedades/domain/property_summary_model.dart';
import '../../application/animals_provider.dart';
import '../../domain/animal_summary_model.dart';

class AnimalsPage extends ConsumerWidget {
  const AnimalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animals = ref.watch(animalsProvider);
    final properties = ref.watch(propertiesProvider);
    final selectedPropertyId = ref.watch(animalsPropertyFilterProvider);
    final propertyOptions =
        properties.asData?.value ?? const <PropertySummaryModel>[];
    final propertyById = {
      for (final property in propertyOptions) property.id: property,
    };

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(animalsProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _AnimalsFilterCard(
                properties: propertyOptions,
                selectedPropertyId: selectedPropertyId,
                onChanged: (value) {
                  ref.read(animalsPropertyFilterProvider.notifier).set(value);
                },
              ),
              const SizedBox(height: 16),
              AsyncValueView<List<AnimalSummaryModel>>(
                value: animals,
                loadingMessage: 'Buscando animais...',
                emptyMessage: 'Nenhum animal encontrado para o filtro atual.',
                isEmpty: (items) => items.isEmpty,
                onRetry: () => ref.invalidate(animalsProvider),
                builder: (items) => Column(
                  children: [
                    for (final animal in items) ...[
                      _AnimalCard(
                        animal: animal,
                        propertyName:
                            propertyById[animal.idPropriedade]?.nome ??
                            animal.idExternoPropriedade,
                      ),
                      const SizedBox(height: 12),
                    ],
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

class _AnimalsFilterCard extends StatelessWidget {
  const _AnimalsFilterCard({
    required this.properties,
    required this.selectedPropertyId,
    required this.onChanged,
  });

  final List<PropertySummaryModel> properties;
  final int? selectedPropertyId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<int?>(
          initialValue: selectedPropertyId,
          decoration: const InputDecoration(
            labelText: 'Filtrar por propriedade',
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Todas as propriedades'),
            ),
            ...properties.map(
              (property) => DropdownMenuItem<int?>(
                value: property.id,
                child: Text(property.nome),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _AnimalCard extends StatelessWidget {
  const _AnimalCard({required this.animal, required this.propertyName});

  final AnimalSummaryModel animal;
  final String propertyName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pets),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    animal.codigo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    animal.categoria,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Line(label: 'Propriedade', value: propertyName),
            _Line(
              label: 'Nascimento',
              value: formatDate(animal.dataNascimento),
            ),
            _Line(
              label: 'Ultimo parto',
              value: formatDate(animal.dataUltimoParto),
            ),
            _Line(label: 'Lactacao', value: animal.numeroLactacao.toString()),
            _Line(
              label: 'Dias em lactacao',
              value: animal.diasEmLactacao?.toString() ?? '--',
            ),
            if (animal.historicoReprodutivo != null &&
                animal.historicoReprodutivo!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                animal.historicoReprodutivo!,
                style: const TextStyle(color: AppTheme.bodyTextColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: AppTheme.bodyTextColor),
            ),
          ],
        ),
      ),
    );
  }
}
