import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/user_status.dart';
import '../../auth/application/auth_state.dart';
import '../data/users_repository.dart';
import '../domain/user_summary_model.dart';

final usersBusyProvider = NotifierProvider<UsersBusyNotifier, bool>(
  UsersBusyNotifier.new,
);

final usersControllerProvider = Provider<UsersController>((ref) {
  return UsersController(ref);
});

final usersProvider = FutureProvider<List<UserSummaryModel>>((ref) async {
  final session = ref.watch(authSessionProvider);

  if (session == null) {
    throw StateError('Sessao indisponivel.');
  }

  final items = await ref.watch(usersRepositoryProvider).list();
  items.sort((a, b) => a.name.compareTo(b.name));
  return items;
});

class UsersController {
  const UsersController(this._ref);

  final Ref _ref;

  Future<void> save(UserSummaryModel user, {required String password}) async {
    _ref.read(usersBusyProvider.notifier).setBusy(true);
    try {
      await _ref
          .read(usersRepositoryProvider)
          .create(user: user, password: password);
      _ref.invalidate(usersProvider);
    } finally {
      _ref.read(usersBusyProvider.notifier).setBusy(false);
    }
  }

  Future<void> update(UserSummaryModel user) async {
    _ref.read(usersBusyProvider.notifier).setBusy(true);
    try {
      await _ref.read(usersRepositoryProvider).update(user);
      _ref.invalidate(usersProvider);
    } finally {
      _ref.read(usersBusyProvider.notifier).setBusy(false);
    }
  }

  Future<void> inactivate(int id) async {
    _ref.read(usersBusyProvider.notifier).setBusy(true);
    try {
      await _ref
          .read(usersRepositoryProvider)
          .updateStatus(id: id, status: UserStatus.inactive);
      _ref.invalidate(usersProvider);
    } finally {
      _ref.read(usersBusyProvider.notifier).setBusy(false);
    }
  }

  Future<void> activate(int id) async {
    _ref.read(usersBusyProvider.notifier).setBusy(true);
    try {
      await _ref
          .read(usersRepositoryProvider)
          .updateStatus(id: id, status: UserStatus.active);
      _ref.invalidate(usersProvider);
    } finally {
      _ref.read(usersBusyProvider.notifier).setBusy(false);
    }
  }

  Future<void> delete(int id) async {
    _ref.read(usersBusyProvider.notifier).setBusy(true);
    try {
      await _ref.read(usersRepositoryProvider).delete(id);
      _ref.invalidate(usersProvider);
    } finally {
      _ref.read(usersBusyProvider.notifier).setBusy(false);
    }
  }
}

class UsersBusyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setBusy(bool value) => state = value;
}
