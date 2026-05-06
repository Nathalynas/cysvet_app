import 'package:flutter/material.dart';

import '../../app/theme.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.text,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.disabled = false,
    this.upperCase = false,
    this.color,
    this.textColor,
    this.borderColor,
    this.outlined = false,
    this.height = 48,
    this.width,
    this.padding,
    this.margin,
    this.borderRadius = 8,
    this.fontSize = 15,
    this.fontWeight = FontWeight.w600,
    this.expanded = false,
    this.child,
  });

  final String? text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Widget? trailingIcon;
  final bool loading;
  final bool disabled;
  final bool upperCase;
  final Color? color;
  final Color? textColor;
  final Color? borderColor;
  final bool outlined;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double? fontSize;
  final FontWeight fontWeight;
  final bool expanded;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? AppTheme.primaryColor;
    final effectiveTextColor =
        textColor ?? (outlined ? effectiveColor : theme.colorScheme.onPrimary);
    final effectiveBorderColor = borderColor ?? effectiveColor;
    final isEnabled = !loading && !disabled && onPressed != null;

    final button = SizedBox(
      width: expanded ? double.infinity : width,
      height: height,
      child: outlined
          ? OutlinedButton(
              onPressed: isEnabled ? onPressed : null,
              style: _buttonStyle(
                backgroundColor: Colors.transparent,
                foregroundColor: effectiveTextColor,
                borderColor: effectiveBorderColor,
              ),
              child: _buildContent(effectiveTextColor),
            )
          : ElevatedButton(
              onPressed: isEnabled ? onPressed : null,
              style: _buttonStyle(
                backgroundColor: effectiveColor,
                foregroundColor: effectiveTextColor,
                borderColor: effectiveBorderColor,
              ),
              child: _buildContent(effectiveTextColor),
            ),
    );

    if (margin == null) {
      return button;
    }

    return Padding(padding: margin!, child: button);
  }

  ButtonStyle _buttonStyle({
    required Color backgroundColor,
    required Color foregroundColor,
    required Color borderColor,
  }) {
    return ButtonStyle(
      elevation: WidgetStateProperty.all(outlined ? 0 : 1),
      mouseCursor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return SystemMouseCursors.basic;
        }

        return SystemMouseCursors.click;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return outlined ? Colors.transparent : Colors.grey.shade300;
        }
        return backgroundColor;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.grey.shade600;
        }
        return foregroundColor;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        final color = states.contains(WidgetState.disabled)
            ? Colors.grey.shade400
            : borderColor;
        return outlined ? BorderSide(color: color) : BorderSide.none;
      }),
      padding: WidgetStateProperty.all(
        padding ?? const EdgeInsets.symmetric(horizontal: 16),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  Widget _buildContent(Color indicatorColor) {
    if (loading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
        ),
      );
    }

    if (child != null) {
      return child!;
    }

    final label = upperCase ? (text ?? '').toUpperCase() : (text ?? '');
    final textWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
    );

    if (icon == null && trailingIcon == null) {
      return textWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: 8)],
        textWidget,
        if (trailingIcon != null) ...[const SizedBox(width: 8), trailingIcon!],
      ],
    );
  }
}
