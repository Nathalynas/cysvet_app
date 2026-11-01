import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cysvet_app/core/presentation/app_scaffold_messenger.dart';
import 'package:cysvet_app/providers/visit_in_progress_provider.dart';

/// Faixa global que aparece fora do formulário quando há uma visita aberta e
/// ainda não salva, com atalho para voltar a ela. Na lista de visitas ela é
/// mostrada como cartão, então a faixa não aparece lá.
class VisitInProgressBar extends ConsumerWidget {
  const VisitInProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visit = ref.watch(visitInProgressProvider);
    final location = GoRouterState.of(context).uri.path;
    if (visit == null || location == visit.route || location == '/visitas') {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final collected = switch (visit.collectedCount) {
      0 => 'nenhum animal coletado',
      1 => '1 animal coletado',
      final count => '$count animais coletados',
    };
    final property = visit.propertyName;

    void discard() {
      final notifier = ref.read(visitInProgressProvider.notifier);
      notifier.clear();
      showAppUndo(
        'Visita em andamento descartada.',
        onUndo: () => notifier.remember(visit),
      );
    }

    return Material(
      color: colorScheme.primaryContainer,
      child: InkWell(
        onTap: () => context.go(visit.route),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
          child: Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 20,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visita em andamento',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      [?property, collected, 'não salva'].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Descartar visita',
                color: colorScheme.onPrimaryContainer,
                onPressed: discard,
                icon: const Icon(Icons.close),
              ),
              FilledButton(
                onPressed: () => context.go(visit.route),
                child: const Text('Voltar à visita'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
