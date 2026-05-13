import 'package:flutter/material.dart';

import '../network/api_error.dart';

final appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

enum AppSnackBarType { success, error, warning, info }

void showAppSnackBar(SnackBar snackBar) {
  final messenger = appScaffoldMessengerKey.currentState;
  if (messenger == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}

void showAppSuccess(String message) {
  showTypedAppSnackBar(message, type: AppSnackBarType.success);
}

void showAppError(Object error, {String? fallbackMessage}) {
  showTypedAppSnackBar(
    describeError(error, fallbackMessage: fallbackMessage),
    type: AppSnackBarType.error,
  );
}

void showAppWarning(String message) {
  showTypedAppSnackBar(message, type: AppSnackBarType.warning);
}

void showAppInfo(String message) {
  showTypedAppSnackBar(message, type: AppSnackBarType.info);
}

void showTypedAppSnackBar(
  String message, {
  AppSnackBarType type = AppSnackBarType.info,
  Duration duration = const Duration(seconds:3),
}) {
  final messenger = appScaffoldMessengerKey.currentState;
  final context = messenger?.context;
  if (context == null) return;

  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final backgroundColor = switch (type) {
    AppSnackBarType.success => Colors.green.shade700,
    AppSnackBarType.error => colorScheme.error,
    AppSnackBarType.warning => Colors.orange.shade800,
    AppSnackBarType.info => colorScheme.inverseSurface,
  };
  final foregroundColor = switch (type) {
    AppSnackBarType.error => colorScheme.onError,
    AppSnackBarType.info => colorScheme.onInverseSurface,
    _ => Colors.white,
  };

  showAppSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      closeIconColor: foregroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
