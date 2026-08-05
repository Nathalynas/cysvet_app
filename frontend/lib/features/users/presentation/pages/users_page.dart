import 'package:cysvet_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../app/app_shell.dart';
import '../../../../app/theme.dart';
import '../../../../core/enums/user_status.dart';
import '../../../../core/presentation/app_scaffold_messenger.dart';
import '../../../../core/presentation/async_value_view.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_table.dart';
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
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              PageTitle(
                title: 'Usuários',
                subtitle: 'Administre os usuários com acesso ao sistema.',
                headerButton: AppButton(
                  text: 'Novo usuário',
                  icon: const Icon(Icons.add),
                  onPressed: () => UserDialog.show(context),
                ),
              ),
              Padding(
                padding: PageTitle.contentPadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _UsersToolbar(
                      searchQuery: searchQuery,
                      statusFilter: statusFilter,
                      onSearchChanged: (value) {
                        ref.read(usersSearchQueryProvider.notifier).state =
                            value;
                      },
                      onStatusChanged: (value) {
                        ref.read(usersStatusFilterProvider.notifier).state =
                            value ?? UserStatusFilter.all;
                      },
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

                        return _UsersTable(
                          users: filteredItems,
                          onEdit: (user) =>
                              UserDialog.show(context, user: user),
                          onInactivate: (user) =>
                              _confirmInactivate(context, ref, user),
                          onActivate: (user) =>
                              _confirmActivate(context, ref, user),
                          onDelete: (user) =>
                              _confirmDelete(context, ref, user),
                        );
                      },
                    ),
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

class _UsersToolbar extends StatefulWidget {
  const _UsersToolbar({
    required this.searchQuery,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
  });

  final String searchQuery;
  final UserStatusFilter statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<UserStatusFilter?> onStatusChanged;

  @override
  State<_UsersToolbar> createState() => _UsersToolbarState();
}

class _UsersToolbarState extends State<_UsersToolbar> {
  bool _filtersOpen = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.sizeOf(context).width < MOBILE_WIDTH;
        final stacked = constraints.maxWidth < 720;
        final search = SearchCard(
          value: widget.searchQuery,
          labelText: 'Pesquisar usuários',
          onChanged: widget.onSearchChanged,
        );
        final status = AppDropdown<UserStatusFilter>(
          value: widget.statusFilter,
          labelText: 'Status',
          onChanged: widget.onStatusChanged,
          options: UserStatusFilter.values
              .map((item) => AppDropdownOption(label: item.label, value: item))
              .toList(growable: false),
        );

        final filterButton = Tooltip(
          message: _filtersOpen ? 'Ocultar filtros' : 'Mostrar filtros',
          child: AppButton(
            outlined: _filtersOpen,
            onPressed: () {
              setState(() => _filtersOpen = !_filtersOpen);
            },
            child: Icon(
              _filtersOpen
                  ? Icons.filter_alt_off_outlined
                  : Icons.filter_alt_outlined,
            ),
          ),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: 10),
                  filterButton,
                ],
              ),
              if (_filtersOpen) ...[const SizedBox(height: 10), status],
            ],
          );
        }

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [search, const SizedBox(height: 10), status],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: search),
            const SizedBox(width: 12),
            SizedBox(width: 200, child: status),
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
  final normalizedQuery = query.trim().normalize();

  return items.where((user) {
    final matchesStatus = switch (statusFilter) {
      UserStatusFilter.all => true,
      UserStatusFilter.active => user.status == UserStatus.active,
      UserStatusFilter.inactive => user.status == UserStatus.inactive,
    };
    final searchableText = [
      user.name,
      user.email,
      user.displayRole,
      user.companyName ?? '',
    ].join(' ').normalize();
    return matchesStatus &&
        (normalizedQuery.isEmpty || searchableText.contains(normalizedQuery));
  }).toList();
}

typedef _UserCallback = void Function(UserSummaryModel user);

class _UsersTable extends StatelessWidget {
  const _UsersTable({
    required this.users,
    required this.onEdit,
    required this.onInactivate,
    required this.onActivate,
    required this.onDelete,
  });

  final List<UserSummaryModel> users;
  final _UserCallback onEdit;
  final _UserCallback onInactivate;
  final _UserCallback onActivate;
  final _UserCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < MOBILE_WIDTH;

    if (isMobile) {
      return _UsersMobileList(
        users: users,
        onEdit: onEdit,
        onInactivate: onInactivate,
        onActivate: onActivate,
        onDelete: onDelete,
      );
    }

