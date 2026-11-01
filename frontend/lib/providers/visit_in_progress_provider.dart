import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/models/visit_summary_model.dart';
import 'package:cysvet_app/providers/auth_state.dart';

/// Visita aberta no formulário e ainda não salva. Fica em memória enquanto o
/// usuário navega por outras telas, para ele poder voltar a ela do ponto onde
/// parou. É descartada ao salvar, ao cancelar ou ao trocar de usuário/empresa.
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
    this.extras,
  });

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

  /// Dados derivados que o formulário guarda para não recalcular ao voltar.
  final Object? extras;

  int get collectedCount => reviewedAnimalIds.length;
}

final visitInProgressProvider =
    NotifierProvider<VisitInProgressNotifier, VisitInProgress?>(
      VisitInProgressNotifier.new,
    );

class VisitInProgressNotifier extends Notifier<VisitInProgress?> {
  @override
  VisitInProgress? build() {
    // Só usuário e empresa: a renovação do token não descarta a visita.
    ref.watch(
      authSessionProvider.select(
        (session) => (session?.user.id, session?.activeCompanyId),
      ),
    );
    return null;
  }

  void remember(VisitInProgress visit) => state = visit;

  void clear() => state = null;
}
