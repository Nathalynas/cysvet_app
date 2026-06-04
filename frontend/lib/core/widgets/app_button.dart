import 'package:flutter/material.dart';

class _ButtonControlStyle {
  static const double height = 42;
  static const double radius = 16;
  static const double iconWidth = height;

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 14);
}

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
    this.height = _ButtonControlStyle.height,
    this.width,
    this.padding,
    this.margin,
    this.borderRadius = _ButtonControlStyle.radius,
    this.fontSize = 14,
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
    final colorScheme = theme.colorScheme;
    final effectiveColor = color ?? colorScheme.primary;
    final effectiveTextColor =
        textColor ?? (outlined ? effectiveColor : colorScheme.onPrimary);
    final effectiveBorderColor = borderColor ?? effectiveColor;
    final isEnabled = !loading && !disabled && onPressed != null;
    final isIconOnly = _isIconOnly;

    final button = SizedBox(
      width: expanded
          ? double.infinity
          : (width ?? (isIconOnly ? _ButtonControlStyle.iconWidth : null)),
      height: height,
      child: outlined
          ? OutlinedButton(
              onPressed: isEnabled ? onPressed : null,
              style: _buttonStyle(
                theme: theme,
                backgroundColor: Colors.transparent,
                foregroundColor: effectiveTextColor,
                borderColor: effectiveBorderColor,
                isIconOnly: isIconOnly,
              ),
              child: _buildContent(effectiveTextColor),
            )
          : ElevatedButton(
              onPressed: isEnabled ? onPressed : null,
              style: _buttonStyle(
                theme: theme,
                backgroundColor: effectiveColor,
                foregroundColor: effectiveTextColor,
                borderColor: effectiveBorderColor,
                isIconOnly: isIconOnly,
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
    required ThemeData theme,
    required Color backgroundColor,
    required Color foregroundColor,
    required Color borderColor,
    required bool isIconOnly,
  }) {
    final disabledBackgroundColor = theme.colorScheme.onSurface.withValues(
      alpha: 0.12,
    );
    final disabledForegroundColor = theme.colorScheme.onSurface.withValues(
      alpha: 0.38,
    );

    return ButtonStyle(
      elevation: WidgetStateProperty.all(outlined ? 0 : 1),
      minimumSize: WidgetStateProperty.all(Size.zero),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      mouseCursor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return SystemMouseCursors.basic;
        }

        return SystemMouseCursors.click;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return outlined ? Colors.transparent : disabledBackgroundColor;
        }
        return backgroundColor;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return disabledForegroundColor;
        }
        return foregroundColor;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        final color = states.contains(WidgetState.disabled)
            ? theme.colorScheme.outline.withValues(alpha: 0.45)
            : borderColor;
        return outlined ? BorderSide(color: color) : BorderSide.none;
      }),
      padding: WidgetStateProperty.all(
        padding ??
            (isIconOnly ? EdgeInsets.zero : _ButtonControlStyle.buttonPadding),
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
    if (label.isEmpty) {
      return icon ?? trailingIcon ?? const SizedBox.shrink();
    }

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

  bool get _isIconOnly {
    final hasText = text != null && text!.trim().isNotEmpty;
    if (hasText || loading) return false;
    return child != null || icon != null || trailingIcon != null;
  }
}
