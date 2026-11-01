import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/api/account_api.dart';
import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/core/network/api_error.dart';
import 'package:cysvet_app/local/sync_queue_store.dart';
import 'package:cysvet_app/providers/auth_state.dart';
import 'package:cysvet_app/providers/offline_first.dart';

/// Atalhos padrão quando o veterinário não escolheu os seus.
const defaultReproductiveShortcuts = [
  AnimalReproductiveStatus.pregnant,
  AnimalReproductiveStatus.empty,
  AnimalReproductiveStatus.inseminated,
  AnimalReproductiveStatus.waitingDiagnosis,
];

const maxReproductiveShortcuts = 8;

/// Situações que podem virar atalho ("Seca" é situação produtiva).
final reproductiveShortcutOptions = AnimalReproductiveStatus.editableValues
    .where((status) => status != AnimalReproductiveStatus.dry)
    .toList(growable: false);

final reproductiveShortcutsProvider =
    AsyncNotifierProvider<
      ReproductiveShortcutsNotifier,
      List<AnimalReproductiveStatus>
    >(ReproductiveShortcutsNotifier.new);

/// Atalhos de situação reprodutiva da visita, guardados por usuário no
/// servidor. No celular ficam também no aparelho: sem sinal, a visita usa a
/// cópia local e uma troca feita offline é enviada na próxima vez que houver
/// conexão.
class ReproductiveShortcutsNotifier
    extends AsyncNotifier<List<AnimalReproductiveStatus>> {
  @override
  Future<List<AnimalReproductiveStatus>> build() async {
    final userId = ref.watch(
      authSessionProvider.select((session) => session?.user.id),
    );
    if (userId == null) return defaultReproductiveShortcuts;

    final cached = await _readCache();
    final repository = ref.read(accountRepositoryProvider);
    try {
      final values = cached != null && cached.pending
          ? await repository.saveReproductiveShortcuts(cached.values)
          : await repository.reproductiveShortcuts();
      await _writeCache(values, pending: false);
      return _parse(values);
    } catch (error) {
      if (!isNetworkError(error)) rethrow;
      return cached == null
          ? defaultReproductiveShortcuts
          : _parse(cached.values);
    }
  }

  /// Salva os atalhos escolhidos; `null` volta ao padrão. Retorna `false`
  /// quando ficou só no aparelho, para enviar quando houver conexão.
  Future<bool> save(List<AnimalReproductiveStatus>? shortcuts) async {
    final values = shortcuts?.map((status) => status.apiValue).toList();
    state = AsyncData(shortcuts ?? defaultReproductiveShortcuts);
    await _writeCache(values, pending: true);
    try {
      final saved = await ref
          .read(accountRepositoryProvider)
          .saveReproductiveShortcuts(values);
      await _writeCache(saved, pending: false);
      state = AsyncData(_parse(saved));
      return true;
    } catch (error) {
      if (!isNetworkError(error) || _store == null) rethrow;
      return false;
    }
  }

  // Nulo: volta ao padrão (pendente de envio quando escolhido offline).
  static List<AnimalReproductiveStatus> _parse(List<String>? values) {
    if (values == null) return defaultReproductiveShortcuts;
    final parsed = [
      for (final value in values) AnimalReproductiveStatus.fromApiValue(value),
    ].where(reproductiveShortcutOptions.contains).toSet().toList();
    return parsed.isEmpty ? defaultReproductiveShortcuts : parsed;
  }

  SyncQueueStore? get _store => ref.read(offlineScopeProvider) == null
      ? null
      : ref.read(syncQueueStoreProvider);

  String? get _cacheKey {
    final scope = ref.read(offlineScopeProvider);
    return scope == null ? null : 'reproductive_shortcuts.${scope.userId}';
  }

  Future<({List<String>? values, bool pending})?> _readCache() async {
    final store = _store;
    final key = _cacheKey;
    if (store == null || key == null) return null;
    final raw = await store.readMeta(key);
    if (raw == null || raw.isEmpty) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final values = json['values'] as List?;
    return (
      values: values?.map((value) => value.toString()).toList(),
      pending: json['pending'] as bool? ?? false,
    );
  }

  Future<void> _writeCache(
    List<String>? values, {
    required bool pending,
  }) async {
    final store = _store;
    final key = _cacheKey;
    if (store == null || key == null) return;
    await store.writeMeta(
      key,
      jsonEncode({'values': values, 'pending': pending}),
    );
  }
}
