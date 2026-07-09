import 'package:flutter/material.dart';

class _ButtonControlStyle {
  static const double height = 42;
  static const double radius = 12;
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
    this.shadow = true,
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
  final bool shadow;

  bool get _isEnabled {
    return !loading && !disabled && onPressed != null;
  }

  bool get _isIconOnly {
    final hasText = text != null && text!.trim().isNotEmpty;

    if (hasText || loading) {
      return false;
    }

    return child != null || icon != null || trailingIcon != null;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? _ButtonControlStyle.height;

    final effectiveWidth = expanded
        ? double.infinity
        : width ?? (_isIconOnly ? _ButtonControlStyle.iconWidth : null);

    final button = SizedBox(
      width: effectiveWidth,
      height: effectiveHeight,
      child: outlined
          ? OutlinedButton(
              onPressed: _isEnabled ? onPressed : null,
              style: _buttonStyle(context: context, isIconOnly: _isIconOnly),
              child: _buildContent(context),
            )
          : ElevatedButton(
              onPressed: _isEnabled ? onPressed : null,
              style: _buttonStyle(context: context, isIconOnly: _isIconOnly),
              child: _buildContent(context),
            ),
    );

    final buttonWithShadow = shadow
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: button,
          )
        : button;

    if (margin == null) {
      return buttonWithShadow;
    }

    return Padding(padding: margin!, child: buttonWithShadow);
  }

  ButtonStyle _buttonStyle({
    required BuildContext context,
    required bool isIconOnly,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveColor = color ?? colorScheme.primary;

    final effectiveTextColor =
        textColor ?? (outlined ? effectiveColor : colorScheme.onPrimary);

    final effectiveBorderColor = borderColor ?? effectiveColor;

    final disabledBackgroundColor = colorScheme.onSurface.withValues(
      alpha: 0.12,
    );

    final disabledForegroundColor = colorScheme.onSurface.withValues(
      alpha: 0.38,
    );

    return ButtonStyle(
      elevation: WidgetStateProperty.all(0),
      shadowColor: WidgetStateProperty.all(Colors.transparent),
      surfaceTintColor: WidgetStateProperty.all(Colors.transparent),

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
          return outlined ? effectiveColor : disabledBackgroundColor;
        }

        return effectiveColor;
      }),
      
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return disabledForegroundColor;
        }

        return effectiveTextColor;
      }),

      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.transparent;
        }

        if (states.contains(WidgetState.pressed)) {
          return outlined
              ? effectiveColor.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.14);
        }

        if (states.contains(WidgetState.hovered)) {
          return outlined
              ? effectiveColor.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.08);
        }

        return Colors.transparent;
      }),

      side: WidgetStateProperty.resolveWith((states) {
        final effectiveSideColor = states.contains(WidgetState.disabled)
            ? colorScheme.outline.withValues(alpha: 0.45)
            : effectiveBorderColor;

        if (outlined) {
          return BorderSide(color: effectiveSideColor, width: 1);
        }

        return BorderSide.none;
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

  Widget _buildContent(BuildContext context) {
    final contentColor = _contentColor(context);

    if (loading) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(contentColor),
        ),
      );
    }

    if (child != null) {
      return IconTheme(
        data: IconThemeData(color: contentColor, size: 18),
        child: DefaultTextStyle(
          style: TextStyle(
            color: contentColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: 1.2,
          ),
          child: child!,
        ),
      );
    }

    final label = upperCase ? (text ?? '').toUpperCase() : (text ?? '');

    if (label.isEmpty) {
      return IconTheme(
        data: IconThemeData(color: contentColor, size: 18),
        child: icon ?? trailingIcon ?? const SizedBox.shrink(),
      );
    }

    final textWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: contentColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: 1.2,
      ),
    );

    if (icon == null && trailingIcon == null) {
      return textWidget;
    }

    return IconTheme(
      data: IconThemeData(color: contentColor, size: 18),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 8)],
          Flexible(child: textWidget),
          if (trailingIcon != null) ...[
            const SizedBox(width: 8),
            trailingIcon!,
          ],
        ],
      ),
    );
  }

  Color _contentColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final effectiveColor = color ?? colorScheme.primary;

    final effectiveTextColor =
        textColor ?? (outlined ? effectiveColor : colorScheme.onPrimary);

    final disabledForegroundColor = colorScheme.onSurface.withValues(
      alpha: 0.38,
    );

    return _isEnabled ? effectiveTextColor : disabledForegroundColor;
  }
}
