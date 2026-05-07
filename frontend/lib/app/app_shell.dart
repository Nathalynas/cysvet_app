// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _items = [
    _NavigationItem(
      route: '/dashboard',
      label: 'Inicio',
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _NavigationItem(
      route: '/propriedades',
      label: 'Propriedades',
      title: 'Propriedades',
      icon: Icons.agriculture_outlined,
      selectedIcon: Icons.agriculture,
    ),
    _NavigationItem(
      route: '/animais',
      label: 'Animais',
      title: 'Animais',
      icon: MdiIcons.cow,
      selectedIcon: MdiIcons.cow,
    ),
    _NavigationItem(
      route: '/visitas',
      label: 'Visitas',
      title: 'Visitas',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
    ),
    _NavigationItem(
      route: '/usuarios',
      label: 'Usuários',
      title: 'Usuários',
      icon: Icons.group_outlined,
      selectedIcon: Icons.group,
    ),
    _NavigationItem(
      route: '/configuracoes',
      label: 'Configurações',
      title: 'Configurações',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  static const int _mobileBottomItemCount = 4;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _menuIsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);
    final bool isMobile = MediaQuery.of(context).size.width < MOBILE_WIDTH;

    if (!isMobile) {
      final content = _ShellContent(
        title: AppShell._items[currentIndex].title,
        child: widget.child,
      );

      return Scaffold(
        body: Row(
          children: [
            _DesktopNavigationMenu(
              currentIndex: currentIndex,
              onDestinationSelected: (index) {
                _onDestinationSelected(context, index);
              },
              onHoverChanged: (isExpanded) {
                setState(() => _menuIsExpanded = isExpanded);
              },
            ),
            Expanded(
              child: Stack(
                children: [
                  content,
                  if (_menuIsExpanded)
                    Positioned(
                      left: 0,
                      top: 0,
                      right: 0,
                      child: Container(height: 60, color: Colors.transparent),
                    ),
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
          return _ShellContent(
            title: AppShell._items[currentIndex].title,
            showMenuButton: true,
            onMenuPressed: () {
              Scaffold.of(scaffoldContext).openDrawer();
            },
            child: widget.child,
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

    for (var index = 1; index < AppShell._items.length; index++) {
      if (location.startsWith(AppShell._items[index].route)) return index;
    }

    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    context.go(AppShell._items[index].route);
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.route,
    required this.label,
    required this.title,
    required this.icon,
    required this.selectedIcon,
  });

  final String route;
  final String label;
  final String title;
  final IconData icon;
  final IconData selectedIcon;
}

class _ShellContent extends StatelessWidget {
  const _ShellContent({
    required this.title,
    required this.child,
    this.showMenuButton = false,
    this.onMenuPressed,
  });

  final String title;
  final Widget child;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PageHeader(
          title: title,
          showMenuButton: showMenuButton,
          onMenuPressed: onMenuPressed,
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    this.showMenuButton = false,
    this.onMenuPressed,
  });

  final String title;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: EdgeInsets.only(left: showMenuButton ? 8 : 24, right: 24),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colorScheme.outline)),
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              if (showMenuButton) ...[
                IconButton(
                  tooltip: 'Abrir menu',
                  icon: const Icon(Icons.menu),
                  color: colorScheme.onSurface,
                  onPressed: onMenuPressed,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopNavigationMenu extends StatefulWidget {
  const _DesktopNavigationMenu({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.onHoverChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final ValueChanged<bool> onHoverChanged;

  @override
  State<_DesktopNavigationMenu> createState() => _DesktopNavigationMenuState();
}

class _DesktopNavigationMenuState extends State<_DesktopNavigationMenu> {
  bool _isHovering = false;

  @override
  void didUpdateWidget(_DesktopNavigationMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void _updateHover(bool hovering) {
    if (_isHovering != hovering) {
      setState(() => _isHovering = hovering);
      widget.onHoverChanged(hovering);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => _updateHover(true),
      onExit: (_) => _updateHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: _isHovering ? 280 : 80,
        color: colorScheme.surface,
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(_isHovering ? 12 : 12, 16, 12, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 47),
                    Container(
                      height: 1,
                      color: colorScheme.outline,
                      margin: const EdgeInsets.only(bottom: 18),
                    ),
                    for (var index = 0; index < AppShell._items.length; index++)
                      _NavigationTile(
                        item: AppShell._items[index],
                        isSelected: widget.currentIndex == index,
                        isCompact: !_isHovering,
                        isDesktop: true,
                        onTap: () {
                          widget.onDestinationSelected(index);
                        },
                      ),
                  ],
                ),
              ),
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: _isHovering
                      ? Alignment.centerLeft
                      : Alignment.center,
                  padding: EdgeInsets.only(
                    left: _isHovering ? 16 : 0,
                    right: _isHovering ? 12 : 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'C',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: _isHovering ? 90 : 0,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: Text(
                            'YSVET',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 1, color: colorScheme.outline),
              ),
            ],
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 1, color: colorScheme.outline),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
              child: Row(
                children: [
                  for (var index = 0; index < AppShell._mobileBottomItemCount; index++)
                    Expanded(
                      flex: 1,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 80),
                        child: _NavigationTile(
                          item: AppShell._items[index],
                          isSelected: currentIndex == index,
                          isCompact: true,
                          onTap: () {
                            onDestinationSelected(index);
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
              child: Text(
                'CYSVET',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(height: 1, color: colorScheme.outline),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
                children: [
                  for (var index = 0; index < AppShell._items.length; index++)
                    _NavigationTile(
                      item: AppShell._items[index],
                      isSelected: currentIndex == index,
                      isCompact: false,
                      isDesktop: true,
                      onTap: () {
                        Navigator.of(context).pop();
                        onDestinationSelected(index);
                      },
                    ),
                ],
              ),
            ),
          ],
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
    this.isCompact = false,
    this.isDesktop = false,
  });

  final _NavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCompact;
  final bool isDesktop;

  @override
  State<_NavigationTile> createState() => _NavigationTileState();
}

class _NavigationTileState extends State<_NavigationTile> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    final colorScheme = Theme.of(context).colorScheme;

    late final Color textColor;
    late final Color backgroundColor;

    if (widget.isSelected) {
      if (widget.isDesktop) {
        textColor = colorScheme.primary;
        backgroundColor = colorScheme.secondary;
      } else {
        textColor = colorScheme.onPrimary;
        backgroundColor = colorScheme.primary;
      }
    } else if (_isHovering) {
      textColor = colorScheme.onSurface;
      backgroundColor = colorScheme.surfaceContainerHighest;
    } else {
      textColor = colorScheme.onSurfaceVariant;
      backgroundColor = colorScheme.surfaceContainerHighest.withValues(
        alpha: 0,
      );
    }

    final icone = Icon(
      widget.isSelected ? widget.item.selectedIcon : widget.item.icon,
    );

    final content = widget.isCompact
        ? icone
        : Row(
            children: [
              icone,
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: widget.isCompact ? 2 : 0,
          vertical: widget.isCompact ? 0 : 4,
        ),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: widget.isCompact ? 58 : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              height: widget.isDesktop && widget.isCompact
                  ? 50
                  : (widget.isCompact ? 58 : 48),
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCompact ? 4 : 14,
                vertical: widget.isCompact ? 6 : 0,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: IconTheme(
                data: IconThemeData(
                  color: textColor,
                  size: widget.isDesktop ? 24 : (widget.isCompact ? 22 : 24),
                ),
                child: DefaultTextStyle(
                  style: (labelStyle ?? const TextStyle()).copyWith(
                    color: textColor,
                    fontSize: widget.isCompact ? 11 : 14,
                    fontWeight: widget.isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
