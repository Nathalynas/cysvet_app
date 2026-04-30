import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_state.dart';
import '../data/visits_repository.dart';
import '../domain/visit_summary.dart';

final visitsPropertyFilterProvider =
    NotifierProvider<VisitsPropertyFilterNotifier, int?>(
      VisitsPropertyFilterNotifier.new,
    );

final visitsProvider = FutureProvider<List<VisitSummary>>((ref) async {
  final session = ref.watch(authSessionProvider);
  final propertyId = ref.watch(visitsPropertyFilterProvider);

  if (session == null) {
    throw StateError('Sessao indisponivel.');
  }

  return ref.watch(visitsRepositoryProvider).list(propertyId: propertyId);
});

class VisitsPropertyFilterNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? value) {
    state = value;
  }
}
