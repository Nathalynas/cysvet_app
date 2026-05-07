import 'package:cysvet_app/core/widgets/search_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/presentation/async_value_view.dart';
import '../../application/properties_provider.dart';
import '../../domain/property_summary_model.dart';

final propertiesSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

class PropertiesPage extends ConsumerWidget {
  const PropertiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(propertiesProvider);
    final searchQuery = ref.watch(propertiesSearchQueryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(propertiesProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SearchCard(
                value: searchQuery,
                labelText: 'Pesquisar propriedades',
                onChanged: (value) {
                  ref.read(propertiesSearchQueryProvider.notifier).state =
                      value;
                },
              ),
              const SizedBox(height: 16),
              AsyncValueView<List<PropertySummaryModel>>(
                value: properties,
                loadingMessage: 'Buscando propriedades...',
                emptyMessage: 'Nenhuma propriedade encontrada para este usuario.',
                isEmpty: (items) => items.isEmpty,
                onRetry: () => ref.invalidate(propertiesProvider),
                builder: (items) {
                  final filteredItems = _filterProperties(items, searchQuery);

                  if (filteredItems.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(
                        child: Text(
                          'Nenhuma propriedade encontrada para a pesquisa atual.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (final property in filteredItems) ...[
                        _PropertyCard(property: property),
                        const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<PropertySummaryModel> _filterProperties(
  List<PropertySummaryModel> items,
  String query,
) {
  final normalizedQuery = _normalize(query.trim());

  if (normalizedQuery.isEmpty) {
    return items;
  }

  return items.where((property) {
    final searchableText = _normalize(
      [
        property.nome,
        property.nomeProprietario,
        property.localizacao,
        property.idExterno,
        property.observacoes ?? '',
      ].join(' '),
    );

    return searchableText.contains(normalizedQuery);
  }).toList();
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp('[áàâãä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòôõö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll('ç', 'c');
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property});

  final PropertySummaryModel property;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.agriculture_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    property.nome,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoLine(
              label: 'Proprietario',
              value: property.nomeProprietario,
            ),
            _InfoLine(
              label: 'Localizacao',
              value: property.localizacao,
            ),
            _InfoLine(
              label: 'ID externo',
              value: property.idExterno,
            ),
            if (property.observacoes != null &&
                property.observacoes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                property.observacoes!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
          ],
        ),
      ),
    );
  }
}