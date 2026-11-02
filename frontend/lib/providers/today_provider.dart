import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/api/animals_api.dart';
import 'package:cysvet_app/core/enums/property_status.dart';
import 'package:cysvet_app/local/animals_local_store.dart';
import 'package:cysvet_app/local/visits_local_store.dart';
import 'package:cysvet_app/models/animal_summary_model.dart';
import 'package:cysvet_app/models/property_summary_model.dart';
import 'package:cysvet_app/models/today_summary.dart';
import 'package:cysvet_app/providers/animals_provider.dart';
import 'package:cysvet_app/providers/auth_state.dart';
import 'package:cysvet_app/providers/offline_first.dart';
import 'package:cysvet_app/providers/properties_provider.dart';
import 'package:cysvet_app/providers/sync_provider.dart';

/// Uma fazenda na tela Hoje.
class TodayFarm {
  const TodayFarm({
    required this.property,
    required this.animals,
    required this.summary,
    this.lastVisit,
  });

  final PropertySummaryModel property;
  final List<AnimalSummaryModel> animals;
  final TodaySummary summary;
  final DateTime? lastVisit;
}

/// Fazendas ativas com o resumo do que fazer. No celular lê o banco do
/// aparelho (o sync mantém atualizado), então abre na hora e sem sinal; na web
/// busca no servidor.
final todayFarmsProvider = FutureProvider.autoDispose<List<TodayFarm>>((
  ref,
) async {
  final session = ref.watch(sessionKeyProvider);
  if (session == null) throw StateError('Sessão indisponível.');
  // Recarrega depois de cada sincronização.
  ref.watch(syncControllerProvider.select((state) => state.lastSyncedAt));

  final properties = (await ref.watch(propertiesProvider.future))
      .where((property) => property.status == PropertyStatus.active)
      .toList();
  final scope = ref.watch(offlineScopeProvider);

  List<AnimalSummaryModel> animals;
  final lastVisit = <int, DateTime>{};
  if (scope != null) {
    animals = await ref.read(animalsLocalStoreProvider).list(scope.companyId);
    if (animals.isEmpty) {
      // Primeiro uso no aparelho: ainda não há cache.
      animals = await fetchAnimalsWithLocalFallback(ref);
    }
    final visits = await ref
        .read(visitsLocalStoreProvider)
        .list(scope.companyId);
    for (final record in visits) {
      final date = record.visit.dataVisita;
      final property = record.visit.idPropriedade;
      if (date == null || property == 0) continue;
      final current = lastVisit[property];
      if (current == null || date.isAfter(current)) lastVisit[property] = date;
    }
  } else {
    animals = await ref.read(animalsRepositoryProvider).list();
  }

  final byProperty = <int, List<AnimalSummaryModel>>{};
  for (final animal in animals) {
    byProperty.putIfAbsent(animal.idPropriedade, () => []).add(animal);
  }

  final hoje = DateTime.now();
  final farms = [
    for (final property in properties)
      TodayFarm(
        property: property,
        animals: byProperty[property.id] ?? const [],
        summary: TodaySummary.build(byProperty[property.id] ?? const [], hoje),
        lastVisit: lastVisit[property.id],
      ),
  ];
  // Quem mais precisa de atenção primeiro; depois pelo nome.
  farms.sort((a, b) {
    final byAttention = b.summary.animalsNeedingAttention.compareTo(
      a.summary.animalsNeedingAttention,
    );
    return byAttention != 0
        ? byAttention
        : a.property.nome.toLowerCase().compareTo(b.property.nome.toLowerCase());
  });
  return farms;
});
