import 'package:flutter_riverpod/legacy.dart';

import '../core/enums/user_status.dart';

final usersSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final usersStatusFilterProvider = StateProvider.autoDispose<UserStatusFilter>((
  ref,
) {
  return UserStatusFilter.active;
});
