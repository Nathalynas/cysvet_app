import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled,
      autofocus: autofocus,
      textInputAction: textInputAction,
      textCapitalization: capitalize
          ? TextCapitalization.characters
          : TextCapitalization.none,
      maxLines: obscureText ? 1 : maxLines,
      minLines: obscureText ? null : minLines,
      style: textStyle,
      inputFormatters: _buildInputFormatters(),
      validator: _validate,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      decoration: _buildDecoration(context),
    );
  }

  InputDecoration _buildDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final radiusValue = borderRadius ?? 12.0;
    final effectiveBorderColor = borderColor ?? theme.colorScheme.outline;
    final effectiveFocusedBorderColor =
        focusedBorderColor ?? theme.colorScheme.primary;
    final effectiveLabelColor = enabled
        ? theme.colorScheme.onSurfaceVariant
        : theme.disabledColor;

    return InputDecoration(
      labelText: _labelText,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: _buildSuffixIcon(),
      filled: true,
      fillColor: fillColor ?? theme.colorScheme.surfaceContainerHighest,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: TextStyle(
        color: effectiveLabelColor,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        color: effectiveFocusedBorderColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isDense: isDense,
      prefixIconConstraints: prefixIconConstraints,
      suffixIconConstraints: suffixIconConstraints,
      border: _buildCustomBorder(radiusValue, effectiveBorderColor),
      enabledBorder: _buildCustomBorder(radiusValue, effectiveBorderColor),
      focusedBorder: _buildCustomBorder(
        radiusValue,
        effectiveFocusedBorderColor,
        width: 1.5,
      ),
      disabledBorder: _buildCustomBorder(
        radiusValue,
        theme.colorScheme.outline.withValues(alpha: 0.45),
      ),
    );
  }

  InputBorder _buildCustomBorder(
    double radius,
    Color color, {
    double width = 1.0,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  String? get _labelText {
    if (label == null || label!.isEmpty) {
      return null;
    }

    return required ? '${label!} *' : label;
  }

  List<TextInputFormatter>? _buildInputFormatters() {
    final formatters = <TextInputFormatter>[...?inputFormatters];

    if (capitalize) {
      formatters.add(UpperCaseTextFormatter());
    }

    if (denySpaces) {
      formatters.add(FilteringTextInputFormatter.deny(RegExp(r'\s')));
    }

    return formatters.isEmpty ? null : formatters;
  }

  Widget? _buildSuffixIcon() {
    final shouldShowClearButton = clearable && controller != null;

    if (!shouldShowClearButton) {
      return suffixIcon;
    }

    final clearButton = ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller!,
      builder: (context, value, _) {
        if (value.text.isEmpty) {
          return const SizedBox.shrink();
        }

        return IconButton(
          tooltip: 'Limpar',
          icon: const Icon(Icons.clear),
          onPressed: enabled && !readOnly ? controller!.clear : null,
        );
      },
    );

    if (suffixIcon == null) {
      return clearButton;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [suffixIcon!, clearButton],
    );
  }

  String? _validate(String? rawValue) {
    final value = rawValue?.trim() ?? '';

    if (required && value.isEmpty) {
      return 'Campo obrigatório';
    }

    if (minChars != null && value.isNotEmpty && value.length < minChars!) {
      return 'Informe pelo menos $minChars caracteres';
    }

    if (maxChars != null && value.length > maxChars!) {
      return 'Informe no máximo $maxChars caracteres';
    }

    return validator?.call(rawValue);
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
