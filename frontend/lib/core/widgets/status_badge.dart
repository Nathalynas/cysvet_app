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
    final colors = _colorsFor(type);

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

  _StatusBadgeColors _colorsFor(StatusBadgeType type) {
    switch (type) {
      case StatusBadgeType.success:
        return const _StatusBadgeColors(
          background: Color(0xFFE8F5E9),
          border: Color(0xFFA5D6A7),
          foreground: Color(0xFF1B5E20),
        );
      case StatusBadgeType.warning:
        return const _StatusBadgeColors(
          background: Color(0xFFFFF8E1),
          border: Color(0xFFFFD54F),
          foreground: Color(0xFFF57F17),
        );
      case StatusBadgeType.error:
        return const _StatusBadgeColors(
          background: Color(0xFFFFEBEE),
          border: Color(0xFFEF9A9A),
          foreground: Color(0xFFB71C1C),
        );
      case StatusBadgeType.info:
        return const _StatusBadgeColors(
          background: Color(0xFFE3F2FD),
          border: Color(0xFF90CAF9),
          foreground: Color(0xFF0D47A1),
        );
      case StatusBadgeType.neutral:
        return const _StatusBadgeColors(
          background: Color(0xFFF5F5F5),
          border: Color(0xFFE0E0E0),
          foreground: Color(0xFF424242),
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
