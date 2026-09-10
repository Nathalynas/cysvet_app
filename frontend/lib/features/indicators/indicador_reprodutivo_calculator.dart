import '../../core/constants/app_constants.dart';
import '../../core/enums/animal_status.dart';
import '../animals/domain/animal_summary_model.dart';
import '../visits/domain/visit_summary_model.dart';

class IndicadorReprodutivoCalculator {
  const IndicadorReprodutivoCalculator._();

  static VisitAnimalEntryModel applyAutomaticCalculations({
    required VisitAnimalEntryModel entry,
    required DateTime? dataAtual,
  }) {
    final situacaoProdutiva = _normalize(entry.situacaoProdutiva);
    final situacaoReprodutiva = _normalize(entry.situacaoReprodutiva);
    final intervalo1e2Ia = _diasEntre(
      entry.dataPrimeiraIa,
      entry.dataSegundaIa,
    );
    final intervalo2e3Ia = _diasEntre(
      entry.dataSegundaIa,
      entry.dataTerceiraIa,
    );
    final intervalo3e4Ia = _diasEntre(entry.dataTerceiraIa, entry.dataQuartaIa);
    final intervalo4e5Ia = _diasEntre(entry.dataQuartaIa, entry.dataQuintaIa);
    final diasPrenhez = _diasPrenhez(
      situacaoProdutiva: situacaoProdutiva,
      situacaoReprodutiva: situacaoReprodutiva,
      dataUltimaIa: entry.dataUltimaIa,
      dataAtual: dataAtual,
    );
    final previsaoSecagem = _previsaoSecagem(
      situacaoProdutiva: situacaoProdutiva,
      situacaoReprodutiva: situacaoReprodutiva,
      dataUltimaIa: entry.dataUltimaIa,
    );
    final dataPreParto = _dataPreParto(
      situacaoReprodutiva: situacaoReprodutiva,
      dataUltimaIa: entry.dataUltimaIa,
    );
    final previsaoParto = _previsaoParto(
      situacaoReprodutiva: situacaoReprodutiva,
      dataUltimaIa: entry.dataUltimaIa,
    );

    return entry.copyWith(
      idadeMeses: _monthsBetween(entry.dataNascimento, dataAtual),
      del: _del(
        situacaoProdutiva: situacaoProdutiva,
        dataUltimoParto: entry.dataUltimoParto,
      ),
      idadePrimeiroPartoMeses: _monthsBetween(
        entry.dataNascimento,
        entry.dataPrimeiroParto,
      ),
      idadePrimeiraIa: _idadePrimeiraIa(
        situacaoProdutiva: situacaoProdutiva,
        dataNascimento: entry.dataNascimento,
        dataPrimeiraIa: entry.dataPrimeiraIa,
      ),
      mesParto: _mesParto(entry.numeroPartos, entry.dataUltimoParto),
      anoUltimoParto: entry.dataUltimoParto?.year,
      iepAtual: _iepAtual(
        numeroPartos: entry.numeroPartos,
        dataPartoAnterior: entry.dataPartoAnterior,
        dataUltimoParto: entry.dataUltimoParto,
      ),
      classificacaoPartos: _classificacaoPartos(entry.numeroPartos),
      vacaApta: _vacaApta(situacaoReprodutiva),
      intervalo1e2Ia: intervalo1e2Ia,
      intervalo2e3Ia: intervalo2e3Ia,
      intervalo3e4Ia: intervalo3e4Ia,
      intervalo4e5Ia: intervalo4e5Ia,
      mediaIntervaloIa: _mediaIntervaloIa(
        numeroIaRecebida: entry.numeroIaRecebida,
        situacaoReprodutiva: situacaoReprodutiva,
        intervalos: [
          intervalo1e2Ia,
          intervalo2e3Ia,
          intervalo3e4Ia,
          intervalo4e5Ia,
        ],
      ),
      previsaoRetornoCio: _previsaoRetornoCio(
        situacaoReprodutiva: situacaoReprodutiva,
        dataUltimaIa: entry.dataUltimaIa,
      ),
      diasPrenhez: diasPrenhez,
      delPrimeiraIa: _delPrimeiraIa(
        situacaoProdutiva: situacaoProdutiva,
        situacaoReprodutiva: situacaoReprodutiva,
        dataUltimoParto: entry.dataUltimoParto,
        dataPrimeiraIa: entry.dataPrimeiraIa,
      ),
      periodoServico: _periodoServico(
        situacaoProdutiva: situacaoProdutiva,
        situacaoReprodutiva: situacaoReprodutiva,
        dataUltimoParto: entry.dataUltimoParto,
        dataUltimaIa: entry.dataUltimaIa,
        diasPrenhez: diasPrenhez,
      ),
      diasParaSecar: _diasParaSecar(
        situacaoProdutiva: situacaoProdutiva,
        situacaoReprodutiva: situacaoReprodutiva,
        diasPrenhez: diasPrenhez,
      ),
      previsaoSecagem: previsaoSecagem,
      mesSecagem: _nomeDoMes(previsaoSecagem),
      diferencaSecagem: _diasEntre(previsaoSecagem, entry.dataSecagemEfetiva),
      periodoLactacao: _periodoLactacao(
        situacaoProdutiva: situacaoProdutiva,
        dataSecagemEfetiva: entry.dataSecagemEfetiva,
        dataUltimoParto: entry.dataUltimoParto,
      ),
      dataPreParto: dataPreParto,
      mesPreParto: _nomeDoMes(dataPreParto),
      duracaoPreParto: _duracaoPreParto(
        situacaoProdutiva: situacaoProdutiva,
        entradaPreParto: entry.entradaPreParto,
        dataUltimoParto: entry.dataUltimoParto,
      ),
      previsaoParto: previsaoParto,
      mesPrevistoParto: _nomeDoMes(previsaoParto),
      iepProjetado: _iepProjetado(
        situacaoProdutiva: situacaoProdutiva,
        situacaoReprodutiva: situacaoReprodutiva,
        previsaoParto: previsaoParto,
        dataUltimoParto: entry.dataUltimoParto,
      ),
      controleLeiteiroComDesconto: _controleLeiteiroComDesconto(
        situacaoProdutiva: situacaoProdutiva,
        controleLeiteiro: entry.controleLeiteiro,
      ),
    );
  }

