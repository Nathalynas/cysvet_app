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
                      child: Container(
                        height: _AppShellSizes.headerHeight,
                        color: Colors.transparent,
                      ),
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
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge;
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: _AppShellSizes.headerHeight,
          padding: EdgeInsets.only(left: showMenuButton ? 8 : 24, right: 24),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              if (showMenuButton) ...[
                IconButton(
                  tooltip: 'Abrir menu',
                  icon: const Icon(Icons.menu),
                  color: colorScheme.primary,
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
                    color: colorScheme.primary,
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

class _AppShellSizes {
  static const double desktopMenuCollapsedWidth = 64;
  static const double menuExpandedWidth = 224;
  static const double headerHeight = 56;

  static const double menuHorizontalPadding = 12;
  static const double menuCompactHorizontalPadding = 8;
  static const double menuVerticalPadding = 16;
  static const double dividerHeight = 1;

  static const double compactDesktopTileWidth = 44;
  static const double compactMobileTileWidth = 52;
  static const double compactDesktopTileHeight = 44;
  static const double compactMobileTileHeight = 48;
  static const double expandedDesktopTileHeight = 42;
  static const double mobileNavigationItemWidth = desktopMenuCollapsedWidth;
  static const double expandedContentMinWidth = 120;
  static const double logoIconSize = 40;
  static const double logoWordmarkWidth = 140;
  static const double logoWordmarkHeight = 36;
  static const double logoTopOffset = (headerHeight - logoIconSize) / 2;
  static const double logoDividerGap = 14;
  static const double logoDividerTopSpacing =
      logoTopOffset + logoIconSize + logoDividerGap - menuVerticalPadding;

  static const EdgeInsets menuPadding = EdgeInsets.fromLTRB(
    menuHorizontalPadding,
    menuVerticalPadding,
    menuHorizontalPadding,
    menuVerticalPadding,
  );
  static const EdgeInsets compactMenuPadding = EdgeInsets.fromLTRB(
    menuCompactHorizontalPadding,
    menuVerticalPadding,
    menuCompactHorizontalPadding,
    menuVerticalPadding,
  );
  static const EdgeInsets mobileNavigationPadding = EdgeInsets.fromLTRB(
    4,
    4,
    4,
    4,
  );
  static const EdgeInsets logoPadding = EdgeInsets.only(left: 16, right: 12);
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
        width: _isHovering
            ? _AppShellSizes.menuExpandedWidth
            : _AppShellSizes.desktopMenuCollapsedWidth,
        color: colorScheme.surface,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isExpandedLayout =
                  _isHovering &&
                  width >= _AppShellSizes.expandedContentMinWidth;

              return Stack(
                children: [
                  Padding(
                    padding: isExpandedLayout
                        ? _AppShellSizes.menuPadding
                        : _AppShellSizes.compactMenuPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: _AppShellSizes.logoDividerTopSpacing,
                        ),
                        Container(
                          height: _AppShellSizes.dividerHeight,
                          color: colorScheme.outline,
                          margin: const EdgeInsets.only(
                            bottom: _AppShellSizes.logoDividerGap,
                          ),
                        ),
                        for (
                          var index = 0;
                          index < AppShell._items.length;
                          index++
                        )
                          _NavigationTile(
                            item: AppShell._items[index],
                            isSelected: widget.currentIndex == index,
                            isCompact: !isExpandedLayout,
                            isDesktop: true,
                            onTap: () {
                              widget.onDestinationSelected(index);
                            },
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: _AppShellSizes.logoTopOffset,
                    left: 0,
                    right: 0,
                    child: _DesktopLogo(
                      isExpanded: _isHovering,
                      availableWidth: width,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 1, color: colorScheme.outline),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DesktopLogo extends StatelessWidget {
  const _DesktopLogo({required this.isExpanded, required this.availableWidth});

  final bool isExpanded;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final leftPadding = isExpanded ? 16.0 : 0.0;
    final rightPadding = isExpanded ? 12.0 : 0.0;
    final wordmarkWidth = isExpanded
        ? (availableWidth -
                  leftPadding -
                  rightPadding -
                  _AppShellSizes.logoIconSize)
              .clamp(0.0, _AppShellSizes.logoWordmarkWidth)
              .toDouble()
        : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: isExpanded ? Alignment.centerLeft : Alignment.center,
      padding: EdgeInsets.only(left: leftPadding, right: rightPadding),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/icon.png',
            width: _AppShellSizes.logoIconSize,
            height: _AppShellSizes.logoIconSize,
            fit: BoxFit.contain,
          ),
          SizedBox(
            width: wordmarkWidth,
            child: ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: 1,
                child: Image.asset(
                  'assets/images/letreiro.png',
                  height: _AppShellSizes.logoWordmarkHeight,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
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
            Container(
              height: _AppShellSizes.dividerHeight,
              color: colorScheme.outline,
            ),
            Padding(
              padding: _AppShellSizes.mobileNavigationPadding,
              child: Row(
                children: [
                  for (
                    var index = 0;
                    index < AppShell._mobileBottomItemCount;
                    index++
                  )
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: SizedBox(
                          width: _AppShellSizes.mobileNavigationItemWidth,
                          child: Center(
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
      width: _AppShellSizes.menuExpandedWidth,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: _AppShellSizes.menuPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: _AppShellSizes.logoDividerTopSpacing),
                  Container(
                    height: _AppShellSizes.dividerHeight,
                    color: colorScheme.outline,
                    margin: const EdgeInsets.only(
                      bottom: _AppShellSizes.logoDividerGap,
                    ),
                  ),
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

            Positioned(
              top: _AppShellSizes.logoTopOffset,
              left: 0,
              right: 0,
              child: Padding(
                padding: _AppShellSizes.logoPadding,
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/icon.png',
                      width: _AppShellSizes.logoIconSize,
                      height: _AppShellSizes.logoIconSize,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Image.asset(
                          'assets/images/letreiro.png',
                          height: _AppShellSizes.logoIconSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
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
      textColor = colorScheme.onPrimary;
      backgroundColor = colorScheme.primary;
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
            width: widget.isCompact
                ? (widget.isDesktop
                      ? _AppShellSizes.compactDesktopTileWidth
                      : _AppShellSizes.compactMobileTileWidth)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              height: widget.isCompact
                  ? (widget.isDesktop
                        ? _AppShellSizes.compactDesktopTileHeight
                        : _AppShellSizes.compactMobileTileHeight)
                  : (widget.isDesktop
                        ? _AppShellSizes.expandedDesktopTileHeight
                        : 48),
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCompact ? 4 : 14,
                vertical: widget.isCompact ? 4 : 0,
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
