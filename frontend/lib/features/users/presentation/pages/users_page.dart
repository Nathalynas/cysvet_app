import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/enums/user_status.dart';
import '../../../../core/presentation/app_scaffold_messenger.dart';
import '../../../../core/presentation/async_value_view.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/search_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../application/users_provider.dart';
import '../../domain/user_summary_model.dart';
import '../widgets/user_dialog.dart';

final usersSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final usersStatusFilterProvider = StateProvider.autoDispose<UserStatusFilter>((
  ref,
) {
  return UserStatusFilter.active;
});

class UsuariosPage extends ConsumerWidget {
  const UsuariosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);
    final searchQuery = ref.watch(usersSearchQueryProvider);
    final statusFilter = ref.watch(usersStatusFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(usersProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _UsersToolbar(
                searchQuery: searchQuery,
                statusFilter: statusFilter,
                onSearchChanged: (value) {
                  ref.read(usersSearchQueryProvider.notifier).state = value;
                },
                onStatusChanged: (value) {
                  ref.read(usersStatusFilterProvider.notifier).state =
                      value ?? UserStatusFilter.all;
                },
                onCreate: () => UserDialog.show(context),
              ),
              const SizedBox(height: 16),
              AsyncValueView<List<UserSummaryModel>>(
                value: users,
                loadingMessage: 'Buscando usuários...',
                emptyMessage: 'Nenhum usuário cadastrado.',
                isEmpty: (items) => items.isEmpty,
                onRetry: () => ref.invalidate(usersProvider),
                builder: (items) {
                  final filteredItems = _filterUsers(
                    items,
                    searchQuery,
                    statusFilter,
                  );

                  if (filteredItems.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(
                        child: Text(
                          'Nenhum usuário encontrado para os filtros atuais.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (final user in filteredItems) ...[
                        _UserCard(
                          user: user,
                          onInactivate: () =>
                              _confirmInactivate(context, ref, user),
                          onActivate: () =>
                              _confirmActivate(context, ref, user),
                          onDelete: () => _confirmDelete(context, ref, user),
                        ),
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

class _UsersToolbar extends StatelessWidget {
  const _UsersToolbar({
    required this.searchQuery,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onCreate,
  });

  final String searchQuery;
  final UserStatusFilter statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<UserStatusFilter?> onStatusChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 720;
        final search = SearchCard(
          value: searchQuery,
          labelText: 'Pesquisar usuários',
          onChanged: onSearchChanged,
        );
        final status = AppDropdown<UserStatusFilter>(
          value: statusFilter,
          labelText: 'Status',
          onChanged: onStatusChanged,
          options: UserStatusFilter.values
              .map((item) => AppDropdownOption(label: item.label, value: item))
              .toList(growable: false),
        );
        final button = AppButton(
          text: 'Novo usuário',
          icon: const Icon(Icons.add),
          onPressed: onCreate,
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 10),
              status,
              const SizedBox(height: 10),
              button,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: search),
            const SizedBox(width: 12),
            SizedBox(width: 200, child: status),
            const SizedBox(width: 12),
            button,
          ],
        );
      },
    );
  }
}

List<UserSummaryModel> _filterUsers(
  List<UserSummaryModel> items,
  String query,
  UserStatusFilter statusFilter,
) {
  final normalizedQuery = _normalize(query.trim());

  return items.where((user) {
    final matchesStatus = switch (statusFilter) {
      UserStatusFilter.all => true,
      UserStatusFilter.active => user.status == UserStatus.active,
      UserStatusFilter.inactive => user.status == UserStatus.inactive,
    };
    final searchableText = _normalize(
      [
        user.name,
        user.email,
        user.displayRole,
        user.companyName ?? '',
      ].join(' '),
    );
    return matchesStatus &&
        (normalizedQuery.isEmpty || searchableText.contains(normalizedQuery));
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

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onInactivate,
    required this.onActivate,
    required this.onDelete,
  });

  final UserSummaryModel user;
  final VoidCallback onInactivate;
  final VoidCallback onActivate;
  final VoidCallback onDelete;

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
                const Icon(Icons.badge_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    user.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                StatusBadge(
                  label: user.status.label,
                  type: user.status == UserStatus.active
                      ? StatusBadgeType.success
                      : StatusBadgeType.neutral,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoLine(label: 'E-mail', value: user.email),
            _InfoLine(label: 'Perfil', value: user.displayRole),
            _InfoLine(label: 'Empresa', value: user.companyName ?? '--'),
            const SizedBox(height: 12),
            _CardActionRow(
              leadingActions: const [],
              trailingActions: [
                AppButton(
                  text: user.status == UserStatus.inactive
                      ? 'Ativar'
                      : 'Inativar',
                  outlined: true,
                  height: 40,
                  icon: Icon(
                    user.status == UserStatus.inactive
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                    size: 18,
                  ),
                  onPressed: user.status == UserStatus.inactive
                      ? onActivate
                      : onInactivate,
                ),
                IconButton(
                  tooltip: 'Excluir',
                  color: colorScheme.error,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardActionRow extends StatelessWidget {
  const _CardActionRow({
    required this.leadingActions,
    required this.trailingActions,
  });

  final List<Widget> leadingActions;
  final List<Widget> trailingActions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: leadingActions),
        const Spacer(),
        Wrap(spacing: 8, runSpacing: 8, children: trailingActions),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmInactivate(
  BuildContext context,
  WidgetRef ref,
  UserSummaryModel user,
) {
  return AppDialog.show<void>(
    context: context,
    title: 'Inativar usuário',
    content: Text('Deseja inativar ${user.name}?'),
    confirmText: 'Inativar',
    cancelText: 'Cancelar',
    onConfirm: () async {
      final navigator = Navigator.of(context, rootNavigator: true);
      try {
        await ref.read(usersControllerProvider).inactivate(user.id);
        if (context.mounted) {
          await navigator.maybePop();
          showAppSuccess('Usuário inativado com sucesso.');
        }
      } catch (error) {
        showAppError(error);
      }
    },
  );
}

Future<void> _confirmActivate(
  BuildContext context,
  WidgetRef ref,
  UserSummaryModel user,
) {
  return AppDialog.show<void>(
    context: context,
    title: 'Ativar usuário',
    content: Text('Deseja ativar ${user.name}?'),
    confirmText: 'Ativar',
    cancelText: 'Cancelar',
    onConfirm: () async {
      final navigator = Navigator.of(context, rootNavigator: true);
      try {
        await ref.read(usersControllerProvider).activate(user.id);
        if (context.mounted) {
          await navigator.maybePop();
          showAppSuccess('Usuário ativado com sucesso.');
        }
      } catch (error) {
        showAppError(error);
      }
    },
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  UserSummaryModel user,
) {
  return AppDialog.show<void>(
    context: context,
    title: 'Excluir usuário',
    content: Text('Deseja excluir ${user.name} desta sessão?'),
    confirmText: 'Excluir',
    cancelText: 'Cancelar',
    onConfirm: () async {
      final navigator = Navigator.of(context, rootNavigator: true);
      try {
        await ref.read(usersControllerProvider).delete(user.id);
        if (context.mounted) {
          await navigator.maybePop();
          showAppSuccess('Usuário excluído com sucesso.');
        }
      } catch (error) {
        showAppError(error);
      }
    },
  );
}
