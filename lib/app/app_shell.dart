import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import 'theme.dart';

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
      route: '/perfil',
      label: 'Perfil',
      title: 'Perfil',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _menuIsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);
    final bool isMobile = MediaQuery.of(context).size.width < MOBILE_WIDTH;
    final content = _ShellContent(
      title: AppShell._items[currentIndex].title,
      child: widget.child,
    );

    if (!isMobile) {
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
                        height: 60,
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
      body: content,
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
  const _ShellContent({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PageHeader(title: title),
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
  const _PageHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge;

    return Material(
      color: AppTheme.tertiaryColor,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: titleStyle?.copyWith(
              color: AppTheme.textColor,
              fontWeight: FontWeight.w700,
            ),
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
    return MouseRegion(
      onEnter: (_) => _updateHover(true),
      onExit: (_) => _updateHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: _isHovering ? 256 : 80,
        color: AppTheme.tertiaryColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              children: [
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
    return Material(
      color: AppTheme.tertiaryColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
          child: Row(
            children: [
              for (var index = 0; index < AppShell._items.length; index++)
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
    
    late final Color textColor;
    late final Color backgroundColor;
    
    if (widget.isSelected) {
      if (widget.isDesktop) {
        // Desktop: texto primary, fundo secondary
        textColor = AppTheme.primaryColor;
        backgroundColor = AppTheme.secondaryColor;
      } else {
        // Mobile: fundo inteiro na cor primary, texto branco
        textColor = Colors.white;
        backgroundColor = AppTheme.primaryColor;
      }
    } else if (_isHovering) {
      // Hover: neutral (mais sutil)
      textColor = AppTheme.textColor;
      backgroundColor = AppTheme.neutralColor;
    } else {
      // Normal
      textColor = AppTheme.mutedTextColor;
      backgroundColor = Colors.transparent;
    }
    
    // No desktop encolhido, mostrar apenas ícone
    // No desktop expandido, mostrar ícone + texto em linha
    // No mobile, mostrar apenas ícone
    final content = (widget.isDesktop && widget.isCompact)
        ? Icon(widget.isSelected ? widget.item.selectedIcon : widget.item.icon, size: 24)
        : (!widget.isDesktop && widget.isCompact)
            ? Icon(widget.isSelected ? widget.item.selectedIcon : widget.item.icon, size: 24)
            : Row(
                children: [
                  Icon(widget.isSelected ? widget.item.selectedIcon : widget.item.icon, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
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
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: widget.isCompact ? 2 : 0,
          vertical: widget.isCompact ? 0 : 4,
        ),
        child: InkWell(
          onTap: widget.onTap,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: (widget.isDesktop && widget.isCompact) || (!widget.isDesktop && widget.isCompact) ? 58 : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              height: widget.isDesktop && widget.isCompact ? 50 : (widget.isCompact ? 58 : 48),
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCompact ? 4 : 14,
                vertical: widget.isCompact ? 6 : 0,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: IconTheme(
                data: IconThemeData(color: textColor, size: widget.isDesktop ? 24 : (widget.isCompact ? 22 : 24)),
                child: DefaultTextStyle(
                  style: (labelStyle ?? const TextStyle()).copyWith(
                    color: textColor,
                    fontSize: widget.isCompact ? 11 : 14,
                    fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
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
