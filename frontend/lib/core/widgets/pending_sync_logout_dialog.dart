import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/core/widgets/app_button.dart';
import 'package:cysvet_app/core/widgets/app_dialog.dart';
import 'package:cysvet_app/providers/sync_provider.dart';

enum _PendingSyncChoice { sync, leave }

/// Confirma a saída quando há alterações ainda não enviadas.
///
/// A fila é por usuário e fica no aparelho: depois de sair, ela só é enviada
/// quando a mesma conta entrar de novo neste aparelho. Retorna `true` quando
/// pode sair.
Future<bool> confirmLogoutWithPendingSync(
  BuildContext context,
  WidgetRef ref,
) async {
  while (true) {
    final sync = ref.read(syncControllerProvider);
    if (!sync.enabled || sync.pendingCount == 0) return true;
    if (!context.mounted) return false;

    final choice = await AppDialog.show<_PendingSyncChoice>(
      context: context,
      title: 'Alterações não enviadas',
      content: _PendingSyncMessage(state: sync),
      actions: [
        Builder(
          builder: (dialogContext) => AppButton(
            text: 'Sair mesmo assim',
            outlined: true,
            height: 40,
            fontSize: 14,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: () =>
                Navigator.of(dialogContext).pop(_PendingSyncChoice.leave),
          ),
        ),
        Builder(
          builder: (dialogContext) => AppButton(
            text: 'Sincronizar agora',
            height: 40,
            fontSize: 14,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: () =>
                Navigator.of(dialogContext).pop(_PendingSyncChoice.sync),
          ),
        ),
      ],
    );

    if (choice == _PendingSyncChoice.leave) return true;
    if (choice != _PendingSyncChoice.sync) return false;

    // Se ainda restar pendência (sem conexão ou item recusado), o aviso volta
    // com a contagem e a mensagem atualizadas.
    await ref.read(syncControllerProvider.notifier).syncNow();
  }
}

class _PendingSyncMessage extends StatelessWidget {
  const _PendingSyncMessage({required this.state});

  final SyncState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = state.pendingCount;
    final lastMessage = state.lastMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count == 1
              ? '1 alteração ainda não foi enviada ao servidor.'
              : '$count alterações ainda não foram enviadas ao servidor.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Elas continuam salvas neste aparelho, mas só serão enviadas '
          'quando você entrar novamente com esta conta aqui.',
          style: theme.textTheme.bodyMedium,
        ),
        if (state.errorCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            '${state.errorCount} com erro: revise antes de sair.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        if (lastMessage != null && lastMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            lastMessage,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
