import 'package:flutter/material.dart';

import 'app_text_field.dart';

class _SearchControlStyle {
  static const double height = 42;
  static const double radius = 12;

  static const EdgeInsets fieldPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 8,
  );

  static const BoxConstraints prefixIconConstraints = BoxConstraints(
    minWidth: 38,
    minHeight: height,
  );

  static const BoxConstraints suffixIconConstraints = BoxConstraints(
    minWidth: 36,
    minHeight: height,
  );
}

class SearchCard extends StatefulWidget {
  const SearchCard({
    super.key,
    required this.value,
    required this.labelText,
    required this.onChanged,
    this.hintText,
  });

  final String value;
  final String labelText;
  final String? hintText;
  final ValueChanged<String> onChanged;

  @override
  State<SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<SearchCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant SearchCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppTextField(
      controller: _controller,
      onChanged: widget.onChanged,
      hint: widget.hintText ?? widget.labelText,
      clearable: true,
      isDense: true,
      height: _SearchControlStyle.height,
      borderRadius: _SearchControlStyle.radius,
      contentPadding: _SearchControlStyle.fieldPadding,
      fillColor: colorScheme.surface,
      borderColor: colorScheme.outline.withValues(alpha: 0.75),
      focusedBorderColor: colorScheme.primary,
      prefixIcon: Icon(
        Icons.search_outlined,
        size: 18,
        color: colorScheme.onSurfaceVariant,
      ),
      prefixIconConstraints: _SearchControlStyle.prefixIconConstraints,
      suffixIconConstraints: _SearchControlStyle.suffixIconConstraints,
      textStyle: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.2,
        color: colorScheme.onSurface,
      ),
    );
  }
}