import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../core/enums/animal_status.dart';

final animalsSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

final animalsStatusFilterProvider =
    StateProvider.autoDispose<AnimalStatusFilter>((ref) {
      return AnimalStatusFilter.active;
    });

final animalsReproductiveStatusFilterProvider =
    StateProvider.autoDispose<AnimalReproductiveStatus?>((ref) => null);

final animalsPropertyFilterProvider =
    NotifierProvider<AnimalsPropertyFilterNotifier, int?>(
      AnimalsPropertyFilterNotifier.new,
    );

class AnimalsPropertyFilterNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? value) {
    state = value;
  }
}
