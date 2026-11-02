import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/local/sync_queue_store.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';
import 'package:cysvet_app/providers/auth_state.dart';
import 'package:cysvet_app/providers/offline_first.dart';

/// Histórico de IAs do animal usado pelo formulário (datas e total).
class VisitIaHistorySnapshot {
  const VisitIaHistorySnapshot({required this.dates, required this.totalIas});

  final List<DateTime> dates;
  final int totalIas;
}

/// Visita aberta no formulário e ainda não salva. Fica em memória enquanto o
/// usuário navega por outras telas e, no celular, também gravada no aparelho:
/// se o sistema fechar o app em segundo plano (ex.: o veterinário abriu outro
/// app), ela volta ao abrir de novo. É descartada ao salvar, ao cancelar ou ao
/// trocar de usuário/empresa.
class VisitInProgress {
  const VisitInProgress({
    required this.route,
    required this.propertyId,
    required this.dataVisita,
    required this.entries,
    required this.reviewedAnimalIds,
    this.propertyName,
    this.selectedAnimalId,
    this.editing,
    this.isEditingDraft = false,
    this.iaHistory = const {},
    this.newIdExterno,
  });

  factory VisitInProgress.fromJson(Map<String, dynamic> json) {
    final editing = json['editing'];
    final iaHistory = json['iaHistory'] as Map<String, dynamic>? ?? const {};
    return VisitInProgress(
      route: json['route'] as String,
      propertyId: json['propertyId'] as int?,
      propertyName: json['propertyName'] as String?,
      dataVisita: json['dataVisita'] as String? ?? '',
      entries: [
        for (final entry in json['entries'] as List? ?? const [])
          VisitAnimalEntryModelMapper.fromMap(
            Map<String, dynamic>.from(entry as Map),
          ),
      ],
      reviewedAnimalIds: {
        for (final id in json['reviewedAnimalIds'] as List? ?? const [])
          id as int,
      },
      selectedAnimalId: json['selectedAnimalId'] as int?,
      editing: editing == null
          ? null
          : VisitSummaryModelMapper.fromMap(
              Map<String, dynamic>.from(editing as Map),
            ),
      isEditingDraft: json['isEditingDraft'] as bool? ?? false,
      newIdExterno: json['newIdExterno'] as String?,
      iaHistory: {
        for (final item in iaHistory.entries)
          int.parse(item.key): VisitIaHistorySnapshot(
            dates: [
              for (final date in (item.value as Map)['dates'] as List)
                DateTime.parse(date as String),
            ],
            totalIas: (item.value as Map)['totalIas'] as int,
          ),
      },
    );
  }

  /// Rota para voltar ao formulário (`/visitas/nova` ou `/visitas/editar/x`).
  final String route;
  final int? propertyId;
  final String? propertyName;

  /// Data como digitada no campo (DD/MM/AAAA).
  final String dataVisita;
  final List<VisitAnimalEntryModel> entries;
  final Set<int> reviewedAnimalIds;
  final int? selectedAnimalId;

  /// Visita salva no aparelho sendo continuada/editada, se houver.
  final VisitSummaryModel? editing;
  final bool isEditingDraft;

  /// `idExterno` reservado para a visita nova ao abrir o formulário: salvar
  /// de novo depois de uma falha atualiza a mesma visita em vez de duplicar.
  final String? newIdExterno;

  /// Histórico de IAs por animal, para não recalcular ao voltar.
  final Map<int, VisitIaHistorySnapshot> iaHistory;

  int get collectedCount => reviewedAnimalIds.length;

  Map<String, dynamic> toJson() => {
    'route': route,
    'propertyId': propertyId,
    'propertyName': propertyName,
    'dataVisita': dataVisita,
    'entries': [for (final entry in entries) entry.toMap()],
    'reviewedAnimalIds': reviewedAnimalIds.toList(),
    'selectedAnimalId': selectedAnimalId,
    'editing': editing?.toMap(),
    'isEditingDraft': isEditingDraft,
    'newIdExterno': newIdExterno,
    'iaHistory': {
      for (final item in iaHistory.entries)
        '${item.key}': {
          'dates': [
            for (final date in item.value.dates) date.toIso8601String(),
          ],
          'totalIas': item.value.totalIas,
        },
    },
  };
}

final visitInProgressProvider =
    NotifierProvider<VisitInProgressNotifier, VisitInProgress?>(
      VisitInProgressNotifier.new,
    );

class VisitInProgressNotifier extends Notifier<VisitInProgress?> {
  static const _writeDelay = Duration(milliseconds: 600);

  Timer? _pendingWrite;
  String? _storageKey;
  SyncQueueStore? _store;

  // Cópia do estado para gravar no descarte do provider, onde ler `state`
  // não é permitido.
  VisitInProgress? _latest;

  @override
  VisitInProgress? build() {
    // Só usuário e empresa: a renovação do token não descarta a visita.
    ref.watch(
      authSessionProvider.select(
        (session) => (session?.user.id, session?.activeCompanyId),
      ),
    );
    final scope = ref.watch(offlineScopeProvider);
    _storageKey = scope == null
        ? null
        : 'visit_in_progress.${scope.companyId}.${scope.userId}';
    _store = scope == null ? null : ref.read(syncQueueStoreProvider);

    // O Android pode fechar o app logo depois de ir para segundo plano.
    final lifecycle = AppLifecycleListener(
      onHide: _flush,
      onPause: _flush,
      onDetach: _flush,
    );
    ref.onDispose(() {
      _flush();
      lifecycle.dispose();
    });

    if (_storageKey != null) unawaited(_load());
    return null;
  }

  void remember(VisitInProgress visit) {
    state = visit;
    _latest = visit;
    _pendingWrite?.cancel();
    _pendingWrite = Timer(_writeDelay, _flush);
  }

  void clear() {
    state = null;
    _latest = null;
    _pendingWrite?.cancel();
    _pendingWrite = null;
    unawaited(_write(null));
  }

  Future<void> _load() async {
    final key = _storageKey;
    final store = _store;
    if (key == null || store == null) return;
    try {
      final raw = await store.readMeta(key);
      // Algo aberto nesta sessão é mais novo que o que estava gravado.
      if (raw == null || raw.isEmpty || !ref.mounted || state != null) return;
      state = _latest = VisitInProgress.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (error) {
      debugPrint('Visita em andamento ilegível, descartada: $error');
    }
  }

  void _flush() {
    if (_pendingWrite == null) return;
    _pendingWrite!.cancel();
    _pendingWrite = null;
    unawaited(_write(_latest));
  }

  Future<void> _write(VisitInProgress? visit) async {
    final key = _storageKey;
    final store = _store;
    if (key == null || store == null) return;
    try {
      await store.writeMeta(
        key,
        visit == null ? null : jsonEncode(visit.toJson()),
      );
    } catch (error) {
      debugPrint('Falha ao gravar a visita em andamento: $error');
    }
  }
}
