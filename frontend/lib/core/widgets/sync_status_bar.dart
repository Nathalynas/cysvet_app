import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/core/enums/sync_status_enum.dart';
import 'package:cysvet_app/core/presentation/app_scaffold_messenger.dart';
import 'package:cysvet_app/providers/connectivity_provider.dart';
import 'package:cysvet_app/providers/sync_provider.dart';

/// Faixa global do mobile com o estado da sincronização: modo offline,
/// pendências, sincronizando, erro — e botão de sincronização manual.
/// Some quando está tudo sincronizado e online.
class SyncStatusBar extends ConsumerWidget {
  const SyncStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncControllerProvider);
    final isOffline = ref.watch(isOfflineProvider);

    if (!sync.enabled) return const SizedBox.shrink();
    if (!isOffline && sync.status == SyncStatusEnum.synced) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final pending = sync.pendingCount;
    final pendingLabel = pending == 1
        ? '1 registro pendente'
        : '$pending registros pendentes';

    final ({
      IconData icon,
      String title,
      String? subtitle,
      Color background,
      Color foreground,
    })
    view;
    if (isOffline) {
      view = (
        icon: Icons.wifi_off,
        title: 'Modo offline',
        subtitle: pending == 0
            ? 'Os registros serão salvos no aparelho.'
            : '$pendingLabel · salvos no aparelho.',
        background: colorScheme.tertiaryContainer,
        foreground: colorScheme.onTertiaryContainer,
      );
    } else if (sync.isSyncing) {
      view = (
        icon: Icons.sync,
        title: 'Sincronizando...',
        subtitle: pending == 0 ? null : pendingLabel,
        background: colorScheme.secondaryContainer,
        foreground: colorScheme.onSecondaryContainer,
      );
    } else if (sync.status == SyncStatusEnum.error) {
      view = (
        icon: Icons.cloud_off_outlined,
        title: 'Erro ao sincronizar',
        subtitle: sync.lastMessage ?? pendingLabel,
        background: colorScheme.errorContainer,
        foreground: colorScheme.onErrorContainer,
      );
    } else {
      view = (
        icon: Icons.schedule_outlined,
        title: pendingLabel,
        subtitle: sync.lastMessage ?? 'Aguardando sincronização.',
        background: colorScheme.tertiaryContainer,
        foreground: colorScheme.onTertiaryContainer,
      );
    }

    Future<void> syncNow() async {
      final ok = await ref.read(syncControllerProvider.notifier).syncNow();
      final state = ref.read(syncControllerProvider);
      if (!ok) {
        showAppWarning(
          state.lastMessage ?? 'Não foi possível sincronizar agora.',
        );
      } else if (state.errorCount > 0) {
        showAppWarning('Alguns registros não puderam ser sincronizados.');
      } else if (state.pendingCount == 0) {
        showAppSuccess('Dados sincronizados.');
      }
    }

    return Material(
      color: view.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            if (sync.isSyncing)
              SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: view.foreground,
                ),
              )
            else
              Icon(view.icon, size: 20, color: view.foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    view.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: view.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (view.subtitle != null)
                    Text(
                      view.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: view.foreground),
                    ),
                ],
              ),
            ),
            if (!isOffline && !sync.isSyncing && pending > 0)
              TextButton.icon(
                onPressed: syncNow,
                style: TextButton.styleFrom(foregroundColor: view.foreground),
                icon: const Icon(Icons.sync, size: 18),
                label: Text(
                  sync.status == SyncStatusEnum.error
                      ? 'Tentar novamente'
                      : 'Sincronizar',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
