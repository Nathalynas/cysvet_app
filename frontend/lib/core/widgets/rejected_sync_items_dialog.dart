import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/core/widgets/app_dialog.dart';
import 'package:cysvet_app/models/sync_models.dart';
import 'package:cysvet_app/providers/sync_provider.dart';

/// Lista o que o servidor recusou, com o motivo, e deixa o usuário decidir:
/// tentar de novo ou descartar (a visita volta a ser rascunho no aparelho).
Future<void> showRejectedSyncItemsDialog(BuildContext context) {
  return AppDialog.show<void>(
    context: context,
    title: 'Não aceitos pelo servidor',
    width: 560,
    content: const _RejectedSyncItems(),
  );
}

class _RejectedSyncItems extends ConsumerStatefulWidget {
  const _RejectedSyncItems();

  @override
  ConsumerState<_RejectedSyncItems> createState() => _RejectedSyncItemsState();
}

class _RejectedSyncItemsState extends ConsumerState<_RejectedSyncItems> {
  late Future<List<SyncMutation>> _items = _load();

  Future<List<SyncMutation>> _load() =>
      ref.read(syncControllerProvider.notifier).rejectedItems();

  Future<void> _act(Future<void> Function() action) async {
    await action();
    if (!mounted) return;
    setState(() => _items = _load());
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(syncControllerProvider.notifier);
    final theme = Theme.of(context);

    return FutureBuilder<List<SyncMutation>>(
      future: _items,
      builder: (context, snapshot) {
        final items = snapshot.data;
        if (items == null) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Nenhum registro recusado.'),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Estes registros continuam salvos no aparelho, mas o servidor '
              'não aceitou. Descartar uma visita a deixa como rascunho para '
              'corrigir e finalizar de novo.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final item in items)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SyncController.describeMutation(item),
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.lastError ?? 'Sem motivo informado.',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: () =>
                                _act(() => controller.retryRejected(item)),
                            child: const Text('Tentar de novo'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: () =>
                                _act(() => controller.discardRejected(item)),
                            child: const Text('Descartar do envio'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