  static AnimalReproductiveStatus resolveAnimalStatus(
    AnimalSummaryModel animal, {
    Iterable<String?> extraTexts = const [],
  }) {
    return _resolveStatus(
      savedStatus: animal.statusReprodutivo,
      dataInseminacao: animal.dataInseminacao,
      texts: [animal.historicoReprodutivo, ...extraTexts],
    );
  }

  static AnimalReproductiveStatus resolveStatusFromTexts({
    AnimalReproductiveStatus? savedStatus,
    DateTime? dataInseminacao,
    Iterable<String?> texts = const [],
  }) {
    return _resolveStatus(
      savedStatus: savedStatus,
      dataInseminacao: dataInseminacao,
      texts: texts,
    );
  }

  static Map<AnimalReproductiveStatus, int> countAnimalStatuses(
    Iterable<AnimalSummaryModel> animals,
  ) {
    final counts = {
      for (final status in AnimalReproductiveStatus.editableValues) status: 0,
    };

    for (final animal in animals) {
      final status = resolveAnimalStatus(animal);
      counts[status] = (counts[status] ?? 0) + 1;
    }

    return counts;
  }

  static double? pregnancyRateFromAnimals(
    Iterable<AnimalSummaryModel> animals,
  ) {
    final counts = countAnimalStatuses(animals);
    final knownStatusCount = counts.entries
        .where((entry) => entry.key != AnimalReproductiveStatus.pending)
        .fold<int>(0, (total, entry) => total + entry.value);
    if (knownStatusCount == 0) return null;

    return (counts[AnimalReproductiveStatus.pregnant] ?? 0) / knownStatusCount;
  }

  static double? pregnancyRateFromStatuses(
    Iterable<AnimalReproductiveStatus> statuses,
  ) {
    final known = statuses
        .where((status) {
          return status == AnimalReproductiveStatus.pregnant ||
              status == AnimalReproductiveStatus.empty;
        })
        .toList(growable: false);
    if (known.isEmpty) return null;

    final pregnant = known.where((status) {
      return status == AnimalReproductiveStatus.pregnant;
    }).length;
    return pregnant / known.length;
  }

