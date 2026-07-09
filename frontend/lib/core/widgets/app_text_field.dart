import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _TextFieldControlStyle {
  static const double height = 42;
  static const double multilineHeight = 82;
  static const double radius = 12;

  static const EdgeInsets fieldPadding = EdgeInsets.symmetric(horizontal: 14);

  static const double floatingLabelFontSize = 12;
  static const double inputFontSize = 14;
}

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.required = false,
    this.clearable = false,
    this.capitalize = false,
    this.denySpaces = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.maxLines = 1,
    this.minLines,
    this.minChars,
    this.maxChars,
    this.inputFormatters,
    this.autofocus = false,
    this.textInputAction,
    this.fillColor,
    this.contentPadding,
    this.borderRadius,
    this.borderColor,
    this.focusedBorderColor,
    this.isDense,
    this.textStyle,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
    this.height,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final bool required;
  final bool clearable;
  final bool capitalize;
  final bool denySpaces;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final int? maxLines;
  final int? minLines;
  final int? minChars;
  final int? maxChars;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final Color? fillColor;
  final EdgeInsetsGeometry? contentPadding;
  final double? borderRadius;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final bool? isDense;
  final TextStyle? textStyle;
  final BoxConstraints? prefixIconConstraints;
  final BoxConstraints? suffixIconConstraints;
  final double? height;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;
  late TextEditingController _controller;
  late bool _ownsController;

  bool _focused = false;

  bool get _isSingleLine {
    final effectiveMaxLines = widget.obscureText ? 1 : widget.maxLines;
    final effectiveMinLines = widget.obscureText ? null : widget.minLines;

    return effectiveMaxLines == 1 && effectiveMinLines == null;
  }

  double get _effectiveHeight {
    if (!_isSingleLine) {
      return widget.height ?? _TextFieldControlStyle.multilineHeight;
    }

    return widget.height ?? _TextFieldControlStyle.height;
  }

  double get _effectiveRadius {
    return widget.borderRadius ?? _TextFieldControlStyle.radius;
  }

  String? get _labelText {
    if (widget.label == null || widget.label!.isEmpty) {
      return null;
    }

    return widget.required ? '${widget.label!} *' : widget.label;
  }

  bool get _hasValue {
    return _controller.text.trim().isNotEmpty;
  }

  bool get _shouldFloatLabel {
    return _focused || _hasValue;
  }

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChanged);

    _ownsController = widget.controller == null;
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_handleTextChanged);

      if (_ownsController) {
        _controller.dispose();
      }

      _ownsController = widget.controller == null;
      _controller =
          widget.controller ?? TextEditingController(text: widget.initialValue);
      _controller.addListener(_handleTextChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();

    _controller.removeListener(_handleTextChanged);

    if (_ownsController) {
      _controller.dispose();
    }

    super.dispose();
  }

  void _handleFocusChanged() {
    setState(() {
      _focused = _focusNode.hasFocus;
    });
  }

  void _handleTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: _controller.text,
      validator: _validate,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildShell(context, field),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  field.errorText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 11,
                    height: 1.1,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildShell(BuildContext context, FormFieldState<String> field) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final borderColor = field.hasError
        ? colorScheme.error
        : _focused
        ? widget.focusedBorderColor ?? colorScheme.primary
        : widget.borderColor ?? colorScheme.outline.withValues(alpha: 0.75);

    final fillColor = widget.fillColor ?? colorScheme.surface;

    return Container(
      height: _effectiveHeight,
      width: double.infinity,
      padding: widget.contentPadding ?? _TextFieldControlStyle.fieldPadding,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(_effectiveRadius),
        border: Border.all(color: borderColor, width: _focused ? 1.2 : 1),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (widget.prefixIcon != null) ...[
            widget.prefixIcon!,
            const SizedBox(width: 8),
          ],
          Expanded(
            child: _isSingleLine
                ? _buildSingleLineContent(context, field)
                : _buildMultiLineContent(context, field),
          ),
          if (_buildSuffixIcon(field) != null) ...[
            const SizedBox(width: 8),
            _buildSuffixIcon(field)!,
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingLabelOnBorder(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        color: widget.fillColor ?? colorScheme.surface,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
          style: _labelStyle(context, floating: true),
        ),
      ),
    );
  }

  Widget _buildSingleLineContent(
    BuildContext context,
    FormFieldState<String> field,
  ) {
    final label = _labelText;

    if (label == null) {
      return Center(child: _buildTextField(context, field));
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          left: 0,
          right: 0,

          top: _shouldFloatLabel ? -6 : 11,

          child: IgnorePointer(
            child: _shouldFloatLabel
                ? _buildFloatingLabelOnBorder(context, label)
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      style: _labelStyle(context, floating: false),
                    ),
                  ),
          ),
        ),

        AnimatedPositioned(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          left: 0,
          right: 0,
          top: _shouldFloatLabel ? 16 : 9,
          child: _buildTextField(context, field, hideHint: !_shouldFloatLabel),
        ),
      ],
    );
  }

  Widget _buildMultiLineContent(
  BuildContext context,
  FormFieldState<String> field,
) {
  final label = _labelText;

  if (label == null) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: _buildTextField(context, field),
    );
  }

  return Stack(
    clipBehavior: Clip.none,
    children: [
      AnimatedPositioned(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        left: 0,
        right: 0,
        top: _shouldFloatLabel ? -6 : 12,
        child: IgnorePointer(
          child: _shouldFloatLabel
              ? _buildFloatingLabelOnBorder(context, label)
              : Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: _labelStyle(context, floating: false),
                  ),
                ),
        ),
      ),
      Positioned.fill(
        top: _shouldFloatLabel ? 18 : 8,
        bottom: 8,
        child: _buildTextField(
          context,
          field,
          hideHint: !_shouldFloatLabel,
        ),
      ),
    ],
  );
}

  TextStyle _labelStyle(BuildContext context, {required bool floating}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return theme.textTheme.bodySmall!.copyWith(
      fontSize: floating ? _TextFieldControlStyle.floatingLabelFontSize : 14,
      height: 1,
      fontWeight: floating ? FontWeight.w500 : FontWeight.w400,
      color: _focused ? colorScheme.primary : colorScheme.onSurfaceVariant,
    );
  }

  Widget _buildTextField(
    BuildContext context,
    FormFieldState<String> field, {
    bool hideHint = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.capitalize
          ? TextCapitalization.characters
          : TextCapitalization.none,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.obscureText ? null : widget.minLines,
      style: _effectiveTextStyle(context),
      inputFormatters: _buildInputFormatters(),
      onTap: widget.onTap,
      onChanged: (value) {
        field.didChange(value);
        widget.onChanged?.call(value);
      },
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        isDense: true,
        isCollapsed: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        filled: false,
        hintText: hideHint ? null : widget.hint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          fontSize: _TextFieldControlStyle.inputFontSize,
          height: 1.2,
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  TextStyle? _effectiveTextStyle(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return theme.textTheme.bodyMedium
        ?.copyWith(
          fontSize: _TextFieldControlStyle.inputFontSize,
          height: 1.2,
          color: widget.enabled ? colorScheme.onSurface : theme.disabledColor,
        )
        .merge(widget.textStyle);
  }

  List<TextInputFormatter>? _buildInputFormatters() {
    final formatters = <TextInputFormatter>[...?widget.inputFormatters];

    if (widget.capitalize) {
      formatters.add(UpperCaseTextFormatter());
    }

    if (widget.denySpaces) {
      formatters.add(FilteringTextInputFormatter.deny(RegExp(r'\s')));
    }

    return formatters.isEmpty ? null : formatters;
  }

  Widget? _buildSuffixIcon(FormFieldState<String> field) {
    final shouldShowClearButton = widget.clearable && widget.controller != null;

    if (!shouldShowClearButton) {
      return widget.suffixIcon;
    }

    final hasText = _controller.text.isNotEmpty;

    if (!hasText) {
      return widget.suffixIcon;
    }

    final clearButton = InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: widget.enabled && !widget.readOnly
          ? () {
              _controller.clear();
              field.didChange('');
              widget.onChanged?.call('');
            }
          : null,
      child: const SizedBox(
        width: 36,
        height: 36,
        child: Icon(Icons.clear, size: 18),
      ),
    );

    if (widget.suffixIcon == null) {
      return clearButton;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [widget.suffixIcon!, clearButton],
    );
  }

  String? _validate(String? rawValue) {
    final value = _controller.text.trim();

    if (widget.required && value.isEmpty) {
      return 'Campo obrigatório';
    }

    if (widget.minChars != null &&
        value.isNotEmpty &&
        value.length < widget.minChars!) {
      return 'Informe pelo menos ${widget.minChars} caracteres';
    }

    if (widget.maxChars != null && value.length > widget.maxChars!) {
      return 'Informe no máximo ${widget.maxChars} caracteres';
    }

    return widget.validator?.call(_controller.text);
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
