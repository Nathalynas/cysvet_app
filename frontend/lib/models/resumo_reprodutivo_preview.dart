import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/models/animal_summary_model.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';

/// Prévia do resumo reprodutivo do animal depois de uma visita salva no
/// aparelho, usada enquanto a visita não sincroniza.
///
/// O resumo oficial é recalculado no servidor a partir dos eventos gerados
/// pela visita (`ResumoReprodutivoAnimalService`) e chega pelo pull,
/// substituindo esta prévia. Aqui só se aplicam as mesmas regras de parto,
/// última IA e situação observada, sem considerar outras visitas pendentes.
AnimalSummaryModel previewAnimalAfterVisit(
  AnimalSummaryModel animal,
  VisitAnimalEntryModel entry,
) {
  var lactacoes = animal.numeroLactacao;
  var ultimoParto = animal.dataUltimoParto;
  var ultimaIa = animal.dataInseminacao;
  var status = animal.statusReprodutivo;

  final parto = entry.dataUltimoParto;
  if (parto != null && (ultimoParto == null || parto.isAfter(ultimoParto))) {
    lactacoes++;
    ultimoParto = parto;
    status = AnimalReproductiveStatus.pending;
  }

  final ia = entry.dataUltimaIa;
  if (ia != null && (ultimaIa == null || !ia.isBefore(ultimaIa))) {
    ultimaIa = ia;
    status = AnimalReproductiveStatus.inseminated;
  }

  // A IA anterior ao último parto pertence à lactação passada.
  if (ultimaIa != null &&
      ultimoParto != null &&
      !ultimaIa.isAfter(ultimoParto)) {
    ultimaIa = null;
  }

  status = _statusObservado(entry.situacaoReprodutiva) ?? status;

  return animal.copyWith(
    numeroLactacao: lactacoes,
    dataUltimoParto: ultimoParto,
    dataInseminacao: ultimaIa,
    statusReprodutivo: status,
  );
}

AnimalReproductiveStatus? _statusObservado(String? value) {
  final normalized = value?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return null;

  for (final status in AnimalReproductiveStatus.values) {
    if (status.apiValue == normalized ||
        status.aliases.any((alias) => alias.toLowerCase() == normalized)) {
      return status;
    }
  }
  return null;
}