  static double? iaConceptionRateFromEntries(
    Iterable<VisitAnimalEntryModel> entries,
  ) {
    final withIa = entries
        .where((entry) {
          return entry.dataUltimaIa != null ||
              (entry.numeroIaRecebida ?? 0) > 0;
        })
        .toList(growable: false);
    if (withIa.isEmpty) return null;

    final positive = withIa.where((entry) {
      return hasPositivePregnancyText([
        entry.situacaoReprodutiva,
        entry.diagnostico,
        entry.decisao,
      ]);
    }).length;
    return positive / withIa.length;
  }

  static bool hasPositivePregnancyText(Iterable<String?> texts) {
    final normalized = texts.map(_normalize).whereType<String>().join(' ');
    return normalized.contains('pren') || normalized.contains('positiv');
  }

  static AnimalReproductiveStatus _resolveStatus({
    required AnimalReproductiveStatus? savedStatus,
    required DateTime? dataInseminacao,
    required Iterable<String?> texts,
  }) {
    if (savedStatus != null) {
      return savedStatus;
    }

    if (dataInseminacao != null) {
      return AnimalReproductiveStatus.inseminated;
    }

    final normalized = texts.map(_normalize).whereType<String>().join(' ');

    if (normalized.contains('pren') || normalized.contains('confirm')) {
      return AnimalReproductiveStatus.pregnant;
    }
    if (normalized.contains('insemin')) {
      return AnimalReproductiveStatus.inseminated;
    }
    if (normalized.contains('seca') || normalized.contains('dry')) {
      return AnimalReproductiveStatus.dry;
    }
    if (normalized.contains('vazia') ||
        normalized.contains('empty') ||
        normalized.contains('negativ') ||
        normalized.contains('toque')) {
      return AnimalReproductiveStatus.empty;
    }

    return AnimalReproductiveStatus.pending;
  }

  static int? _del({
    required String? situacaoProdutiva,
    required DateTime? dataUltimoParto,
  }) {
    if (situacaoProdutiva != AnimalProductiveSituation.lactating) {
      return null;
    }

    return _diasEntre(dataUltimoParto, DateTime.now());
  }

  static double? _idadePrimeiraIa({
    required String? situacaoProdutiva,
    required DateTime? dataNascimento,
    required DateTime? dataPrimeiraIa,
  }) {
    if (situacaoProdutiva != AnimalProductiveSituation.heifer) {
      return null;
    }

    return _monthsBetween(dataNascimento, dataPrimeiraIa);
  }

  static String? _mesParto(int? numeroPartos, DateTime? dataUltimoParto) {
    if (numeroPartos == null || numeroPartos < 1) {
      return null;
    }

    return _nomeDoMes(dataUltimoParto);
  }

  static double? _iepAtual({
    required int? numeroPartos,
    required DateTime? dataPartoAnterior,
    required DateTime? dataUltimoParto,
  }) {
    if (numeroPartos == null || numeroPartos < 2) {
      return null;
    }

    return _monthsBetween(dataPartoAnterior, dataUltimoParto);
  }

  static String? _classificacaoPartos(int? numeroPartos) {
    if (numeroPartos == 1) {
      return 'Primipara';
    }
    if (numeroPartos != null && numeroPartos >= 2) {
      return 'Multipara';
    }
    return null;
  }

  static bool? _vacaApta(String? situacaoReprodutiva) {
    const fitStatuses = {
      AnimalReproductiveStatus.protocol,
      AnimalReproductiveStatus.empty,
      AnimalReproductiveStatus.released,
      AnimalReproductiveStatus.delayed,
      AnimalReproductiveStatus.waitingDiagnosis,
      AnimalReproductiveStatus.inseminatedSt,
    };
    const unfitStatuses = {
      AnimalReproductiveStatus.pregnant,
      AnimalReproductiveStatus.induction,
      AnimalReproductiveStatus.discard,
      AnimalReproductiveStatus.pev,
      AnimalReproductiveStatus.noAge,
      AnimalReproductiveStatus.calf,
    };

    if (_isAnyReproductiveStatus(situacaoReprodutiva, fitStatuses)) {
      return true;
    }
    if (_isAnyReproductiveStatus(situacaoReprodutiva, unfitStatuses)) {
      return false;
    }
    return null;
  }

  static double? _mediaIntervaloIa({
    required int? numeroIaRecebida,
    required String? situacaoReprodutiva,
    required Iterable<int?> intervalos,
  }) {
    const excludedStatuses = {
      AnimalReproductiveStatus.pev,
      AnimalReproductiveStatus.induction,
      AnimalReproductiveStatus.noAge,
      AnimalReproductiveStatus.discard,
    };
    if (numeroIaRecebida == null ||
        numeroIaRecebida < 2 ||
        _isAnyReproductiveStatus(situacaoReprodutiva, excludedStatuses)) {
      return null;
    }

    return _media(intervalos);
  }

