import 'package:flutter/material.dart';

enum StatusBadgeType { success, warning, error, neutral, info }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.neutral,
    this.icon,
  });

  final String label;
  final StatusBadgeType type;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(context, type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: colors.foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  _StatusBadgeColors _colorsFor(BuildContext context, StatusBadgeType type) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case StatusBadgeType.success:
        return _StatusBadgeColors(
          background: colorScheme.primaryContainer,
          border: colorScheme.onPrimaryContainer.withValues(alpha: 0.18),
          foreground: colorScheme.onPrimaryContainer,
        );
      case StatusBadgeType.warning:
        return _StatusBadgeColors(
          background: colorScheme.tertiaryContainer,
          border: colorScheme.onTertiaryContainer.withValues(alpha: 0.18),
          foreground: colorScheme.onTertiaryContainer,
        );
      case StatusBadgeType.error:
        return _StatusBadgeColors(
          background: colorScheme.errorContainer,
          border: colorScheme.onErrorContainer.withValues(alpha: 0.18),
          foreground: colorScheme.onErrorContainer,
        );
      case StatusBadgeType.info:
        return _StatusBadgeColors(
          background: colorScheme.secondaryContainer,
          border: colorScheme.onSecondaryContainer.withValues(alpha: 0.18),
          foreground: colorScheme.onSecondaryContainer,
        );
      case StatusBadgeType.neutral:
        return _StatusBadgeColors(
          background: colorScheme.surfaceContainerHighest,
          border: colorScheme.outline,
          foreground: colorScheme.onSurfaceVariant,
        );
    }
  }
}

class _StatusBadgeColors {
  const _StatusBadgeColors({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}
