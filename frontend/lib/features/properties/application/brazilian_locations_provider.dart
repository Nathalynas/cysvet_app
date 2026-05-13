// ignore_for_file: implementation_imports

import 'package:brazilian_locations/src/services/cache_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final brazilianLocationsProvider = FutureProvider<BrazilianLocationsData>((
  ref,
) async {
  final service = CacheService();
  await service.initializeHive();
  await service.loadData();

  final citiesByState = <String, Set<String>>{};
  for (final location in service.getCachedData()) {
    citiesByState.putIfAbsent(location.state, () => {}).add(location.city);
  }

  final states = citiesByState.keys.toList()..sort();
  final mappedCities = {
    for (final entry in citiesByState.entries)
      entry.key: (entry.value.toList()..sort()),
  };

  return BrazilianLocationsData(states: states, citiesByState: mappedCities);
});

class BrazilianLocationsData {
  const BrazilianLocationsData({
    required this.states,
    required this.citiesByState,
  });

  final List<String> states;
  final Map<String, List<String>> citiesByState;

  List<String> citiesFor(String? state) {
    if (state == null || state.isEmpty) return const [];
    return citiesByState[state] ?? const [];
  }
}
