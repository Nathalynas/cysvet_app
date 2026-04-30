import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/presentation/async_value_view.dart';
import '../../application/properties_provider.dart';
import '../../domain/property_summary.dart';

class PropertiesPage extends ConsumerWidget {
  const PropertiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(propertiesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(propertiesProvider.future),
          child: AsyncValueView<List<PropertySummary>>(
            value: properties,
            loadingMessage: 'Buscando propriedades...',
            emptyMessage: 'Nenhuma propriedade encontrada para este usuario.',
            isEmpty: (items) => items.isEmpty,
            onRetry: () => ref.invalidate(propertiesProvider),
            builder: (items) => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final property = items[index];
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
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textColor,
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
                            style: const TextStyle(
                              color: AppTheme.bodyTextColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
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
