import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import 'app_button.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    this.title,
    this.subtitle,
    required this.content,
    this.actions,
    this.headerActions,
    this.persistent = false,
    this.width = 420,
    this.height,
    this.padding = const EdgeInsets.all(24),
    this.fullscreen = false,
    this.isFullscreen = false,
    this.fullscreenOnMobile = false,
    this.headerIndent = 0,
    this.fullscreenBodyPadding = const EdgeInsets.all(24),
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
  final List<Widget>? headerActions;
  final bool persistent;
  final double width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final bool fullscreen;
  final bool isFullscreen;
  final bool fullscreenOnMobile;
  final double headerIndent;
  final EdgeInsetsGeometry fullscreenBodyPadding;
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
    List<Widget>? headerActions,
    bool persistent = false,
    bool fullscreen = false,
    bool useInternalScroll = false,
    double width = 420,
    double? height,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24),
    bool isFullscreen = false,
    bool fullscreenOnMobile = false,
    double headerIndent = 0,
    EdgeInsetsGeometry fullscreenBodyPadding = const EdgeInsets.all(24),
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
          headerActions: headerActions,
          persistent: persistent,
          fullscreen: fullscreen,
          isFullscreen: isFullscreen,
          fullscreenOnMobile: fullscreenOnMobile,
          headerIndent: headerIndent,
          fullscreenBodyPadding: fullscreenBodyPadding,
          useInternalScroll: useInternalScroll,
          width: width,
          height: height,
          padding: padding,
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
    final effectiveFullscreen =
        fullscreen ||
        isFullscreen ||
        (fullscreenOnMobile && size.width < MOBILE_WIDTH);
    final maxHeight = effectiveFullscreen ? size.height : size.height * 0.9;
    final dialogActions = _buildActions(context);
    final body = _DialogBody(
      useInternalScroll: useInternalScroll,
      expanded: effectiveFullscreen || height != null,
      child: content,
    );
    final bodyAndActions = Padding(
      padding: effectiveFullscreen ? fullscreenBodyPadding : EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: effectiveFullscreen || height != null
            ? MainAxisSize.max
            : MainAxisSize.min,
        children: [
          body,
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
    );

    return Dialog(
      insetPadding: effectiveFullscreen
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(effectiveFullscreen ? 0 : 12),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: effectiveFullscreen ? size.width : width,
          maxHeight: maxHeight,
        ),
        child: SizedBox(
          width: effectiveFullscreen ? size.width : width,
          height: effectiveFullscreen ? size.height : height,
          child: Padding(
            padding: effectiveFullscreen ? EdgeInsets.zero : padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: effectiveFullscreen || height != null
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              children: [
                if (_hasHeader) ...[
                  _DialogHeader(
                    title: title,
                    subtitle: subtitle,
                    actions: headerActions,
                    showCloseButton: showCloseButton,
                    fullscreen: effectiveFullscreen,
                    indent: headerIndent,
                  ),
                  if (!effectiveFullscreen) const SizedBox(height: 10),
                ],
                if (effectiveFullscreen)
                  Expanded(child: bodyAndActions)
                else if (height != null)
                  Expanded(child: bodyAndActions)
                else if (useInternalScroll)
                  Flexible(fit: FlexFit.loose, child: bodyAndActions)
                else
                  bodyAndActions,
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
      (subtitle != null && subtitle!.isNotEmpty) ||
      (headerActions != null && headerActions!.isNotEmpty);

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
        height: 40,
        fontSize: 14,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        onPressed: confirmLoading
            ? null
            : (onCancel ?? () => Navigator.of(context).maybePop()),
      ),
      AppButton(
        text: confirmText ?? 'Confirmar',
        loading: confirmLoading,
        height: 40,
        fontSize: 14,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
    this.actions,
    required this.showCloseButton,
    required this.fullscreen,
    required this.indent,
  });

  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showCloseButton;
  final bool fullscreen;
  final double indent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasTitle = title != null && title!.isNotEmpty;
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: theme.brightness == Brightness.dark
          ? colorScheme.onSurface
          : colorScheme.primary,
      fontSize: 20,
      height: 1.2,
      fontWeight: FontWeight.w700,
    );
    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );
    final headerActions = actions ?? const <Widget>[];
    final actionColor = fullscreen
        ? colorScheme.onPrimary
        : colorScheme.primary;
    final actionsWidget = headerActions.isEmpty
        ? null
        : IconTheme.merge(
            data: IconThemeData(color: actionColor),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: actionColor),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.end,
                children: headerActions,
              ),
            ),
          );

    if (fullscreen) {
      return Material(
        color: colorScheme.primary,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 64,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 8),
                if (showCloseButton) ...[
                  IconButton(
                    tooltip: 'Voltar',
                    color: colorScheme.onPrimary,
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ] else
                  const SizedBox(width: 56),
                if (indent > 0) SizedBox(width: indent),
                Expanded(
                  child: Text(
                    hasTitle ? title! : '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (actionsWidget != null) ...[
                  const SizedBox(width: 8),
                  actionsWidget,
                ],
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      );
    }

    if (!hasTitle) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (indent > 0) SizedBox(width: indent),
          Expanded(
            child: hasSubtitle
                ? Text(subtitle!, style: subtitleStyle)
                : const SizedBox.shrink(),
          ),
          if (actionsWidget != null) ...[
            const SizedBox(width: 12),
            actionsWidget,
          ],
          if (showCloseButton) ...[
            const SizedBox(width: 12),
            _CloseDialogButton(colorScheme: colorScheme),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (indent > 0) SizedBox(width: indent),
            Expanded(child: Text(title!, style: titleStyle)),
            if (actionsWidget != null) ...[
              const SizedBox(width: 12),
              actionsWidget,
            ],
            if (showCloseButton) ...[
              const SizedBox(width: 12),
              _CloseDialogButton(colorScheme: colorScheme),
            ],
          ],
        ),
        if (hasSubtitle)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(subtitle!, style: subtitleStyle),
          ),
      ],
    );
  }
}

class _CloseDialogButton extends StatelessWidget {
  const _CloseDialogButton({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 40,
      child: IconButton(
        tooltip: 'Fechar',
        mouseCursor: SystemMouseCursors.click,
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: colorScheme.primary,
          fixedSize: const Size.square(40),
          minimumSize: const Size.square(40),
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.close, size: 20),
      ),
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
      if (useInternalScroll) {
        return Flexible(fit: FlexFit.loose, child: body);
      }

      return body;
    }

    return Expanded(child: body);
  }
}