  static DateTime? _previsaoRetornoCio({
    required String? situacaoReprodutiva,
    required DateTime? dataUltimaIa,
  }) {
    const excludedStatuses = {
      AnimalReproductiveStatus.pregnant,
      AnimalReproductiveStatus.pev,
      AnimalReproductiveStatus.induction,
      AnimalReproductiveStatus.discard,
      AnimalReproductiveStatus.noAge,
      AnimalReproductiveStatus.calf,
      AnimalReproductiveStatus.released,
      AnimalReproductiveStatus.delayed,
    };
    if (_isAnyReproductiveStatus(situacaoReprodutiva, excludedStatuses)) {
      return null;
    }

    return _adicionarDias(dataUltimaIa, 21);
  }

  static int? _diasPrenhez({
    required String? situacaoProdutiva,
    required String? situacaoReprodutiva,
    required DateTime? dataUltimaIa,
    required DateTime? dataAtual,
  }) {
    const excludedReproductiveStatuses = {
      AnimalReproductiveStatus.empty,
      AnimalReproductiveStatus.induction,
      AnimalReproductiveStatus.discard,
      AnimalReproductiveStatus.pev,
      AnimalReproductiveStatus.noAge,
      AnimalReproductiveStatus.delayed,
      AnimalReproductiveStatus.released,
    };

    if (situacaoProdutiva == AnimalProductiveSituation.heifer ||
        _isAnyReproductiveStatus(
          situacaoReprodutiva,
          excludedReproductiveStatuses,
        )) {
      return null;
    }

    return _diasEntre(dataUltimaIa, dataAtual);
  }

  static int? _delPrimeiraIa({
    required String? situacaoProdutiva,
    required String? situacaoReprodutiva,
    required DateTime? dataUltimoParto,
    required DateTime? dataPrimeiraIa,
  }) {
    const excludedReproductiveStatuses = {
      AnimalReproductiveStatus.induction,
      AnimalReproductiveStatus.discard,
      AnimalReproductiveStatus.pev,
      AnimalReproductiveStatus.noAge,
      AnimalReproductiveStatus.delayed,
      AnimalReproductiveStatus.released,
    };
    const excludedProductiveStatuses = {
      AnimalProductiveSituation.heifer,
      AnimalProductiveSituation.prepartum,
    };
    if (_isAnyReproductiveStatus(
          situacaoReprodutiva,
          excludedReproductiveStatuses,
        ) ||
        excludedProductiveStatuses.contains(situacaoProdutiva)) {
      return null;
    }

    return _diasEntre(dataUltimoParto, dataPrimeiraIa);
  }

  static int? _periodoServico({
    required String? situacaoProdutiva,
    required String? situacaoReprodutiva,
    required DateTime? dataUltimoParto,
    required DateTime? dataUltimaIa,
    required int? diasPrenhez,
  }) {
    const excludedProductiveStatuses = {
      AnimalProductiveSituation.heifer,
      AnimalProductiveSituation.prepartum,
    };
    if (!_isPregnant(situacaoReprodutiva) ||
        excludedProductiveStatuses.contains(situacaoProdutiva) ||
        diasPrenhez == null) {
      return null;
    }

    return _diasEntre(dataUltimoParto, dataUltimaIa);
  }

  static int? _diasParaSecar({
    required String? situacaoProdutiva,
    required String? situacaoReprodutiva,
    required int? diasPrenhez,
  }) {
    if (situacaoProdutiva == AnimalProductiveSituation.heifer ||
        !_isPregnant(situacaoReprodutiva) ||
        diasPrenhez == null) {
      return null;
    }

    return 220 - diasPrenhez;
  }

  static DateTime? _previsaoSecagem({
    required String? situacaoProdutiva,
    required String? situacaoReprodutiva,
    required DateTime? dataUltimaIa,
  }) {
    if (situacaoProdutiva == AnimalProductiveSituation.heifer ||
        !_isPregnant(situacaoReprodutiva)) {
      return null;
    }

    return _adicionarDias(dataUltimaIa, 220);
  }

