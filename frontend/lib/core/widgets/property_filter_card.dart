import 'package:cysvet_app/core/widgets/app_button.dart';
import 'package:cysvet_app/core/widgets/app_card.dart';
import 'package:cysvet_app/core/widgets/app_dropdown.dart';
import 'package:cysvet_app/features/properties/domain/property_summary_model.dart';
import 'package:flutter/material.dart';

class PropertyFilterCard extends StatelessWidget {
  const PropertyFilterCard({
    super.key,
    required this.properties,
    required this.selectedPropertyId,
    required this.onChanged,
    this.labelText = 'Filtrar por propriedade',
    this.allPropertiesText = 'Todas as propriedades',
  });

  final List<PropertySummaryModel> properties;
  final int? selectedPropertyId;
  final ValueChanged<int?> onChanged;
  final String labelText;
  final String allPropertiesText;

  @override
  Widget build(BuildContext context) {
    return AppDropdown<int>(
      value: selectedPropertyId,
      labelText: labelText,
      nullLabel: allPropertiesText,
      searchable: true,
      onChanged: onChanged,
      options: [
        AppDropdownOption<int>(label: allPropertiesText, value: null),
        ...properties.map(
          (property) =>
              AppDropdownOption<int>(label: property.nome, value: property.id),
        ),
      ],
    );
  }
}

class PropertySegmentedFilter extends StatefulWidget {
  const PropertySegmentedFilter({
    super.key,
    required this.properties,
    required this.selectedPropertyId,
    required this.onChanged,
    this.generalText = 'Geral',
    this.propertyText = 'Por propriedade',
    this.searchHintText = 'Pesquisar',
  });

  final List<PropertySummaryModel> properties;
  final int? selectedPropertyId;
  final ValueChanged<int?> onChanged;
  final String generalText;
  final String propertyText;
  final String searchHintText;

  @override
  State<PropertySegmentedFilter> createState() =>
      _PropertySegmentedFilterState();
}

class _PropertySegmentedFilterState extends State<PropertySegmentedFilter> {
  final _searchController = TextEditingController();
  final _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;

  bool get _isPropertyMode => widget.selectedPropertyId != null;

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PropertySegmentedFilter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedPropertyId != widget.selectedPropertyId) {
      _overlayEntry?.markNeedsBuild();
    }

    if (oldWidget.properties != widget.properties) {
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _togglePropertiesMenu() {
    if (_overlayEntry == null) {
      _showPropertiesMenu();
    } else {
      _removeOverlay();
    }
  }

  void _showPropertiesMenu() {
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _searchController.clear();
  }

  void _selectGeneral() {
    widget.onChanged(null);
    _removeOverlay();
  }

  void _selectProperty(int propertyId) {
    widget.onChanged(propertyId);
    _removeOverlay();
  }

  OverlayEntry _buildOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeOverlay,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 8),
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: size.width,
                  child: _PropertyMenuCard(
                    properties: widget.properties,
                    selectedPropertyId: widget.selectedPropertyId,
                    searchController: _searchController,
                    searchHintText: widget.searchHintText,
                    onChanged: _selectProperty,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CompositedTransformTarget(
      link: _layerLink,
      child: IntrinsicWidth(
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          borderRadius: 12,
          shadow: true,
          backgroundColor: colorScheme.surface,
          borderColor: colorScheme.outline.withValues(alpha: 0.75),
          child: SizedBox(
            height: 30,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PropertySegmentButton(
                  label: widget.generalText.toUpperCase(),
                  selected: !_isPropertyMode,
                  horizontalPadding: 10,
                  onTap: _selectGeneral,
                ),
                _PropertySegmentButton(
                  label: widget.propertyText.toUpperCase(),
                  selected: _isPropertyMode,
                  horizontalPadding: 14,
                  onTap: _togglePropertiesMenu,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PropertySegmentButton extends StatelessWidget {
  const _PropertySegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.horizontalPadding = 16,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppButton(
      text: label,
      height: 30,
      shadow: false,
      outlined: false,
      color: selected ? colorScheme.secondary : Colors.transparent,
      textColor: selected
          ? colorScheme.onSecondary
          : colorScheme.onSurfaceVariant,
      borderColor: Colors.transparent,
      borderRadius: 9,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      fontSize: theme.textTheme.labelMedium?.fontSize ?? 12,
      fontWeight: FontWeight.w700,
      onPressed: onTap,
    );
  }
}

class _PropertyMenuCard extends StatefulWidget {
  const _PropertyMenuCard({
    required this.properties,
    required this.selectedPropertyId,
    required this.searchController,
    required this.searchHintText,
    required this.onChanged,
  });

  final List<PropertySummaryModel> properties;
  final int? selectedPropertyId;
  final TextEditingController searchController;
  final String searchHintText;
  final ValueChanged<int> onChanged;

  @override
  State<_PropertyMenuCard> createState() => _PropertyMenuCardState();
}

class _PropertyMenuCardState extends State<_PropertyMenuCard> {
  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final query = widget.searchController.text.trim().toLowerCase();

    final filteredProperties = widget.properties
        .where((property) {
          if (query.isEmpty) {
            return true;
          }

          return property.nome.toLowerCase().contains(query);
        })
        .toList(growable: false);

    return Container(
      constraints: const BoxConstraints(maxHeight: 330),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.searchController,
            decoration: InputDecoration(
              hintText: widget.searchHintText,
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              filled: true,
              fillColor: colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.20),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.20),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: filteredProperties.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'Nenhuma propriedade encontrada.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: filteredProperties.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (context, index) {
                      final property = filteredProperties[index];
                      final selected = property.id == widget.selectedPropertyId;

                      return _PropertyMenuItem(
                        label: property.nome,
                        selected: selected,
                        onTap: () => widget.onChanged(property.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PropertyMenuItem extends StatelessWidget {
  const _PropertyMenuItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_rounded, size: 20, color: colorScheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
