import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'app_button.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    this.title,
    this.subtitle,
    required this.content,
    this.actions,
    this.persistent = false,
    this.width = 420,
    this.height,
    this.padding = const EdgeInsets.all(24),
    this.fullscreen = false,
    this.useInternalScroll = false,
    this.showCloseButton = true,
    this.showDefaultActions = false,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.confirmLoading = false,
  });

  final String? title;
  final String? subtitle;
  final Widget content;
  final List<Widget>? actions;
  final bool persistent;
  final double width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final bool fullscreen;
  final bool useInternalScroll;
  final bool showCloseButton;
  final bool showDefaultActions;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool confirmLoading;

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? subtitle,
    required Widget content,
    List<Widget>? actions,
    bool persistent = false,
    bool fullscreen = false,
    bool useInternalScroll = false,
    double width = 420,
    double? height,
    bool showCloseButton = true,
    bool showDefaultActions = false,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool confirmLoading = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: !persistent,
      builder: (context) {
        return AppDialog(
          title: title,
          subtitle: subtitle,
          content: content,
          actions: actions,
          persistent: persistent,
          fullscreen: fullscreen,
          useInternalScroll: useInternalScroll,
          width: width,
          height: height,
          showCloseButton: showCloseButton,
          showDefaultActions: showDefaultActions,
          confirmText: confirmText,
          cancelText: cancelText,
          onConfirm: onConfirm,
          onCancel: onCancel,
          confirmLoading: confirmLoading,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final maxHeight = fullscreen ? size.height : size.height * 0.9;
    final dialogActions = _buildActions(context);

    return Dialog(
      insetPadding: fullscreen
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(fullscreen ? 0 : 12),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: fullscreen ? size.width : width,
          maxHeight: maxHeight,
        ),
        child: SizedBox(
          width: fullscreen ? size.width : width,
          height: fullscreen ? size.height : height,
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: fullscreen || height != null
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              children: [
                if (_hasHeader) ...[
                  _DialogHeader(
                    title: title,
                    subtitle: subtitle,
                    showCloseButton: showCloseButton,
                  ),
                  const SizedBox(height: 16),
                ],
                _DialogBody(
                  useInternalScroll: useInternalScroll,
                  expanded: fullscreen || height != null,
                  child: content,
                ),
                if (dialogActions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.end,
                    children: dialogActions,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasHeader =>
      showCloseButton ||
      (title != null && title!.isNotEmpty) ||
      (subtitle != null && subtitle!.isNotEmpty);

  bool get _shouldShowDefaultActions =>
      showDefaultActions ||
      confirmText != null ||
      cancelText != null ||
      onConfirm != null ||
      onCancel != null ||
      confirmLoading;

  List<Widget> _buildActions(BuildContext context) {
    final dialogActions = <Widget>[...?actions];

    if (!_shouldShowDefaultActions) {
      return dialogActions;
    }

    dialogActions.addAll([
      AppButton(
        text: cancelText ?? 'Cancelar',
        outlined: true,
        onPressed: confirmLoading
            ? null
            : (onCancel ?? () => Navigator.of(context).maybePop()),
      ),
      AppButton(
        text: confirmText ?? 'Confirmar',
        loading: confirmLoading,
        onPressed: onConfirm ?? () => Navigator.of(context).maybePop(),
      ),
    ]);

    return dialogActions;
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    this.title,
    this.subtitle,
    required this.showCloseButton,
  });

  final String? title;
  final String? subtitle;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null && title!.isNotEmpty)
                Text(
                  title!,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                    top: title == null || title!.isEmpty ? 0 : 6,
                  ),
                  child: Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showCloseButton)
          IconButton(
            tooltip: 'Fechar',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }
}

class _DialogBody extends StatelessWidget {
  const _DialogBody({
    required this.child,
    required this.useInternalScroll,
    required this.expanded,
  });

  final Widget child;
  final bool useInternalScroll;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final body = useInternalScroll
        ? SingleChildScrollView(child: child)
        : child;

    if (!expanded) {
      return Flexible(fit: FlexFit.loose, child: body);
    }

    return Expanded(child: body);
  }
}
