import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final visitsSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

final visitsPropertyFilterProvider =
    NotifierProvider<VisitsPropertyFilterNotifier, int?>(
      VisitsPropertyFilterNotifier.new,
    );

class VisitsPropertyFilterNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? value) {
    state = value;
  }
}
