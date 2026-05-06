import 'package:flutter/material.dart';

import 'app_button.dart';

class AppForm extends StatefulWidget {
  const AppForm({
    super.key,
    required this.fields,
    this.rightFields,
    this.title,
    this.subtitle,
    this.actions,
    this.submitText = 'Salvar',
    this.cancelText = 'Cancelar',
    this.onSubmit,
    this.onCancel,
    this.isLoading = false,
    this.showDefaultActions = true,
    this.padding = const EdgeInsets.all(16),
    this.fieldsSpacing = 16,
    this.actionsSpacing = 12,
    this.minDualColumnWidth = 720,
    this.internalScroll = false,
  });

  final List<Widget> fields;
  final List<Widget>? rightFields;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final String submitText;
  final String cancelText;
  final VoidCallback? onSubmit;
  final VoidCallback? onCancel;
  final bool isLoading;
  final bool showDefaultActions;
  final EdgeInsetsGeometry padding;
  final double fieldsSpacing;
  final double actionsSpacing;
  final double minDualColumnWidth;
  final bool internalScroll;

  @override
  State<AppForm> createState() => _AppFormState();
}

class _AppFormState extends State<AppForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: widget.padding,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._buildHeader(context),
            LayoutBuilder(
              builder: (context, constraints) {
                return _buildFields(constraints.maxWidth);
              },
            ),
            ..._buildActions(),
          ],
        ),
      ),
    );

    if (!widget.internalScroll) {
      return content;
    }

    return SingleChildScrollView(child: content);
  }

  List<Widget> _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[];

    if (widget.title != null && widget.title!.isNotEmpty) {
      children.add(
        Text(
          widget.title!,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (widget.subtitle != null && widget.subtitle!.isNotEmpty) {
      children.add(
        Padding(
          padding: EdgeInsets.only(top: widget.title == null ? 0 : 6),
          child: Text(
            widget.subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    if (children.isNotEmpty) {
      children.add(SizedBox(height: widget.fieldsSpacing));
    }

    return children;
  }

  Widget _buildFields(double availableWidth) {
    final hasRightFields =
        widget.rightFields != null && widget.rightFields!.isNotEmpty;
    final useDualColumn =
        hasRightFields && availableWidth >= widget.minDualColumnWidth;

    if (!hasRightFields) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _withSpacing(widget.fields, widget.fieldsSpacing),
      );
    }

    if (!useDualColumn) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _withSpacing([
          ...widget.fields,
          ...widget.rightFields!,
        ], widget.fieldsSpacing),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _withSpacing(widget.fields, widget.fieldsSpacing),
          ),
        ),
        SizedBox(width: widget.fieldsSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _withSpacing(widget.rightFields!, widget.fieldsSpacing),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions() {
    final actions = <Widget>[...?widget.actions];

    if (widget.showDefaultActions) {
      actions.addAll([
        AppButton(
          text: widget.cancelText,
          outlined: true,
          onPressed: widget.isLoading ? null : widget.onCancel,
        ),
        AppButton(
          text: widget.submitText,
          loading: widget.isLoading,
          onPressed: _handleSubmit,
        ),
      ]);
    }

    if (actions.isEmpty) {
      return [];
    }

    return [
      SizedBox(height: widget.fieldsSpacing),
      Wrap(
        spacing: widget.actionsSpacing,
        runSpacing: widget.actionsSpacing,
        alignment: WrapAlignment.end,
        children: actions,
      ),
    ];
  }

  List<Widget> _withSpacing(List<Widget> widgets, double spacing) {
    if (widgets.isEmpty) {
      return [];
    }

    final children = <Widget>[];

    for (var index = 0; index < widgets.length; index++) {
      if (index > 0) {
        children.add(SizedBox(height: spacing));
      }

      children.add(widgets[index]);
    }

    return children;
  }

  void _handleSubmit() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    _formKey.currentState?.save();
    widget.onSubmit?.call();
  }
}
