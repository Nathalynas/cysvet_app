import 'package:cysvet_app/core/widgets/app_card.dart';
import 'package:flutter/material.dart';

class AppTableColumn<T> {
  const AppTableColumn({
    required this.label,
    required this.cellBuilder,
    this.mobileCellBuilder,
    this.flex = 1,
    this.alignment = Alignment.centerLeft,
    this.mobileLabel,
  });

  final String label;
  final String? mobileLabel;
  final Widget Function(BuildContext context, T item) cellBuilder;
  final Widget Function(BuildContext context, T item)? mobileCellBuilder;
  final int flex;
  final AlignmentGeometry alignment;
}

class AppTable<T> extends StatelessWidget {
  const AppTable({
    super.key,
    required this.rows,
    required this.columns,
    this.mobileTitleBuilder,
    this.footerLabel,
    this.emptyMessage = 'Nenhum registro encontrado.',
    this.mobileBreakpoint = 720,
    this.equalColumnWidth = false,
  });

  final List<T> rows;
  final List<AppTableColumn<T>> columns;
  final Widget Function(BuildContext context, T item)? mobileTitleBuilder;
  final String? footerLabel;
  final String emptyMessage;
  final double mobileBreakpoint;
  final bool equalColumnWidth;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < mobileBreakpoint) {
          return _AppTableCards<T>(
            rows: rows,
            columns: columns,
            titleBuilder: mobileTitleBuilder,
            footerLabel: footerLabel,
            emptyMessage: emptyMessage,
          );
        }

        return _AppTableGrid<T>(
          rows: rows,
          columns: columns,
          footerLabel: footerLabel,
          emptyMessage: emptyMessage,
          equalColumnWidth: equalColumnWidth,
        );
      },
    );
  }
}

class _AppTableGrid<T> extends StatelessWidget {
  const _AppTableGrid({
    required this.rows,
    required this.columns,
    required this.footerLabel,
    required this.emptyMessage,
    required this.equalColumnWidth,
  });

  final List<T> rows;
  final List<AppTableColumn<T>> columns;
  final String? footerLabel;
  final String emptyMessage;
  final bool equalColumnWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AppTableRow<T>(
            columns: columns,
            item: null,
            isHeader: true,
            backgroundColor: colorScheme.surface,
            equalColumnWidth: equalColumnWidth,
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (var index = 0; index < rows.length; index++) ...[
              Divider(color: colorScheme.outline.withValues(alpha: 0.26)),
              _AppTableRow<T>(
                columns: columns,
                item: rows[index],
                backgroundColor: index.isEven
                    ? colorScheme.surface
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.28,
                      ),
                equalColumnWidth: equalColumnWidth,
              ),
            ],
          if (footerLabel != null) ...[
            Divider(color: colorScheme.outline.withValues(alpha: 0.26)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              color: colorScheme.surface,
              child: Text(
                footerLabel!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AppTableRow<T> extends StatelessWidget {
  const _AppTableRow({
    required this.columns,
    required this.item,
    this.isHeader = false,
    this.backgroundColor,
    this.equalColumnWidth = false,
  });

  final List<AppTableColumn<T>> columns;
  final T? item;
  final bool isHeader;
  final Color? backgroundColor;
  final bool equalColumnWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ColoredBox(
      color: backgroundColor ?? Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: isHeader ? 15 : 16,
        ),
        child: Row(
          children: [
            for (var index = 0; index < columns.length; index++) ...[
              Expanded(
                flex: equalColumnWidth ? 1 : columns[index].flex,
                child: Align(
                  alignment: isHeader
                      ? Alignment.center
                      : columns[index].alignment,
                  child: isHeader
                      ? Text(
                          columns[index].label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            height: 1.18,
                          ),
                        )
                      : DefaultTextStyle.merge(
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          child: columns[index].cellBuilder(context, item as T),
                        ),
                ),
              ),
              if (index < columns.length - 1) const SizedBox(width: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppTableCards<T> extends StatelessWidget {
  const _AppTableCards({
    required this.rows,
    required this.columns,
    required this.titleBuilder,
    required this.footerLabel,
    required this.emptyMessage,
  });

  final List<T> rows;
  final List<AppTableColumn<T>> columns;
  final Widget Function(BuildContext context, T item)? titleBuilder;
  final String? footerLabel;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (rows.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (titleBuilder != null) ...[
                    titleBuilder!(context, rows[index]),
                    const SizedBox(height: 12),
                    Divider(color: colorScheme.outline.withValues(alpha: 0.7)),
                    const SizedBox(height: 10),
                  ],
                  for (
                    var columnIndex = 0;
                    columnIndex < columns.length;
                    columnIndex++
                  ) ...[
                    _AppTableCardField<T>(
                      label:
                          columns[columnIndex].mobileLabel ??
                          columns[columnIndex].label,
                      child:
                          columns[columnIndex].mobileCellBuilder?.call(
                            context,
                            rows[index],
                          ) ??
                          columns[columnIndex].cellBuilder(
                            context,
                            rows[index],
                          ),
                    ),
                    if (columnIndex < columns.length - 1)
                      const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
          if (index < rows.length - 1) const SizedBox(height: 12),
        ],
        if (footerLabel != null) ...[
          const SizedBox(height: 12),
          Text(
            footerLabel!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _AppTableCardField<T> extends StatelessWidget {
  const _AppTableCardField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}
