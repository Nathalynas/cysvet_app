import 'package:flutter/material.dart';

import '../enums/sync_status_enum.dart';
import 'status_badge.dart';

class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({
    super.key,
    required this.status,
    this.compact = false,
  });

  final SyncStatusEnum status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(status);

    if (compact) {
      return Tooltip(
        message: status.label,
        child: StatusBadge(
          label: status.label,
          type: _typeFor(status),
          icon: icon,
        ),
      );
    }

    return StatusBadge(label: status.label, type: _typeFor(status), icon: icon);
  }

  IconData _iconFor(SyncStatusEnum status) {
    switch (status) {
      case SyncStatusEnum.synced:
        return Icons.cloud_done_outlined;
      case SyncStatusEnum.pending:
        return Icons.schedule_outlined;
      case SyncStatusEnum.syncing:
        return Icons.sync;
      case SyncStatusEnum.error:
        return Icons.cloud_off_outlined;
    }
  }

  StatusBadgeType _typeFor(SyncStatusEnum status) {
    switch (status) {
      case SyncStatusEnum.synced:
        return StatusBadgeType.success;
      case SyncStatusEnum.pending:
        return StatusBadgeType.warning;
      case SyncStatusEnum.syncing:
        return StatusBadgeType.info;
      case SyncStatusEnum.error:
        return StatusBadgeType.error;
    }
  }
}
