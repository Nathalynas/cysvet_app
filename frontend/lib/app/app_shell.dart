// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/widgets/app_button.dart';
import '../features/auth/application/auth_state.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const double _desktopMenuWidth = 214;
  static const double _mobileDrawerWidth = 232;
  static const int _mobileBottomItemCount = 4;

  static const _items = [
    _NavigationItem(
      route: '/dashboard',
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _NavigationItem(
      route: '/propriedades',
      label: 'Propriedades',
      icon: Icons.agriculture_outlined,
      selectedIcon: Icons.agriculture,
    ),
    _NavigationItem(
      route: '/animais',
      label: 'Animais',
      icon: MdiIcons.cow,
      selectedIcon: MdiIcons.cow,
    ),
    _NavigationItem(
      route: '/visitas',
      label: 'Visitas',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
    ),
    _NavigationItem(
      route: '/usuarios',
      label: 'Usuários',
      icon: Icons.group_outlined,
      selectedIcon: Icons.group,
    ),
    _NavigationItem(
      route: '/configuracoes',
      label: 'Configurações',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _getCurrentIndex(context);
    final pageHeader = _getPageHeader(context);
    final session = ref.watch(authSessionProvider);
    final isMobile = MediaQuery.of(context).size.width < MOBILE_WIDTH;

    if (!isMobile) {
      return Scaffold(
        body: Column(
          children: [
            _MainHeader(
              session: session,
              showMenuButton: false,
              onMenuPressed: null,
            ),
            Expanded(
              child: Row(
                children: [
                  _DesktopNavigationMenu(
                    currentIndex: currentIndex,
                    onDestinationSelected: (index) {
                      _onDestinationSelected(context, index);
                    },
                  ),
                  Expanded(child: _ShellContent(child: child)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      drawerEnableOpenDragGesture: false,
      drawer: _MobileNavigationDrawer(
        currentIndex: currentIndex,
        onDestinationSelected: (index) {
          _onDestinationSelected(context, index);
        },
      ),
      body: Builder(
        builder: (scaffoldContext) {
          return Column(
            children: [
              _MainHeader(
                session: session,
                showMenuButton: pageHeader.backRoute == null,
                onMenuPressed: () {
                  Scaffold.of(scaffoldContext).openDrawer();
                },
                backRoute: pageHeader.backRoute,
              ),
              Expanded(child: _ShellContent(child: child)),
            ],
          );
        },
      ),
      bottomNavigationBar: _MobileNavigationBar(
        currentIndex: currentIndex,
        onDestinationSelected: (index) {
          _onDestinationSelected(context, index);
        },
      ),
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    for (var index = 1; index < _items.length; index++) {
      if (location.startsWith(_items[index].route)) {
        return index;
      }
    }

    return 0;
  }

  _PageHeaderConfig _getPageHeader(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    if (location.startsWith('/visitas/nova')) {
      return const _PageHeaderConfig(backRoute: '/visitas');
    }

    if (location.startsWith('/visitas/') && location.endsWith('/detalhes')) {
      return const _PageHeaderConfig(backRoute: '/visitas');
    }

    return const _PageHeaderConfig();
  }

  void _onDestinationSelected(BuildContext context, int index) {
    context.go(_items[index].route);
  }
}

class _PageHeaderConfig {
  const _PageHeaderConfig({this.backRoute});

  final String? backRoute;
}

class _NavigationItem {
  const _NavigationItem({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _MainHeader extends ConsumerWidget {
  const _MainHeader({
    required this.session,
    required this.showMenuButton,
    required this.onMenuPressed,
    this.backRoute,
  });

  final dynamic session;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;
  final String? backRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < MOBILE_WIDTH;

    final logoAsset = Theme.of(context).brightness == Brightness.dark
        ? 'assets/images/logo_branco.png'
        : 'assets/images/logo.png';

    dynamic activeCompany;

    if (session != null) {
      for (final company in session.companies) {
        if (company.id == session.activeCompanyId) {
          activeCompany = company;
          break;
        }
      }
    }

    final companyName = activeCompany?.name ?? 'Empresa não informada';
    final userName = session?.user.name ?? '';
    final userEmail = session?.user.email ?? '';

    return Material(
      color: colorScheme.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 64,
            child: Padding(
              padding: EdgeInsets.only(
                left: isMobile ? 8 : 16,
                right: isMobile ? 12 : 20,
              ),
              child: isMobile
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _HeaderNavigationButton(
                            backRoute: backRoute,
                            showMenuButton: showMenuButton,
                            onMenuPressed: onMenuPressed,
                          ),
                        ),
                        Image.asset(
                          logoAsset,
                          height: 38,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _UserAvatarMenu(
                            userName: userName,
                            userEmail: userEmail,
                            onProfile: () => context.go('/configuracoes'),
                            onCompany: () => context.go('/configuracoes'),
                            onLogout: () async {
                              await ref.read(authControllerProvider).logout();

                              if (!context.mounted) {
                                return;
                              }

                              context.go('/login');
                            },
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        SizedBox(
                          width: 155,
                          child: Image.asset(
                            logoAsset,
                            height: 44,
                            fit: BoxFit.contain,
                            alignment: Alignment.centerLeft,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          height: 36,
                          child: VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: Colors.grey.shade300,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _HeaderUserCompanyInfo(
                            companyName: companyName,
                            userName: userName,
                          ),
                        ),
                        _UserAvatarMenu(
                          userName: userName,
                          userEmail: userEmail,
                          onProfile: () => context.go('/configuracoes'),
                          onCompany: () => context.go('/configuracoes'),
                          onLogout: () async {
                            await ref.read(authControllerProvider).logout();

                            if (!context.mounted) {
                              return;
                            }

                            context.go('/login');
                          },
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderNavigationButton extends StatelessWidget {
  const _HeaderNavigationButton({
    required this.backRoute,
    required this.showMenuButton,
    required this.onMenuPressed,
  });

  final String? backRoute;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (backRoute != null) {
      return IconButton(
        tooltip: 'Voltar',
        icon: const Icon(Icons.arrow_back),
        color: colorScheme.primary,
        onPressed: () => context.go(backRoute!),
      );
    }

    if (showMenuButton) {
      return IconButton(
        tooltip: 'Abrir menu',
        icon: const Icon(Icons.menu),
        color: colorScheme.primary,
        onPressed: onMenuPressed,
      );
    }

    return const SizedBox(width: 48);
  }
}

class _HeaderUserCompanyInfo extends StatelessWidget {
  const _HeaderUserCompanyInfo({
    required this.companyName,
    required this.userName,
  });

  final String companyName;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          companyName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          userName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _ShellContent extends StatelessWidget {
  const _ShellContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: child,
    );
  }
}

class PageTitle extends StatelessWidget {
  const PageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.backRoute,
    this.headerButton,
    this.headerFilter,
  });

  final String title;
  final String? subtitle;
  final String? backRoute;
  final Widget? headerButton;
  final Widget? headerFilter;

  static const double _mobileHorizontalPadding = 16;
  static const double _desktopHorizontalPadding = 30;
  static const double _contentTopPadding = 8;
  static const double _contentBottomPadding = 16;

  static double horizontalPadding(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < MOBILE_WIDTH;
    return isMobile ? _mobileHorizontalPadding : _desktopHorizontalPadding;
  }

  static EdgeInsets contentPadding(BuildContext context) {
    final horizontal = horizontalPadding(context);
    return EdgeInsets.fromLTRB(
      horizontal,
      _contentTopPadding,
      horizontal,
      _contentBottomPadding,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < MOBILE_WIDTH;
    final horizontal = PageTitle.horizontalPadding(context);
    final pageSubtitle = subtitle;
    final hasHeaderActions = headerFilter != null || headerButton != null;

    Widget titleContent() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: isMobile ? 21 : 22,
            ),
          ),
          if (pageSubtitle != null && pageSubtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              pageSubtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: isMobile ? 13 : 14,
              ),
            ),
          ],
        ],
      );
    }

    Widget titleRow({required bool expanded}) {
      final title = titleContent();

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (backRoute != null && !isMobile) ...[
            Tooltip(
              message: 'Voltar',
              child: AppButton(
                outlined: true,
                width: 40,
                height: 40,
                padding: EdgeInsets.zero,
                borderRadius: 12,
                color: colorScheme.primary,
                textColor: colorScheme.primary,
                borderColor: Colors.transparent,
                onPressed: () => context.go(backRoute!),
                child: const Icon(Icons.arrow_back),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (expanded) Expanded(child: title) else Flexible(child: title),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        horizontal,
        isMobile ? 16 : 24,
        horizontal,
        isMobile ? 10 : 12,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!hasHeaderActions) {
            return titleRow(expanded: true);
          }

          final actions = _PageTitleHeaderActions(
            headerFilter: headerFilter,
            headerButton: headerButton,
          );
          final inline = constraints.maxWidth >= 760;

          if (!inline) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleRow(expanded: false),
                const SizedBox(height: 12),
                actions,
              ],
            );
          }

          final maxActionsWidth = math.min(
            math.max(0.0, constraints.maxWidth - 220.0),
            760.0,
          );

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleRow(expanded: true)),
              const SizedBox(width: 16),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxActionsWidth),
                child: actions,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PageTitleHeaderActions extends StatelessWidget {
  const _PageTitleHeaderActions({
    required this.headerButton,
    required this.headerFilter,
  });

  final Widget? headerButton;
  final Widget? headerFilter;

  @override
  Widget build(BuildContext context) {
    final filter = headerFilter;
    final button = headerButton;

    if (filter == null && button == null) {
      return const SizedBox.shrink();
    }

    if (filter == null) {
      return Align(alignment: Alignment.centerRight, child: button!);
    }

    if (button == null) {
      return filter;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              filter,
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerRight, child: button),
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(child: filter),
            const SizedBox(width: 12),
            button,
          ],
        );
      },
    );
  }
}

class _DesktopNavigationMenu extends StatelessWidget {
  const _DesktopNavigationMenu({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return _NavigationMenuSurface(
      currentIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      isDrawer: false,
    );
  }
}

class _MobileNavigationDrawer extends StatelessWidget {
  const _MobileNavigationDrawer({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: AppShell._mobileDrawerWidth,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: _NavigationMenuSurface(
        currentIndex: currentIndex,
        onDestinationSelected: (index) {
          Navigator.of(context).pop();
          onDestinationSelected(index);
        },
        isDrawer: true,
      ),
    );
  }
}

class _NavigationMenuSurface extends StatelessWidget {
  const _NavigationMenuSurface({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.isDrawer,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isDrawer;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: isDrawer
          ? AppShell._mobileDrawerWidth
          : AppShell._desktopMenuWidth,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: isDrawer,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDrawer) ...[
                const _SidebarLogo(),
                Container(
                  height: 1,
                  margin: const EdgeInsets.only(bottom: 14),
                  color: Colors.black.withValues(alpha: 0.10),
                ),
              ],
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (var index = 0; index < AppShell._items.length; index++)
                      _NavigationTile(
                        item: AppShell._items[index],
                        isSelected: currentIndex == index,
                        isCompact: false,
                        isBottomNavigation: false,
                        onTap: () {
                          onDestinationSelected(index);
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

class _SidebarLogo extends StatelessWidget {
  const _SidebarLogo();

  @override
  Widget build(BuildContext context) {
    final logoAsset = Theme.of(context).brightness == Brightness.dark
        ? 'assets/images/logo_branco.png'
        : 'assets/images/logo.png';

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Image.asset(
            logoAsset,
            width: 178,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}

class _MobileNavigationBar extends StatelessWidget {
  const _MobileNavigationBar({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.45),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Row(
              children: [
                for (
                  var index = 0;
                  index < AppShell._mobileBottomItemCount;
                  index++
                )
                  Expanded(
                    child: _NavigationTile(
                      item: AppShell._items[index],
                      isSelected: currentIndex == index,
                      isCompact: true,
                      isBottomNavigation: true,
                      onTap: () {
                        onDestinationSelected(index);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationTile extends StatefulWidget {
  const _NavigationTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.isCompact,
    required this.isBottomNavigation,
  });

  final _NavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCompact;
  final bool isBottomNavigation;

  @override
  State<_NavigationTile> createState() => _NavigationTileState();
}

class _NavigationTileState extends State<_NavigationTile> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final isSelected = widget.isSelected;

    final backgroundColor = isSelected
        ? colorScheme.surfaceContainerHighest
        : Colors.transparent;

    final itemColor = isSelected ? primary : colorScheme.onSurfaceVariant;

    final iconColor = isSelected
        ? itemColor
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.72);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: widget.isBottomNavigation ? 2 : 10,
          vertical: widget.isBottomNavigation ? 0 : 3,
        ),
        child: Stack(
          children: [
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12),
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                focusColor: Colors.transparent,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                child: Container(
                  height: widget.isBottomNavigation ? 52 : null,
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isCompact ? 4 : 12,
                    vertical: widget.isCompact ? 4 : 11,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconTheme(
                    data: IconThemeData(
                      color: iconColor,
                      size: widget.isCompact ? 21 : 20,
                    ),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: itemColor,
                        fontSize: widget.isCompact ? 11 : 14,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                      child: widget.isCompact
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(widget.item.icon),
                                const SizedBox(height: 2),
                                Text(
                                  widget.item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Icon(widget.item.icon),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    widget.item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
            if (isSelected && !widget.isBottomNavigation)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: primary, width: 3)),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
              ),
            if (isSelected && widget.isBottomNavigation)
              Positioned(
                left: 14,
                right: 14,
                top: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UserAvatarMenu extends StatelessWidget {
  const _UserAvatarMenu({
    required this.userName,
    required this.userEmail,
    required this.onProfile,
    required this.onCompany,
    required this.onLogout,
  });

  final String userName;
  final String userEmail;
  final VoidCallback onProfile;
  final VoidCallback onCompany;
  final Future<void> Function() onLogout;

  String getInitials(String? name) {
    if (name == null || name.trim().isEmpty) {
      return '';
    }

    final names = name.trim().split(' ').where((item) => item.isNotEmpty);

    if (names.isEmpty) {
      return '';
    }

    final namesList = names.toList();

    if (namesList.length == 1) {
      return namesList.first[0].toUpperCase();
    }

    return '${namesList.first[0]}${namesList.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = getInitials(userName);
    final primary = Theme.of(context).colorScheme.primary;
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      offset: const Offset(0, 55),
      elevation: 8,
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surface,
      tooltip: '',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            onProfile();
            break;
          case 'company':
            onCompany();
            break;
          case 'logout':
            await onLogout();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: primary,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      userEmail,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          enabled: false,
          height: 12,
          child: SizedBox.shrink(),
        ),
        const PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, color: Colors.grey),
              SizedBox(width: 12),
              Text('Meu Perfil'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 12),
              Text('Sair', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: CircleAvatar(
          radius: 19,
          backgroundColor: primary,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
