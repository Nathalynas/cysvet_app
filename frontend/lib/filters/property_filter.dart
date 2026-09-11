import 'package:flutter_riverpod/legacy.dart';

import '../core/enums/property_status.dart';

final propertiesSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

final propertiesStatusFilterProvider =
    StateProvider.autoDispose<PropertyStatusFilter>((ref) {
      return PropertyStatusFilter.active;
    });
