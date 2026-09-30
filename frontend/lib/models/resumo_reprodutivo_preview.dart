import 'package:cysvet_app/core/enums/animal_status.dart';
import 'package:cysvet_app/models/animal_summary_model.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';

/// Prévia do resumo reprodutivo do animal depois de uma visita salva no
/// aparelho, usada enquanto a visita não sincroniza.
///
/// O resumo oficial é recalculado no servidor a partir dos eventos gerados
/// pela visita (`ResumoReprodutivoAnimalService`) e chega pelo pull,
/// substituindo esta prévia. Aqui só se aplicam as mesmas regras de parto,
/// última IA, secagem e situação observada, sem considerar outras visitas
/// pendentes. A secagem muda só a situação produtiva: a vaca seca continua
/// prenha.
AnimalSummaryModel previewAnimalAfterVisit(
  AnimalSummaryModel animal,
  VisitAnimalEntryModel entry,
) {
  var lactacoes = animal.numeroLactacao;
  var ultimoParto = animal.dataUltimoParto;
  var ultimaIa = animal.dataInseminacao;
  var status = animal.statusReprodutivo;
  var produtiva = animal.situacaoProdutiva;

  final parto = entry.dataUltimoParto;
  if (parto != null && (ultimoParto == null || parto.isAfter(ultimoParto))) {
    lactacoes++;
    ultimoParto = parto;
    status = AnimalReproductiveStatus.pending;
    produtiva = AnimalProductiveSituation.lactating;
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

  if (entry.dataSecagemEfetiva != null) {
    produtiva = AnimalProductiveSituation.dry;
  }

  final observado = _statusObservado(entry.situacaoReprodutiva);
  if (observado == AnimalReproductiveStatus.dry) {
    // "Seca" na coluna reprodutiva é a situação produtiva.
    produtiva = AnimalProductiveSituation.dry;
  } else if (observado != null) {
    status = observado;
  }
  produtiva = _situacaoProdutivaObservada(entry.situacaoProdutiva) ?? produtiva;

  return animal.copyWith(
    numeroLactacao: lactacoes,
    dataUltimoParto: ultimoParto,
    dataInseminacao: ultimaIa,
    statusReprodutivo: status,
    situacaoProdutiva: produtiva,
  );
}

String? _situacaoProdutivaObservada(String? value) {
  final normalized = value?.trim().toLowerCase().replaceAll('-', ' ');
  if (normalized == null || normalized.isEmpty) return null;
  for (final situacao in AnimalProductiveSituation.values) {
    if (situacao == normalized) return situacao;
  }
  return null;
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
