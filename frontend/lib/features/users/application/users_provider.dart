import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/user_status.dart';
import '../../auth/application/auth_state.dart';
import '../domain/user_summary_model.dart';

final usersBusyProvider = NotifierProvider<UsersBusyNotifier, bool>(
  UsersBusyNotifier.new,
);

final usersControllerProvider = Provider<UsersController>((ref) {
  return UsersController(ref);
});

final localUsersProvider =
    NotifierProvider<LocalUsersNotifier, Map<int, UserSummaryModel>>(
      LocalUsersNotifier.new,
    );

final usersProvider = FutureProvider<List<UserSummaryModel>>((ref) async {
  final session = ref.watch(authSessionProvider);
  final localItems = ref.watch(localUsersProvider);

  if (session == null) {
    throw StateError('Sessão indisponível.');
  }

  final items = localItems.values.toList();
  items.sort((a, b) => a.name.compareTo(b.name));
  return items;
});

class UsersController {
  const UsersController(this._ref);

  final Ref _ref;

  Future<void> save(UserSummaryModel user) async {
    _ref.read(usersBusyProvider.notifier).setBusy(true);
    try {
      _ref.read(localUsersProvider.notifier).save(user);
    } finally {
      _ref.read(usersBusyProvider.notifier).setBusy(false);
    }
  }

  Future<void> inactivate(int id) async {
    _ref.read(usersBusyProvider.notifier).setBusy(true);
    try {
      _ref.read(localUsersProvider.notifier).inactivate(id);
    } finally {
      _ref.read(usersBusyProvider.notifier).setBusy(false);
    }
  }

  Future<void> activate(int id) async {
    _ref.read(usersBusyProvider.notifier).setBusy(true);
    try {
      _ref.read(localUsersProvider.notifier).activate(id);
    } finally {
      _ref.read(usersBusyProvider.notifier).setBusy(false);
    }
  }

  Future<void> delete(int id) async {
    _ref.read(usersBusyProvider.notifier).setBusy(true);
    try {
      _ref.read(localUsersProvider.notifier).remove(id);
    } finally {
      _ref.read(usersBusyProvider.notifier).setBusy(false);
    }
  }
}

class LocalUsersNotifier extends Notifier<Map<int, UserSummaryModel>> {
  @override
  Map<int, UserSummaryModel> build() => const {};

  void save(UserSummaryModel user) {
    final id = user.id == 0 ? _nextLocalId() : user.id;
    state = {...state, id: user.copyWith(id: id)};
  }

  void remove(int id) {
    if (!state.containsKey(id)) return;
    final updated = {...state}..remove(id);
    state = updated;
  }

  void inactivate(int id) {
    final current = state[id];
    if (current == null) return;
    state = {...state, id: current.copyWith(status: UserStatus.inactive)};
  }

  void activate(int id) {
    final current = state[id];
    if (current == null) return;
    state = {...state, id: current.copyWith(status: UserStatus.active)};
  }

  int _nextLocalId() {
    final ids = state.keys.where((id) => id < 0);
    if (ids.isEmpty) return -1;
    return ids.reduce((a, b) => a < b ? a : b) - 1;
  }
}

class UsersBusyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setBusy(bool value) => state = value;
}
