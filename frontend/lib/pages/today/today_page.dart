import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cysvet_app/core/presentation/async_value_view.dart';
import 'package:cysvet_app/core/utils/formatters.dart';
import 'package:cysvet_app/core/widgets/empty_state.dart';
import 'package:cysvet_app/models/animal_forecast.dart';
import 'package:cysvet_app/models/animal_summary_model.dart';
import 'package:cysvet_app/models/today_summary.dart';
import 'package:cysvet_app/models/visit_action_hint.dart';
import 'package:cysvet_app/providers/today_provider.dart';

/// Tela inicial do celular: as fazendas, cada uma com quantos animais precisam
/// de atenção. Tocar numa fazenda abre o que fazer nela.
class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farms = ref.watch(todayFarmsProvider);
    final theme = Theme.of(context);

    return AsyncValueView<List<TodayFarm>>(
      value: farms,
      onRetry: () => ref.invalidate(todayFarmsProvider),
      isEmpty: (items) => items.isEmpty,
      emptyMessage: 'Nenhuma propriedade ativa. Cadastre em Propriedades.',
      builder: (items) => RefreshIndicator(
        onRefresh: () => ref.refresh(todayFarmsProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text('Hoje', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Escolha a fazenda para ver o que fazer.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            for (final farm in items) _FarmTile(farm: farm),
          ],
        ),
      ),
    );
  }
}

class _FarmTile extends StatelessWidget {
  const _FarmTile({required this.farm});

  final TodayFarm farm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attention = farm.summary.animalsNeedingAttention;
    final lastVisit = farm.lastVisit;
    final details = [
      '${farm.summary.totalAnimals} animais',
      if (lastVisit != null) 'última visita ${formatDate(lastVisit)}',
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/hoje/${farm.property.id}'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm.property.nome,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(details, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _AttentionBadge(count: attention),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttentionBadge extends StatelessWidget {
  const _AttentionBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final none = count == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: none ? scheme.surfaceContainerHighest : scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        none ? 'em dia' : '$count atenção',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: none ? scheme.onSurfaceVariant : scheme.onTertiaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// O que fazer numa fazenda: nova visita, busca por brinco, animais que
/// precisam de atenção (agrupados) e os próximos 30 dias.
class TodayFarmPage extends ConsumerStatefulWidget {
  const TodayFarmPage({super.key, required this.propertyId});

  final int propertyId;

  @override
  ConsumerState<TodayFarmPage> createState() => _TodayFarmPageState();
}

class _TodayFarmPageState extends ConsumerState<TodayFarmPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final farms = ref.watch(todayFarmsProvider);

    return AsyncValueView<List<TodayFarm>>(
      value: farms,
      onRetry: () => ref.invalidate(todayFarmsProvider),
      builder: (items) {
        final farm = items
            .where((item) => item.property.id == widget.propertyId)
            .firstOrNull;
        if (farm == null) {
          return const EmptyState(
            title: 'Fazenda não encontrada',
            message: 'Ela pode ter sido arquivada.',
          );
        }
        return _buildFarm(context, farm);
      },
    );
  }

  Widget _buildFarm(BuildContext context, TodayFarm farm) {
    final theme = Theme.of(context);
    final summary = farm.summary;
    final query = _search.trim();
    final found = query.isEmpty
        ? const <AnimalSummaryModel>[]
        : (farm.animals.where((animal) => animal.codigo.contains(query)).toList()
            ..sort((a, b) => a.codigo.compareTo(b.codigo)));
    final lastVisit = farm.lastVisit;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(farm.property.nome, style: theme.textTheme.headlineSmall),
        Text(
          [
            '${summary.totalAnimals} animais',
            if (lastVisit != null) 'última visita ${formatDate(lastVisit)}',
          ].join(' · '),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: () =>
                context.go('/visitas/nova?propriedade=${farm.property.id}'),
            icon: const Icon(Icons.add),
            label: const Text('Nova visita aqui'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Buscar brinco',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _search = value),
        ),
        if (query.isNotEmpty) ...[
          const SizedBox(height: 8),
          if (found.isEmpty)
            Text('Nenhum animal com o brinco "$query".')
          else
            for (final animal in found.take(20))
              _AnimalRow(animal: animal, detail: _animalDetail(animal)),
        ],
        const SizedBox(height: 20),
        Text(
          summary.animalsNeedingAttention == 0
              ? 'Nenhum animal precisa de atenção agora'
              : 'Precisam de atenção (${summary.animalsNeedingAttention})',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        for (final kind in VisitActionKind.values)
          if (summary.byKind[kind]!.isNotEmpty)
            _ActionGroup(kind: kind, actions: summary.byKind[kind]!),
        const SizedBox(height: 20),
        Text(
          'Próximos $diasProximosEventos dias',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CountChip(label: 'Partos', count: summary.upcomingCalvings),
            _CountChip(label: 'Secagens', count: summary.upcomingDryOffs),
            _CountChip(label: 'Pré-parto', count: summary.upcomingPrepartum),
          ],
        ),
      ],
    );
  }

  String _animalDetail(AnimalSummaryModel animal) {
    final hoje = DateTime.now();
    final status = animal.statusReprodutivo?.label ?? 'Sem situação';
    final forecast = AnimalForecast.of(animal, hoje);
    if (forecast == null) return status;
    return [
      '$status · ${forecast.diasGestacao} d',
      if (!forecast.jaSeca) 'Secar ${formatDate(forecast.secagem)}',
      'Parto ${formatDate(forecast.parto)}',
    ].join(' · ');
  }
}

class _ActionGroup extends StatelessWidget {
  const _ActionGroup({required this.kind, required this.actions});

  final VisitActionKind kind;
  final List<TodayAction> actions;

  @override
  Widget build(BuildContext context) {
    final urgent = actions.where((action) => action.hint.urgent).length;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ExpansionTile(
        shape: const Border(),
        title: Text(kind.title),
        subtitle: urgent == 0 ? null : Text('$urgent atrasados'),
        trailing: Text(
          '${actions.length}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        children: [
          for (final action in actions)
            _AnimalRow(
              animal: action.animal,
              detail: action.hint.label,
              urgent: action.hint.urgent,
            ),
        ],
      ),
    );
  }
}

class _AnimalRow extends StatelessWidget {
  const _AnimalRow({
    required this.animal,
    required this.detail,
    this.urgent = false,
  });

  final AnimalSummaryModel animal;
  final String detail;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      minTileHeight: 48,
      title: Text(
        animal.codigo.isEmpty ? 'Sem brinco' : animal.codigo,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        detail,
        style: urgent
            ? theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              )
            : theme.textTheme.bodyMedium,
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        '$label $count',
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
