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
