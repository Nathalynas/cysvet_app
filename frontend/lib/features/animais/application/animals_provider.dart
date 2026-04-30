import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_state.dart';
import '../data/animals_repository.dart';
import '../domain/animal_summary.dart';

final animalsPropertyFilterProvider =
    NotifierProvider<AnimalsPropertyFilterNotifier, int?>(
      AnimalsPropertyFilterNotifier.new,
    );

final animalsProvider = FutureProvider<List<AnimalSummary>>((ref) async {
  final session = ref.watch(authSessionProvider);
  final propertyId = ref.watch(animalsPropertyFilterProvider);

  if (session == null) {
    throw StateError('Sessao indisponivel.');
  }

  return ref.watch(animalsRepositoryProvider).list(propertyId: propertyId);
});

class AnimalsPropertyFilterNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? value) {
    state = value;
  }
}
