import 'package:cysvet_app/features/properties/domain/property_summary_model.dart';
import 'package:flutter/material.dart';

class PropertyDropdownOption<T> {
  const PropertyDropdownOption({
    required this.label,
    required this.value,
    this.suffix,
  });

  final String label;
  final T? value;
  final Widget? suffix;
}

class PropertyDropdownField<T> extends StatefulWidget {
  const PropertyDropdownField({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.labelText,
    this.nullLabel = '',
    this.searchable = true,
    this.height = 46,
    this.menuMaxHeight = 320,
  });

  final List<PropertyDropdownOption<T>> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String labelText;
  final String nullLabel;
  final bool searchable;
  final double height;
  final double menuMaxHeight;

  @override
  State<PropertyDropdownField<T>> createState() =>
      _PropertyDropdownFieldState<T>();
}

class _PropertyDropdownFieldState<T> extends State<PropertyDropdownField<T>> {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();

  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  String _searchFilter = '';

  PropertyDropdownOption<T>? get _selectedOption {
    for (final option in widget.options) {
      if ( option.value == widget.value) {
        return option;
      }
    }

    return null;
  }

  List<PropertyDropdownOption<T>> get _filteredOptions {
    final filter = _normalize(_searchFilter.trim());

    if (filter.isEmpty) {
      return widget.options;
    }

    final words = filter.split(' ').where((word) => word.isNotEmpty).toList();

    return widget.options.where((option) {
      final optionLabel = _normalize(option.label);

      return words.every(optionLabel.contains);
    }).toList();
  }

  @override
  void didUpdateWidget(covariant PropertyDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isOpen) {
      _overlayEntry?.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleOverlay() {
    if (_isOpen) {
      _removeOverlay();
      return;
    }

    _showOverlay();
  }

  void _showOverlay() {
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    final size = renderBox.size;

    _searchFilter = '';
    _searchController.clear();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final filteredOptions = _filteredOptions;

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
              offset: Offset(0, size.height + 6),
              child: Material(
                color: theme.cardColor,
                elevation: 8,
                borderRadius: BorderRadius.circular(10),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: size.width,
                    maxWidth: size.width,
                    maxHeight: widget.menuMaxHeight,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.searchable)
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            maxLines: 1,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Pesquisar',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchFilter.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        _searchFilter = '';
                                        _overlayEntry?.markNeedsBuild();
                                      },
                                    ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                            onChanged: (value) {
                              _searchFilter = value;
                              _overlayEntry?.markNeedsBuild();
                            },
                            onSubmitted: (_) {
                              final firstOption = _filteredOptions.firstOrNull;

                              if (firstOption == null) return;

                              widget.onChanged(firstOption.value);
                              _removeOverlay();
                            },
                          ),
                        ),
                      Flexible(
                        child: filteredOptions.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Nenhuma opção encontrada.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: filteredOptions.length,
                                itemBuilder: (context, index) {
                                  final option = filteredOptions[index];
                                  final selected =
                                      option.value == widget.value;

                                  return InkWell(
                                    onTap: () {
                                      widget.onChanged(option.value);
                                      _removeOverlay();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              option.label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.start,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontSize: 15,
                                                fontWeight: selected
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          if (option.suffix != null) ...[
                                            const SizedBox(width: 8),
                                            option.suffix!,
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);

    setState(() {
      _isOpen = true;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;

    if (!mounted) return;

    setState(() {
      _isOpen = false;
    });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedLabel = _selectedOption?.label ?? widget.nullLabel;

    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        key: _fieldKey,
        borderRadius: BorderRadius.circular(8),
        onTap: _toggleOverlay,
        child: Container(
          height: widget.height,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.dividerColor,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.labelText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        height: 1,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      selectedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: PropertyDropdownField<int>(
          value: selectedPropertyId,
          labelText: labelText,
          nullLabel: allPropertiesText,
          searchable: true,
          onChanged: onChanged,
          options: [
            PropertyDropdownOption<int>(
              label: allPropertiesText,
              value: null,
            ),
            ...properties.map(
              (property) => PropertyDropdownOption<int>(
                label: property.nome,
                value: property.id,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNullExtension<T> on List<T> {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}