import 'package:dart_mappable/dart_mappable.dart';

part 'visit_summary_model.mapper.dart';

@MappableClass()
class VisitSummaryModel with VisitSummaryModelMappable {
  const VisitSummaryModel({
    this.id = 0,
    this.idExterno = '',
    this.idPropriedade = 0,
    this.idExternoPropriedade = '',
    this.dataVisita,
    this.observacoes,
    this.idUsuario,
    this.nomeUsuario,
    this.animais = const [],
  });

  final int id;
  final String idExterno;
  final int idPropriedade;
  final String idExternoPropriedade;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataVisita;
  final String? observacoes;
  // Frontend-only nesta etapa. A API atual ainda nao retorna o usuario
  // que cadastrou a visita; o repositorio normaliza esse campo quando existir.
  final int? idUsuario;
  final String? nomeUsuario;
  final List<VisitAnimalEntryModel> animais;

  String? get veterinarioResponsavel {
    final name = nomeUsuario?.trim();
    if (name == null || name.isEmpty) return null;
    return name;
  }
}

@MappableClass()
class VisitAnimalEntryModel with VisitAnimalEntryModelMappable {
  const VisitAnimalEntryModel({
    this.animalId = 0,
    this.animalIdExterno = '',
    this.animalCodigo = '',
    this.animalCategoria = '',
    this.idadeMeses,
    this.dataNascimento,
    this.situacaoProdutiva,
    this.situacaoReprodutiva,
    this.decisao,
    this.dataPrimeiroParto,
    this.dataUltimoParto,
    this.dataPartoAnterior,
    this.numeroPartos,
    this.dataPrimeiraIa,
    this.dataSegundaIa,
    this.dataTerceiraIa,
    this.dataQuartaIa,
    this.dataQuintaIa,
    this.dataUltimaIa,
    this.numeroIaRecebida,
    this.dataSecagemEfetiva,
    this.entradaPreParto,
    this.controleLeiteiro,
    this.diasPrenhez,
    this.diagnostico,
    this.del,
    this.idadePrimeiroPartoMeses,
    this.idadePrimeiraIa,
    this.mesParto,
    this.anoUltimoParto,
    this.iepAtual,
    this.classificacaoPartos,
    this.vacaApta,
    this.intervalo1e2Ia,
    this.intervalo2e3Ia,
    this.intervalo3e4Ia,
    this.intervalo4e5Ia,
    this.mediaIntervaloIa,
    this.previsaoRetornoCio,
    this.delPrimeiraIa,
    this.periodoServico,
    this.diasParaSecar,
    this.previsaoSecagem,
    this.mesSecagem,
    this.diferencaSecagem,
    this.periodoLactacao,
    this.dataPreParto,
    this.mesPreParto,
    this.duracaoPreParto,
    this.previsaoParto,
    this.mesPrevistoParto,
    this.iepProjetado,
    this.controleLeiteiroComDesconto,
  });

  final int animalId;
  final String animalIdExterno;
  final String animalCodigo;
  final String animalCategoria;
  final double? idadeMeses;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataNascimento;
  final String? situacaoProdutiva;
  final String? situacaoReprodutiva;
  final String? decisao;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataPrimeiroParto;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataUltimoParto;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataPartoAnterior;
  final int? numeroPartos;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataPrimeiraIa;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataSegundaIa;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataTerceiraIa;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataQuartaIa;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataQuintaIa;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataUltimaIa;
  final int? numeroIaRecebida;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataSecagemEfetiva;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? entradaPreParto;
  final double? controleLeiteiro;
  final int? diasPrenhez;
  final String? diagnostico;
  final int? del;
  final double? idadePrimeiroPartoMeses;
  final double? idadePrimeiraIa;
  final String? mesParto;
  final int? anoUltimoParto;
  final double? iepAtual;
  final String? classificacaoPartos;
  final bool? vacaApta;
  final int? intervalo1e2Ia;
  final int? intervalo2e3Ia;
  final int? intervalo3e4Ia;
  final int? intervalo4e5Ia;
  final double? mediaIntervaloIa;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? previsaoRetornoCio;
  final int? delPrimeiraIa;
  final int? periodoServico;
  final int? diasParaSecar;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? previsaoSecagem;
  final String? mesSecagem;
  final int? diferencaSecagem;
  final int? periodoLactacao;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? dataPreParto;
  final String? mesPreParto;
  final int? duracaoPreParto;
  @MappableField(hook: _NullableDateTimeHook())
  final DateTime? previsaoParto;
  final String? mesPrevistoParto;
  final double? iepProjetado;
  final double? controleLeiteiroComDesconto;

  bool get hasCollectedData {
    return dataNascimento != null ||
        (situacaoProdutiva?.trim().isNotEmpty == true) ||
        (situacaoReprodutiva?.trim().isNotEmpty == true) ||
        (decisao?.trim().isNotEmpty == true) ||
        dataPrimeiroParto != null ||
        dataUltimoParto != null ||
        dataPartoAnterior != null ||
        numeroPartos != null ||
        dataPrimeiraIa != null ||
        dataSegundaIa != null ||
        dataTerceiraIa != null ||
        dataQuartaIa != null ||
        dataQuintaIa != null ||
        dataUltimaIa != null ||
        numeroIaRecebida != null ||
        dataSecagemEfetiva != null ||
        entradaPreParto != null ||
        controleLeiteiro != null ||
        diasPrenhez != null ||
        (diagnostico?.trim().isNotEmpty == true) ||
        del != null ||
        diasParaSecar != null ||
        previsaoSecagem != null ||
        dataPreParto != null ||
        previsaoParto != null;
  }
}

class _NullableDateTimeHook extends MappingHook {
  const _NullableDateTimeHook();

  @override
  Object? beforeDecode(Object? value) {
    if (value is String) {
      if (value.isEmpty) {
        return null;
      }

      return DateTime.tryParse(value);
    }

    return value;
  }
}
