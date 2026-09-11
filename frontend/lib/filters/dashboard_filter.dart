import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardPropertyFilterProvider =
    NotifierProvider<DashboardPropertyFilterNotifier, int?>(
      DashboardPropertyFilterNotifier.new,
    );

final dashboardPeriodFilterProvider =
    NotifierProvider<DashboardPeriodFilterNotifier, DashboardPeriodFilter>(
      DashboardPeriodFilterNotifier.new,
    );

enum DashboardPeriodFilter {
  last30('Últimos 30 dias'),
  last90('Últimos 90 dias'),
  currentMonth('Este mês'),
  currentYear('Este ano'),
  all('Todo o histórico');

  const DashboardPeriodFilter(this.label);

  final String label;
}

class DashboardPropertyFilterNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? value) {
    state = value;
  }
}

class DashboardPeriodFilterNotifier extends Notifier<DashboardPeriodFilter> {
  @override
  DashboardPeriodFilter build() => DashboardPeriodFilter.last30;

  void set(DashboardPeriodFilter? value) {
    if (value == null) return;
    state = value;
  }
}
