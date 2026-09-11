import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../filters/dashboard_filter.dart';
import 'package:cysvet_app/providers/auth_state.dart';
import 'package:cysvet_app/api/dashboard_api.dart';
import 'package:cysvet_app/models/dashboard_metrics_model.dart';

final dashboardProvider = FutureProvider<DashboardMetricsModel>((ref) async {
  final session = ref.watch(authSessionProvider);
  final propertyId = ref.watch(dashboardPropertyFilterProvider);

  if (session == null) {
    throw StateError('Sessão indisponível.');
  }

  return ref.watch(dashboardRepositoryProvider).fetch(propertyId: propertyId);
});
