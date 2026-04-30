import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_state.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_metrics.dart';

final dashboardPropertyFilterProvider =
    NotifierProvider<DashboardPropertyFilterNotifier, int?>(
      DashboardPropertyFilterNotifier.new,
    );

final dashboardProvider = FutureProvider<DashboardMetrics>((ref) async {
  final session = ref.watch(authSessionProvider);
  final propertyId = ref.watch(dashboardPropertyFilterProvider);

  if (session == null) {
    throw StateError('Sessao indisponivel.');
  }

  return ref.watch(dashboardRepositoryProvider).fetch(propertyId: propertyId);
});

class DashboardPropertyFilterNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? value) {
    state = value;
  }
}
