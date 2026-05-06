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
      inputFormatters: _buildInputFormatters(),
      validator: _validate,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: _labelText,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: _buildSuffixIcon(),
      ),
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
