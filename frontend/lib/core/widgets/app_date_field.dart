import 'package:flutter/material.dart';

import 'package:cysvet_app/core/utils/formatters.dart';
import 'package:cysvet_app/core/widgets/app_text_field.dart';

/// Campo de data digitável, com calendário e, opcionalmente, atalho "Hoje".
class AppDateField extends StatefulWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.showToday = false,
    this.required = false,
    this.allowFuture = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?>? onChanged;
  final bool showToday;

  /// Exige uma data válida ao validar o formulário.
  final bool required;

  /// Nascimento, parto, IA e secagem são fatos que já aconteceram: por
  /// padrão uma data depois de hoje é recusada (ex.: IA digitada como 2062).
  final bool allowFuture;

  @override
  State<AppDateField> createState() => _AppDateFieldState();
}

class _AppDateFieldState extends State<AppDateField> {
  late final TextEditingController _controller = TextEditingController(
    text: formatDateInput(widget.value),
  );

  @override
  void didUpdateWidget(covariant AppDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Data trocada por fora (calendário, "Hoje"); enquanto a pessoa digita,
    // o texto incompleto e o valor (nulo) coincidem e nada é sobrescrito.
    // Compara o dia: datas lidas do aparelho voltam em UTC.
    final typed = parseDateInput(_controller.text);
    final same = typed == null || widget.value == null
        ? typed == widget.value
        : DateUtils.isSameDay(typed, widget.value!.toLocal());
    if (!same) {
      _controller.text = formatDateInput(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isFuture(DateTime value) =>
      !widget.allowFuture &&
      DateUtils.dateOnly(value).isAfter(DateUtils.dateOnly(DateTime.now()));

  void _set(DateTime? value) {
    final date = value == null ? null : DateUtils.dateOnly(value);
    _controller.text = formatDateInput(date);
    widget.onChanged?.call(date);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.value == null || _isFuture(widget.value!)
          ? now
          : widget.value!,
      firstDate: DateTime(now.year - 30),
      lastDate: widget.allowFuture ? DateTime(now.year + 2) : now,
      helpText: widget.label,
    );
    if (picked != null) _set(picked);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onChanged != null;
    final today = DateUtils.dateOnly(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          label: widget.label,
          hint: 'DD/MM/AAAA',
          controller: _controller,
          readOnly: !enabled,
          required: widget.required,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (text) {
            final value = (text ?? '').trim();
            if (value.isEmpty) {
              return widget.required ? 'Informe a data' : null;
            }
            final parsed = parseDateInput(value);
            if (parsed == null) return 'Informe uma data válida';
            return _isFuture(parsed) ? 'A data não pode ser depois de hoje' : null;
          },
          keyboardType: TextInputType.number,
          inputFormatters: const [DateInputFormatter()],
          onChanged: enabled
              ? (text) {
                  final parsed = parseDateInput(text);
                  // Data futura fica só no campo, com o aviso; não vai
                  // para o animal até ser corrigida.
                  if (parsed != null && _isFuture(parsed)) return;
                  widget.onChanged!(parsed);
                }
              : null,
          suffixIcon: enabled
              ? IconButton(
                  tooltip: 'Abrir calendário',
                  icon: const Icon(Icons.calendar_month_outlined),
                  onPressed: _pickDate,
                )
              : null,
        ),
        if (widget.showToday &&
            enabled &&
            !DateUtils.isSameDay(widget.value?.toLocal(), today))
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _set(today),
              icon: const Icon(Icons.today_outlined, size: 18),
              label: const Text('Usar hoje'),
            ),
          ),
      ],
    );
  }
}
