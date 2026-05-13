import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_state.dart';
import '../../../core/enums/property_status.dart';
import '../data/properties_repository.dart';
import '../domain/property_summary_model.dart';

final propertiesBusyProvider = NotifierProvider<PropertiesBusyNotifier, bool>(
  PropertiesBusyNotifier.new,
);

final propertiesControllerProvider = Provider<PropertiesController>((ref) {
  return PropertiesController(ref);
});

final localPropertiesProvider =
    NotifierProvider<LocalPropertiesNotifier, Map<int, PropertySummaryModel>>(
      LocalPropertiesNotifier.new,
    );

final deletedPropertiesProvider =
    NotifierProvider<DeletedPropertiesNotifier, Set<int>>(
      DeletedPropertiesNotifier.new,
    );

final propertiesProvider = FutureProvider<List<PropertySummaryModel>>((
  ref,
) async {
  final session = ref.watch(authSessionProvider);
  final localItems = ref.watch(localPropertiesProvider);
  final deletedIds = ref.watch(deletedPropertiesProvider);

  if (session == null) {
    throw StateError('Sessao indisponivel.');
  }

  final remoteItems = await ref.watch(propertiesRepositoryProvider).list();
  final merged = {
    for (final property in remoteItems)
      property.id: localItems[property.id] ?? property,
    ...localItems,
  }.values.where((property) => !deletedIds.contains(property.id)).toList();
  merged.sort((a, b) => a.nome.compareTo(b.nome));
  return merged;
});

class PropertiesController {
  const PropertiesController(this._ref);

  final Ref _ref;

  Future<void> save(PropertySummaryModel property) async {
    _ref.read(propertiesBusyProvider.notifier).setBusy(true);
    try {
      final repository = _ref.read(propertiesRepositoryProvider);
      final saved = property.id <= 0
          ? await repository.create(property)
          : await repository.update(property);
      final merged = saved.copyWith(
        contato: property.contato,
        status: property.status,
      );
      _ref.read(localPropertiesProvider.notifier).remove(property.id);
      _ref.invalidate(propertiesProvider);
      _ref.read(localPropertiesProvider.notifier).save(merged);
    } finally {
      _ref.read(propertiesBusyProvider.notifier).setBusy(false);
    }
  }

  Future<void> inactivate(int id) async {
    _ref.read(propertiesBusyProvider.notifier).setBusy(true);
    try {
      _ref.read(localPropertiesProvider.notifier).inactivate(id);
    } finally {
      _ref.read(propertiesBusyProvider.notifier).setBusy(false);
    }
  }

  Future<void> activate(int id) async {
    _ref.read(propertiesBusyProvider.notifier).setBusy(true);
    try {
      _ref.read(localPropertiesProvider.notifier).activate(id);
    } finally {
      _ref.read(propertiesBusyProvider.notifier).setBusy(false);
    }
  }

  Future<void> delete(int id) async {
    _ref.read(propertiesBusyProvider.notifier).setBusy(true);
    try {
      if (id > 0) {
        await _ref.read(propertiesRepositoryProvider).delete(id);
        _ref.read(localPropertiesProvider.notifier).remove(id);
        _ref.invalidate(propertiesProvider);
      } else {
        _ref.read(deletedPropertiesProvider.notifier).delete(id);
      }
    } finally {
      _ref.read(propertiesBusyProvider.notifier).setBusy(false);
    }
  }
}

class LocalPropertiesNotifier extends Notifier<Map<int, PropertySummaryModel>> {
  @override
  Map<int, PropertySummaryModel> build() => const {};

  void save(PropertySummaryModel property) {
    final id = property.id == 0 ? _nextLocalId() : property.id;
    state = {...state, id: property.copyWith(id: id)};
  }

  void remove(int id) {
    if (!state.containsKey(id)) return;
    final updated = {...state}..remove(id);
    state = updated;
  }

  void inactivate(int id) {
    final current = state[id] ?? _findRemoteProperty(id);
    if (current == null) return;
    state = {...state, id: current.copyWith(status: PropertyStatus.inactive)};
  }

  void activate(int id) {
    final current = state[id] ?? _findRemoteProperty(id);
    if (current == null) return;
    state = {...state, id: current.copyWith(status: PropertyStatus.active)};
  }

  int _nextLocalId() {
    final ids = state.keys.where((id) => id < 0);
    if (ids.isEmpty) return -1;
    return ids.reduce((a, b) => a < b ? a : b) - 1;
  }

  PropertySummaryModel? _findRemoteProperty(int id) {
    return ref.read(propertiesProvider).asData?.value.where((item) {
      return item.id == id;
    }).firstOrNull;
  }
}

class PropertiesBusyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setBusy(bool value) => state = value;
}

class DeletedPropertiesNotifier extends Notifier<Set<int>> {
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
