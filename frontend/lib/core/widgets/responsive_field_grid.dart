import 'package:flutter/material.dart';

/// Campos lado a lado conforme a largura: 3 colunas a partir de 980 px, 2 a
/// partir de 640 px e 1 no celular.
class ResponsiveFieldGrid extends StatelessWidget {
  const ResponsiveFieldGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth >= 980
            ? 3
            : maxWidth >= 640
            ? 2
            : 1;
        final spacing = 12.0;
        final itemWidth = (maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(growable: false),
        );
      },
    );
  }
}
