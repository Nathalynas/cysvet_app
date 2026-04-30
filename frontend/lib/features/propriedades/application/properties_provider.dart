import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_state.dart';
import '../data/properties_repository.dart';
import '../domain/property_summary.dart';

final propertiesProvider = FutureProvider<List<PropertySummary>>((ref) async {
  final session = ref.watch(authSessionProvider);

  if (session == null) {
    throw StateError('Sessao indisponivel.');
  }

  return ref.watch(propertiesRepositoryProvider).list();
});
