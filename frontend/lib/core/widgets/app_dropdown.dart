import 'package:flutter/material.dart';

class AppDropdownOption<T> {
  const AppDropdownOption({
    required this.label,
    required this.value,
    this.suffix,
  });

  final String label;
  final T? value;
  final Widget? suffix;
}

class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.labelText,
    this.nullLabel = '',
    this.searchable = false,
    this.required = false,
    this.height = 46,
    this.menuMaxHeight = 320,
    this.validator,
  });

  final List<AppDropdownOption<T>> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String labelText;
  final String nullLabel;
  final bool searchable;
  final bool required;
  final double height;
  final double menuMaxHeight;
  final FormFieldValidator<T?>? validator;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();

  OverlayEntry? _overlayEntry;
  FormFieldState<T?>? _fieldState;
  bool _isOpen = false;
  String _searchFilter = '';

  AppDropdownOption<T>? get _selectedOption {
    for (final option in widget.options) {
      if (option.value == widget.value) return option;
    }
    return null;
  }

  List<AppDropdownOption<T>> get _filteredOptions {
    final filter = _normalize(_searchFilter.trim());
    if (filter.isEmpty) return widget.options;
    final words = filter.split(' ').where((word) => word.isNotEmpty).toList();
    return widget.options.where((option) {
      final label = _normalize(option.label);
      return words.every(label.contains);
    }).toList();
  }

  @override
  void didUpdateWidget(covariant AppDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isOpen) _overlayEntry?.markNeedsBuild();
      });
    }
  }

  @override
  void dispose() {
    _removeOverlay(updateState: false);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T?>(
      initialValue: widget.value,
      validator: (value) {
        if (widget.required && value == null) return 'Campo obrigatorio';
        return widget.validator?.call(value);
      },
      builder: (field) {
        _fieldState = field;
        if (field.value != widget.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) field.didChange(widget.value);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DropdownShell<T>(
              fieldKey: _fieldKey,
              layerLink: _layerLink,
              isOpen: _isOpen,
              hasError: field.hasError,
              labelText: widget.required
                  ? '${widget.labelText} *'
                  : widget.labelText,
              selectedLabel: _selectedOption?.label ?? widget.nullLabel,
              height: widget.height,
              onTap: _toggleOverlay,
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  field.errorText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _toggleOverlay() {
    if (_isOpen) {
      _removeOverlay();
      return;
    }
    _showOverlay();
  }

  void _showOverlay() {
    final renderBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
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
                color: colorScheme.surface,
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
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (value) {
                              _searchFilter = value;
                              _overlayEntry?.markNeedsBuild();
                            },
                          ),
                        ),
                      Flexible(
                        child: filteredOptions.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Nenhuma opcao encontrada.',
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
                                  final selected = option.value == widget.value;

                                  return InkWell(
                                    onTap: () {
                                      widget.onChanged(option.value);
                                      _fieldState?.didChange(option.value);
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
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontSize: 15,
                                                fontWeight: selected
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
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
    setState(() => _isOpen = true);
  }

  void _removeOverlay({bool updateState = true}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (!updateState) {
      _isOpen = false;
      return;
    }
    if (mounted) setState(() => _isOpen = false);
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
}

class _DropdownShell<T> extends StatelessWidget {
  const _DropdownShell({
    required this.fieldKey,
    required this.layerLink,
    required this.isOpen,
    required this.hasError,
    required this.labelText,
    required this.selectedLabel,
    required this.height,
    required this.onTap,
  });

  final GlobalKey fieldKey;
  final LayerLink layerLink;
  final bool isOpen;
  final bool hasError;
  final String labelText;
  final String selectedLabel;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CompositedTransformTarget(
      link: layerLink,
      child: InkWell(
        key: fieldKey,
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: height,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasError ? colorScheme.error : colorScheme.outline,
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
                      labelText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        height: 1,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      selectedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ),
              Icon(isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }
}
