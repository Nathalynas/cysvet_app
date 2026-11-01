import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/core/presentation/app_scaffold_messenger.dart';
import 'package:cysvet_app/core/widgets/app_button.dart';
import 'package:cysvet_app/core/widgets/app_dialog.dart';
import 'package:cysvet_app/providers/reproductive_shortcuts_provider.dart';

/// Situação reprodutiva em botões grandes: os atalhos do veterinário (os 4
/// padrão até ele escolher os seus, salvos no servidor) e "Outras situações"
/// com as demais. Usado na visita e no cadastro do animal.
class ReproductiveStatusPicker extends ConsumerStatefulWidget {
  const ReproductiveStatusPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  ConsumerState<ReproductiveStatusPicker> createState() =>
      _ReproductiveStatusPickerState();
}

class _ReproductiveStatusPickerState
    extends ConsumerState<ReproductiveStatusPicker> {
  bool _showOthers = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shortcuts =
        ref.watch(reproductiveShortcutsProvider).asData?.value ??
        defaultReproductiveShortcuts;
    final value = widget.value;
    final current = value == null || value.isEmpty
        ? null
        : AnimalReproductiveStatus.fromApiValue(value);
    final others = reproductiveShortcutOptions
        .where((status) => !shortcuts.contains(status))
        .toList(growable: false);
    final currentIsOther = current != null && !shortcuts.contains(current);
    final showOthers = _showOthers || currentIsOther;

    Widget option(AnimalReproductiveStatus status, {double height = 52}) {
      final selected = current == status;
      final child = Text(status.label, overflow: TextOverflow.ellipsis);
      return SizedBox(
        height: height,
        child: selected
            ? FilledButton.icon(
                onPressed: () => widget.onChanged(status.apiValue),
                icon: Icon(status.icon),
                label: child,
              )
            : OutlinedButton.icon(
                onPressed: () => widget.onChanged(status.apiValue),
                icon: Icon(status.icon),
                label: child,
              ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Situação reprodutiva',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Escolher atalhos',
              visualDensity: VisualDensity.compact,
              onPressed: () => _ShortcutsEditor.show(context, shortcuts),
              icon: const Icon(Icons.tune_rounded, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 640 ? 4 : 2;
            const spacing = 8.0;
            final width =
                (constraints.maxWidth - (columns - 1) * spacing) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final status in shortcuts)
                  SizedBox(width: width, child: option(status)),
              ],
            );
          },
        ),
        if (others.isNotEmpty) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: currentIsOther
                  ? null
                  : () => setState(() => _showOthers = !_showOthers),
              icon: Icon(
                showOthers ? Icons.expand_less : Icons.expand_more,
                size: 20,
              ),
              label: Text(
                showOthers
                    ? 'Outras situações'
                    : 'Outras situações (${others.length})',
              ),
            ),
          ),
          if (showOthers)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in others) option(status, height: 40),
                if (current != null)
                  SizedBox(
                    height: 40,
                    child: TextButton.icon(
                      onPressed: () => widget.onChanged(null),
                      icon: const Icon(Icons.backspace_outlined, size: 18),
                      label: const Text('Não informado'),
                    ),
                  ),
              ],
            ),
        ],
      ],
    );
  }
}

/// Escolha dos atalhos de situação reprodutiva, salva no servidor.
class _ShortcutsEditor extends ConsumerStatefulWidget {
  const _ShortcutsEditor({required this.initial});

  final List<AnimalReproductiveStatus> initial;

  static Future<void> show(
    BuildContext context,
    List<AnimalReproductiveStatus> current,
  ) {
    return AppDialog.show<void>(
      context: context,
      title: 'Atalhos da situação reprodutiva',
      width: 480,
      useInternalScroll: true,
      fullscreenOnMobile: true,
      content: _ShortcutsEditor(initial: current),
    );
  }

  @override
  ConsumerState<_ShortcutsEditor> createState() => _ShortcutsEditorState();
}

class _ShortcutsEditorState extends ConsumerState<_ShortcutsEditor> {
  late final List<AnimalReproductiveStatus> _selected = [...widget.initial];
  bool _saving = false;

  Future<void> _save(List<AnimalReproductiveStatus>? shortcuts) async {
    setState(() => _saving = true);
    try {
      final synced = await ref
          .read(reproductiveShortcutsProvider.notifier)
          .save(shortcuts);
      if (!mounted) return;
      Navigator.of(context).pop();
      if (synced) {
        showAppSuccess('Atalhos salvos.');
      } else {
        showAppInfo(
          'Atalhos salvos no aparelho. Serão enviados quando houver conexão.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _saving = false);
      showAppError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final full = _selected.length >= maxReproductiveShortcuts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Marque até $maxReproductiveShortcuts situações para aparecerem como '
          'botões na visita, na ordem em que forem marcadas. As outras ficam '
          'em "Outras situações". Vale em qualquer aparelho em que você entrar.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        for (final status in reproductiveShortcutOptions)
          CheckboxListTile(
            value: _selected.contains(status),
            dense: true,
            contentPadding: EdgeInsets.zero,
            secondary: Icon(status.icon),
            title: Text(status.label),
            subtitle: _selected.contains(status)
                ? Text('Atalho ${_selected.indexOf(status) + 1}')
                : null,
            onChanged: _saving || (!_selected.contains(status) && full)
                ? null
                : (checked) => setState(() {
                    if (checked == true) {
                      _selected.add(status);
                    } else {
                      _selected.remove(status);
                    }
                  }),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.end,
          children: [
            AppButton(
              text: 'Voltar ao padrão',
              outlined: true,
              height: 40,
              onPressed: _saving ? null : () => _save(null),
            ),
            AppButton(
              text: 'Salvar',
              height: 40,
              loading: _saving,
              onPressed: _saving || _selected.isEmpty
                  ? null
                  : () => _save(List.unmodifiable(_selected)),
            ),
          ],
        ),
      ],
    );
  }
}