  static int? _periodoLactacao({
    required String? situacaoProdutiva,
    required DateTime? dataSecagemEfetiva,
    required DateTime? dataUltimoParto,
  }) {
    if (situacaoProdutiva != AnimalProductiveSituation.dry) {
      return null;
    }

    return _diasEntre(dataUltimoParto, dataSecagemEfetiva);
  }

  static DateTime? _dataPreParto({
    required String? situacaoReprodutiva,
    required DateTime? dataUltimaIa,
  }) {
    if (!_isPregnant(situacaoReprodutiva)) {
      return null;
    }

    return _adicionarDias(dataUltimaIa, 252);
  }

  static int? _duracaoPreParto({
    required String? situacaoProdutiva,
    required DateTime? entradaPreParto,
    required DateTime? dataUltimoParto,
  }) {
    if (situacaoProdutiva != AnimalProductiveSituation.lactating) {
      return null;
    }

    return _diasEntre(entradaPreParto, dataUltimoParto);
  }

  static DateTime? _previsaoParto({
    required String? situacaoReprodutiva,
    required DateTime? dataUltimaIa,
  }) {
    if (!_isPregnant(situacaoReprodutiva)) {
      return null;
    }

    return _adicionarDias(dataUltimaIa, 282);
  }

  static double? _iepProjetado({
    required String? situacaoProdutiva,
    required String? situacaoReprodutiva,
    required DateTime? previsaoParto,
    required DateTime? dataUltimoParto,
  }) {
    const excludedProductiveStatuses = {
      AnimalProductiveSituation.heifer,
      AnimalProductiveSituation.prepartum,
    };
    if (excludedProductiveStatuses.contains(situacaoProdutiva) ||
        !_isPregnant(situacaoReprodutiva)) {
      return null;
    }

    return _monthsBetween(dataUltimoParto, previsaoParto);
  }

  static double? _controleLeiteiroComDesconto({
    required String? situacaoProdutiva,
    required double? controleLeiteiro,
  }) {
    const excludedProductiveStatuses = {
      AnimalProductiveSituation.dry,
      AnimalProductiveSituation.prepartum,
      AnimalProductiveSituation.heifer,
    };
    if (controleLeiteiro == null ||
        excludedProductiveStatuses.contains(situacaoProdutiva)) {
      return null;
    }

    final result = controleLeiteiro * 0.70;
    return result.isFinite ? result : null;
  }

  static double? _monthsBetween(DateTime? start, DateTime? end) {
    final days = _diasEntre(start, end);
    if (days == null) {
      return null;
    }

    final result = days / 30;
    return result.isFinite ? result : null;
  }

  static int? _diasEntre(DateTime? dataInicial, DateTime? dataFinal) {
    if (dataInicial == null || dataFinal == null) {
      return null;
    }

    final start = _dateOnly(dataInicial);
    final end = _dateOnly(dataFinal);
    return end.difference(start).inDays;
  }

  static DateTime? _adicionarDias(DateTime? data, int? dias) {
    if (data == null || dias == null) {
      return null;
    }

    return _dateOnly(data).add(Duration(days: dias));
  }

  static String? _nomeDoMes(DateTime? data) {
    if (data == null || data.month < 1 || data.month > 12) {
      return null;
    }

    const months = [
      'janeiro',
      'fevereiro',
      'marco',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    return months[data.month - 1];
  }

  static double? _media(Iterable<num?> lista) {
    final validValues = lista
        .whereType<num>()
        .where((value) => value.isFinite)
        .map((value) => value.toDouble())
        .toList(growable: false);
    if (validValues.isEmpty) {
      return null;
    }

    final total = validValues.fold<double>(0, (sum, value) => sum + value);
    final result = total / validValues.length;
    return result.isFinite ? result : null;
  }

  static bool _isPregnant(String? value) {
    return _isReproductiveStatus(value, AnimalReproductiveStatus.pregnant);
  }

  static bool _isAnyReproductiveStatus(
    String? value,
    Set<AnimalReproductiveStatus> statuses,
  ) {
    return statuses.any((status) => _isReproductiveStatus(value, status));
  }

  static bool _isReproductiveStatus(
    String? value,
    AnimalReproductiveStatus status,
  ) {
    final normalized = _normalize(value);
    if (normalized == null) {
      return false;
    }

    if (normalized == status.apiValue.normalize() ||
        normalized == status.label.normalize()) {
      return true;
    }

    return status.aliases.any((alias) => normalized == alias.normalize());
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim().normalize();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