    return AppTable<UserSummaryModel>(
      rows: users,
      equalColumnWidth: true,
      emptyMessage: 'Nenhum usuário encontrado para os filtros atuais.',
      footerLabel: _recordsLabel(users.length),
      columns: [
        AppTableColumn<UserSummaryModel>(
          label: 'Usuário',
          alignment: Alignment.centerLeft,
          cellBuilder: (context, user) => _UserIdentityCell(user: user),
        ),
        AppTableColumn<UserSummaryModel>(
          label: 'Perfil',
          alignment: Alignment.center,
          cellBuilder: (context, user) =>
              Center(child: _UserRoleBadge(user: user)),
        ),
        AppTableColumn<UserSummaryModel>(
          label: 'Empresa',
          alignment: Alignment.center,
          cellBuilder: (context, user) => Center(
            child: Text(
              _dashIfBlank(user.companyName),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        AppTableColumn<UserSummaryModel>(
          label: 'Status',
          alignment: Alignment.center,
          cellBuilder: (context, user) =>
              Center(child: _UserStatusBadge(user: user)),
        ),
        AppTableColumn<UserSummaryModel>(
          label: 'Ações',
          alignment: Alignment.center,
          cellBuilder: (context, user) {
            return Center(
              child: _UserActions(
                user: user,
                onEdit: () => onEdit(user),
                onInactivate: () => onInactivate(user),
                onActivate: () => onActivate(user),
                onDelete: () => onDelete(user),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _UsersMobileList extends StatelessWidget {
  const _UsersMobileList({
    required this.users,
    required this.onEdit,
    required this.onInactivate,
    required this.onActivate,
    required this.onDelete,
  });

  final List<UserSummaryModel> users;
  final _UserCallback onEdit;
  final _UserCallback onInactivate;
  final _UserCallback onActivate;
  final _UserCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const AppCard(
        padding: EdgeInsets.all(24),
        borderRadius: 16,
        shadow: false,
        child: Text(
          'Nenhum usuário encontrado para os filtros atuais.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final user in users) ...[
          _UserMobileCard(
            user: user,
            onEdit: () => onEdit(user),
            onInactivate: () => onInactivate(user),
            onActivate: () => onActivate(user),
            onDelete: () => onDelete(user),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          _recordsLabel(users.length),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _UserMobileCard extends StatelessWidget {
  const _UserMobileCard({
    required this.user,
    required this.onEdit,
    required this.onInactivate,
    required this.onActivate,
    required this.onDelete,
  });

  final UserSummaryModel user;
  final VoidCallback onEdit;
  final VoidCallback onInactivate;
  final VoidCallback onActivate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      borderColor: colorScheme.outlineVariant.withValues(alpha: 0.8),
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usuário:',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _UserIdentityCell(user: user),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _UserStatusBadge(user: user),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Perfil',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: _UserRoleBadge(user: user),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Empresa:',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _dashIfBlank(user.companyName),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _UserActions(
                user: user,
                alignment: WrapAlignment.end,
                onEdit: onEdit,
                onInactivate: onInactivate,
                onActivate: onActivate,
                onDelete: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserIdentityCell extends StatelessWidget {
  const _UserIdentityCell({required this.user});

  final UserSummaryModel user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          user.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _UserRoleBadge extends StatelessWidget {
  const _UserRoleBadge({required this.user});

  final UserSummaryModel user;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: user.displayRole,
      type: StatusBadgeType.neutral,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.72)
          : const Color(0xFFECEFEC),
      foregroundColor: user.isAdmin
          ? Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF9096E6)
              : AppTheme.indigoColor
          : Theme.of(context).colorScheme.onSurfaceVariant,
      borderColor: Colors.transparent,
      icon: user.isAdmin
          ? Icons.admin_panel_settings_outlined
          : Icons.badge_outlined,
    );
  }
}

class _UserStatusBadge extends StatelessWidget {
  const _UserStatusBadge({required this.user});

  final UserSummaryModel user;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: user.status.label,
      type: user.status == UserStatus.active
          ? StatusBadgeType.success
          : StatusBadgeType.neutral,
      backgroundColor: user.status == UserStatus.active
          ? Theme.of(context).brightness == Brightness.dark
              ? AppTheme.syncBadgeDarkBackgroundColor
              : AppTheme.syncBadgeBackgroundColor
          : null,
      foregroundColor: user.status == UserStatus.active
          ? Theme.of(context).brightness == Brightness.dark
              ? AppTheme.syncBadgeDarkForegroundColor
              : AppTheme.syncBadgeForegroundColor
          : null,
      borderColor: user.status == UserStatus.active
          ? Colors.transparent
          : null,
    );
  }
}

class _UserActions extends StatelessWidget {
  const _UserActions({
    required this.user,
    required this.onEdit,
    required this.onInactivate,
    required this.onActivate,
    required this.onDelete,
    this.alignment = WrapAlignment.end,
  });

  final UserSummaryModel user;
  final VoidCallback onEdit;
  final VoidCallback onInactivate;
  final VoidCallback onActivate;
  final VoidCallback onDelete;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canManageMembership = !user.isAdmin;
    final isInactive = user.status == UserStatus.inactive;
    final toggleTooltip = isInactive ? 'Ativar' : 'Inativar';

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: [
        _UserActionIconButton(
          tooltip: 'Editar',
          icon: Icons.edit_outlined,
          disabled: !canManageMembership,
          onPressed: onEdit,
        ),
        _UserActionIconButton(
          tooltip: toggleTooltip,
          icon: isInactive ? Icons.unarchive_outlined : Icons.archive_outlined,
          disabled: !canManageMembership,
          onPressed: isInactive ? onActivate : onInactivate,
        ),
        _UserActionIconButton(
          tooltip: 'Excluir',
          icon: Icons.delete_outline,
          color: colorScheme.error,
          disabled: !canManageMembership,
          onPressed: onDelete,
        ),
      ],
    );
  }
}

class _UserActionIconButton extends StatelessWidget {
  const _UserActionIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
    this.disabled = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return Tooltip(
      message: tooltip,
      child: AppButton(
        outlined: true,
        width: 36,
        height: 36,
        padding: EdgeInsets.zero,
        color: effectiveColor,
        textColor: effectiveColor,
        borderColor: Colors.transparent,
        shadow: false,
        disabled: disabled,
        onPressed: onPressed,
        child: Icon(icon, size: 18),
      ),
    );
  }
}

String _dashIfBlank(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return '--';
  return normalized;
}

String _recordsLabel(int count) {
  if (count == 1) return '1 usuário encontrado';
  return '$count usuários encontrados';
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
    content: Text('Deseja remover ${user.name} da empresa ativa?'),
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
