import 'package:flutter/services.dart';

String formatDate(DateTime? date) {
  if (date == null) {
    return '--';
  }

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString().padLeft(4, '0');
  return '$day/$month/$year';
}

String formatPercent(double value) {
  return '${(value * 100).toStringAsFixed(1)}%';
}

String formatDecimal(double value) {
  return value.toStringAsFixed(1);
}

class PhoneInputFormatter extends TextInputFormatter {
  const PhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    final formatted = _format(limited);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String digits) {
    if (digits.isEmpty) return '';
    if (digits.length <= 2) return '($digits';

    final areaCode = digits.substring(0, 2);
    final rest = digits.substring(2);

    if (rest.length <= 4) {
      return '($areaCode) $rest';
    }

    final splitIndex = digits.length > 10 ? 5 : 4;
    final firstPart = rest.substring(0, splitIndex);
    final secondPart = rest.substring(splitIndex);

    return '($areaCode) $firstPart-$secondPart';
  }
}

class DateInputFormatter extends TextInputFormatter {
  const DateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 8 ? digits.substring(0, 8) : digits;
    final formatted = _format(limited);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String digits) {
    if (digits.length <= 2) return digits;
    if (digits.length <= 4) {
      return '${digits.substring(0, 2)}/${digits.substring(2)}';
    }

    return '${digits.substring(0, 2)}/${digits.substring(2, 4)}/${digits.substring(4)}';
  }
}

String formatDateInput(DateTime? date) {
  if (date == null) return '';

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString().padLeft(4, '0');
  return '$day/$month/$year';
}

DateTime? parseDateInput(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(trimmed);
  if (match == null) return DateTime.tryParse(trimmed);

  final day = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final year = int.tryParse(match.group(3)!);
  if (day == null || month == null || year == null) return null;

  final date = DateTime(year, month, day);
  if (date.day != day || date.month != month || date.year != year) {
    return null;
  }

  return date;
}
