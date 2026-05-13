import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/animal_status.dart';
import '../../auth/application/auth_state.dart';
import '../data/animals_repository.dart';
import '../domain/animal_summary_model.dart';

final animalsBusyProvider = NotifierProvider<AnimalsBusyNotifier, bool>(
  AnimalsBusyNotifier.new,
);

final animalsControllerProvider = Provider<AnimalsController>((ref) {
  return AnimalsController(ref);
});

final localAnimalsProvider =
    NotifierProvider<LocalAnimalsNotifier, Map<int, AnimalSummaryModel>>(
      LocalAnimalsNotifier.new,
    );

final deletedAnimalsProvider =
    NotifierProvider<DeletedAnimalsNotifier, Set<int>>(
      DeletedAnimalsNotifier.new,
    );

final animalsPropertyFilterProvider =
    NotifierProvider<AnimalsPropertyFilterNotifier, int?>(
      AnimalsPropertyFilterNotifier.new,
    );

final animalsProvider = FutureProvider<List<AnimalSummaryModel>>((ref) async {
  final session = ref.watch(authSessionProvider);
  final propertyId = ref.watch(animalsPropertyFilterProvider);
  final localItems = ref.watch(localAnimalsProvider);
  final deletedIds = ref.watch(deletedAnimalsProvider);

  if (session == null) {
    throw StateError('Sessao indisponivel.');
  }

  final remoteItems = await ref
      .watch(animalsRepositoryProvider)
      .list(propertyId: propertyId);
  final merged =
      {
        for (final animal in remoteItems)
          animal.id: localItems[animal.id] ?? animal,
        ...localItems,
      }.values.where((animal) {
        return !deletedIds.contains(animal.id) &&
            (propertyId == null || animal.idPropriedade == propertyId);
      }).toList();
  merged.sort((a, b) => a.codigo.compareTo(b.codigo));
  return merged;
});

class AnimalsPropertyFilterNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? value) {
    state = value;
  }
}

class AnimalsController {
  const AnimalsController(this._ref);

  final Ref _ref;

  Future<void> save(AnimalSummaryModel animal) async {
    _ref.read(animalsBusyProvider.notifier).setBusy(true);
    try {
      final repository = _ref.read(animalsRepositoryProvider);
      final saved = animal.id <= 0
          ? await repository.create(animal)
          : await repository.update(animal);
      final merged = saved.copyWith(sexo: animal.sexo, status: animal.status);
      _ref.read(localAnimalsProvider.notifier).remove(animal.id);
      _ref.invalidate(animalsProvider);
      _ref.read(localAnimalsProvider.notifier).save(merged);
    } finally {
      _ref.read(animalsBusyProvider.notifier).setBusy(false);
    }
  }

  Future<void> importAnimals(List<AnimalSummaryModel> animals) async {
    _ref.read(animalsBusyProvider.notifier).setBusy(true);
    try {
      _ref.read(localAnimalsProvider.notifier).saveAll(animals);
    } finally {
      _ref.read(animalsBusyProvider.notifier).setBusy(false);
    }
  }

  Future<void> inactivate(int id) async {
    _ref.read(animalsBusyProvider.notifier).setBusy(true);
    try {
      _ref.read(localAnimalsProvider.notifier).inactivate(id);
    } finally {
      _ref.read(animalsBusyProvider.notifier).setBusy(false);
    }
  }

  Future<void> activate(int id) async {
    _ref.read(animalsBusyProvider.notifier).setBusy(true);
    try {
      _ref.read(localAnimalsProvider.notifier).activate(id);
    } finally {
      _ref.read(animalsBusyProvider.notifier).setBusy(false);
    }
  }

  Future<void> delete(int id) async {
    _ref.read(animalsBusyProvider.notifier).setBusy(true);
    try {
      if (id > 0) {
        await _ref.read(animalsRepositoryProvider).delete(id);
        _ref.read(localAnimalsProvider.notifier).remove(id);
        _ref.invalidate(animalsProvider);
      } else {
        _ref.read(deletedAnimalsProvider.notifier).delete(id);
      }
    } finally {
      _ref.read(animalsBusyProvider.notifier).setBusy(false);
    }
  }
}

class LocalAnimalsNotifier extends Notifier<Map<int, AnimalSummaryModel>> {
  @override
  Map<int, AnimalSummaryModel> build() => const {};

  void save(AnimalSummaryModel animal) {
    final id = animal.id == 0 ? _nextLocalId() : animal.id;
    state = {...state, id: animal.copyWith(id: id)};
  }

  void remove(int id) {
    if (!state.containsKey(id)) return;
    final updated = {...state}..remove(id);
    state = updated;
  }

  void saveAll(List<AnimalSummaryModel> animals) {
    var nextId = _nextLocalId();
    final updated = {...state};

    for (final animal in animals) {
      final id = animal.id == 0 ? nextId-- : animal.id;
      updated[id] = animal.copyWith(id: id);
    }

    state = updated;
  }

  void inactivate(int id) {
    final current = state[id] ?? _findRemoteAnimal(id);
    if (current == null) return;
    state = {...state, id: current.copyWith(status: AnimalStatus.inactive)};
  }

  void activate(int id) {
    final current = state[id] ?? _findRemoteAnimal(id);
    if (current == null) return;
    state = {...state, id: current.copyWith(status: AnimalStatus.active)};
  }

  int _nextLocalId() {
    final ids = state.keys.where((id) => id < 0);
    if (ids.isEmpty) return -1;
    return ids.reduce((a, b) => a < b ? a : b) - 1;
  }

  AnimalSummaryModel? _findRemoteAnimal(int id) {
    return ref.read(animalsProvider).asData?.value.where((item) {
      return item.id == id;
    }).firstOrNull;
  }
}

class AnimalsBusyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setBusy(bool value) => state = value;
}

class DeletedAnimalsNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => const {};

  void delete(int id) {
    state = {...state, id};
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
