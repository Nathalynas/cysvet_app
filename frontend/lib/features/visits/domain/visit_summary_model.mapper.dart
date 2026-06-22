// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'visit_summary_model.dart';

class VisitSummaryModelMapper extends ClassMapperBase<VisitSummaryModel> {
  VisitSummaryModelMapper._();

  static VisitSummaryModelMapper? _instance;
  static VisitSummaryModelMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = VisitSummaryModelMapper._());
      VisitAnimalEntryModelMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'VisitSummaryModel';

  static int _$id(VisitSummaryModel v) => v.id;
  static const Field<VisitSummaryModel, int> _f$id = Field(
    'id',
    _$id,
    opt: true,
    def: 0,
  );
  static String _$idExterno(VisitSummaryModel v) => v.idExterno;
  static const Field<VisitSummaryModel, String> _f$idExterno = Field(
    'idExterno',
    _$idExterno,
    opt: true,
    def: '',
  );
  static int _$idPropriedade(VisitSummaryModel v) => v.idPropriedade;
  static const Field<VisitSummaryModel, int> _f$idPropriedade = Field(
    'idPropriedade',
    _$idPropriedade,
    opt: true,
    def: 0,
  );
  static String _$idExternoPropriedade(VisitSummaryModel v) =>
      v.idExternoPropriedade;
  static const Field<VisitSummaryModel, String> _f$idExternoPropriedade = Field(
    'idExternoPropriedade',
    _$idExternoPropriedade,
    opt: true,
    def: '',
  );
  static DateTime? _$dataVisita(VisitSummaryModel v) => v.dataVisita;
  static const Field<VisitSummaryModel, DateTime> _f$dataVisita = Field(
    'dataVisita',
    _$dataVisita,
    opt: true,
    hook: _NullableDateTimeHook(),
  );
  static String? _$observacoes(VisitSummaryModel v) => v.observacoes;
  static const Field<VisitSummaryModel, String> _f$observacoes = Field(
    'observacoes',
    _$observacoes,
    opt: true,
  );
  static int? _$idUsuario(VisitSummaryModel v) => v.idUsuario;
  static const Field<VisitSummaryModel, int> _f$idUsuario = Field(
    'idUsuario',
    _$idUsuario,
    opt: true,
  );
  static String? _$nomeUsuario(VisitSummaryModel v) => v.nomeUsuario;
  static const Field<VisitSummaryModel, String> _f$nomeUsuario = Field(
    'nomeUsuario',
    _$nomeUsuario,
    opt: true,
  );
  static List<VisitAnimalEntryModel> _$animais(VisitSummaryModel v) =>
      v.animais;
  static const Field<VisitSummaryModel, List<VisitAnimalEntryModel>>
  _f$animais = Field('animais', _$animais, opt: true, def: const []);

  @override
  final MappableFields<VisitSummaryModel> fields = const {
    #id: _f$id,
    #idExterno: _f$idExterno,
    #idPropriedade: _f$idPropriedade,
    #idExternoPropriedade: _f$idExternoPropriedade,
    #dataVisita: _f$dataVisita,
    #observacoes: _f$observacoes,
    #idUsuario: _f$idUsuario,
    #nomeUsuario: _f$nomeUsuario,
    #animais: _f$animais,
  };

  static VisitSummaryModel _instantiate(DecodingData data) {
    return VisitSummaryModel(
      id: data.dec(_f$id),
      idExterno: data.dec(_f$idExterno),
      idPropriedade: data.dec(_f$idPropriedade),
      idExternoPropriedade: data.dec(_f$idExternoPropriedade),
      dataVisita: data.dec(_f$dataVisita),
      observacoes: data.dec(_f$observacoes),
      idUsuario: data.dec(_f$idUsuario),
      nomeUsuario: data.dec(_f$nomeUsuario),
      animais: data.dec(_f$animais),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static VisitSummaryModel fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<VisitSummaryModel>(map);
  }

  static VisitSummaryModel fromJson(String json) {
    return ensureInitialized().decodeJson<VisitSummaryModel>(json);
  }
}

mixin VisitSummaryModelMappable {
  String toJson() {
    return VisitSummaryModelMapper.ensureInitialized()
        .encodeJson<VisitSummaryModel>(this as VisitSummaryModel);
  }

  Map<String, dynamic> toMap() {
    return VisitSummaryModelMapper.ensureInitialized()
        .encodeMap<VisitSummaryModel>(this as VisitSummaryModel);
  }

  VisitSummaryModelCopyWith<
    VisitSummaryModel,
    VisitSummaryModel,
    VisitSummaryModel
  >
  get copyWith =>
      _VisitSummaryModelCopyWithImpl<VisitSummaryModel, VisitSummaryModel>(
        this as VisitSummaryModel,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return VisitSummaryModelMapper.ensureInitialized().stringifyValue(
      this as VisitSummaryModel,
    );
  }

  @override
  bool operator ==(Object other) {
    return VisitSummaryModelMapper.ensureInitialized().equalsValue(
      this as VisitSummaryModel,
      other,
    );
  }

  @override
  int get hashCode {
    return VisitSummaryModelMapper.ensureInitialized().hashValue(
      this as VisitSummaryModel,
    );
  }
}

extension VisitSummaryModelValueCopy<$R, $Out>
    on ObjectCopyWith<$R, VisitSummaryModel, $Out> {
  VisitSummaryModelCopyWith<$R, VisitSummaryModel, $Out>
  get $asVisitSummaryModel => $base.as(
    (v, t, t2) => _VisitSummaryModelCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class VisitSummaryModelCopyWith<
  $R,
  $In extends VisitSummaryModel,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    VisitAnimalEntryModel,
    VisitAnimalEntryModelCopyWith<
      $R,
      VisitAnimalEntryModel,
      VisitAnimalEntryModel
    >
  >
  get animais;
  $R call({
    int? id,
    String? idExterno,
    int? idPropriedade,
    String? idExternoPropriedade,
    DateTime? dataVisita,
    String? observacoes,
    int? idUsuario,
    String? nomeUsuario,
    List<VisitAnimalEntryModel>? animais,
  });
  VisitSummaryModelCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _VisitSummaryModelCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, VisitSummaryModel, $Out>
    implements VisitSummaryModelCopyWith<$R, VisitSummaryModel, $Out> {
  _VisitSummaryModelCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<VisitSummaryModel> $mapper =
      VisitSummaryModelMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    VisitAnimalEntryModel,
    VisitAnimalEntryModelCopyWith<
      $R,
      VisitAnimalEntryModel,
      VisitAnimalEntryModel
    >
  >
  get animais => ListCopyWith(
    $value.animais,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(animais: v),
  );
  @override
  $R call({
    int? id,
    String? idExterno,
    int? idPropriedade,
    String? idExternoPropriedade,
    Object? dataVisita = $none,
    Object? observacoes = $none,
    Object? idUsuario = $none,
    Object? nomeUsuario = $none,
    List<VisitAnimalEntryModel>? animais,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (idExterno != null) #idExterno: idExterno,
      if (idPropriedade != null) #idPropriedade: idPropriedade,
      if (idExternoPropriedade != null)
        #idExternoPropriedade: idExternoPropriedade,
      if (dataVisita != $none) #dataVisita: dataVisita,
      if (observacoes != $none) #observacoes: observacoes,
      if (idUsuario != $none) #idUsuario: idUsuario,
      if (nomeUsuario != $none) #nomeUsuario: nomeUsuario,
      if (animais != null) #animais: animais,
    }),
  );
  @override
  VisitSummaryModel $make(CopyWithData data) => VisitSummaryModel(
    id: data.get(#id, or: $value.id),
    idExterno: data.get(#idExterno, or: $value.idExterno),
    idPropriedade: data.get(#idPropriedade, or: $value.idPropriedade),
    idExternoPropriedade: data.get(
      #idExternoPropriedade,
      or: $value.idExternoPropriedade,
    ),
    dataVisita: data.get(#dataVisita, or: $value.dataVisita),
    observacoes: data.get(#observacoes, or: $value.observacoes),
    idUsuario: data.get(#idUsuario, or: $value.idUsuario),
    nomeUsuario: data.get(#nomeUsuario, or: $value.nomeUsuario),
    animais: data.get(#animais, or: $value.animais),
  );

  @override
  VisitSummaryModelCopyWith<$R2, VisitSummaryModel, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _VisitSummaryModelCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class VisitAnimalEntryModelMapper
    extends ClassMapperBase<VisitAnimalEntryModel> {
  VisitAnimalEntryModelMapper._();

  static VisitAnimalEntryModelMapper? _instance;
  static VisitAnimalEntryModelMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = VisitAnimalEntryModelMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'VisitAnimalEntryModel';

  static int _$animalId(VisitAnimalEntryModel v) => v.animalId;
  static const Field<VisitAnimalEntryModel, int> _f$animalId = Field(
    'animalId',
    _$animalId,
    opt: true,
    def: 0,
  );
  static String _$animalIdExterno(VisitAnimalEntryModel v) => v.animalIdExterno;
  static const Field<VisitAnimalEntryModel, String> _f$animalIdExterno = Field(
    'animalIdExterno',
    _$animalIdExterno,
    opt: true,
    def: '',
  );
  static String _$animalCodigo(VisitAnimalEntryModel v) => v.animalCodigo;
  static const Field<VisitAnimalEntryModel, String> _f$animalCodigo = Field(
    'animalCodigo',
    _$animalCodigo,
    opt: true,
    def: '',
  );
  static String _$animalCategoria(VisitAnimalEntryModel v) => v.animalCategoria;
  static const Field<VisitAnimalEntryModel, String> _f$animalCategoria = Field(
    'animalCategoria',
    _$animalCategoria,
    opt: true,
    def: '',
  );
  static double? _$idadeMeses(VisitAnimalEntryModel v) => v.idadeMeses;
  static const Field<VisitAnimalEntryModel, double> _f$idadeMeses = Field(
    'idadeMeses',
    _$idadeMeses,
    opt: true,
  );
  static DateTime? _$dataNascimento(VisitAnimalEntryModel v) =>
      v.dataNascimento;
  static const Field<VisitAnimalEntryModel, DateTime> _f$dataNascimento = Field(
    'dataNascimento',
    _$dataNascimento,
    opt: true,
    hook: _NullableDateTimeHook(),
  );
  static String? _$situacaoProdutiva(VisitAnimalEntryModel v) =>
      v.situacaoProdutiva;
  static const Field<VisitAnimalEntryModel, String> _f$situacaoProdutiva =
      Field('situacaoProdutiva', _$situacaoProdutiva, opt: true);
  static String? _$situacaoReprodutiva(VisitAnimalEntryModel v) =>
      v.situacaoReprodutiva;
  static const Field<VisitAnimalEntryModel, String> _f$situacaoReprodutiva =
      Field('situacaoReprodutiva', _$situacaoReprodutiva, opt: true);
  static String? _$decisao(VisitAnimalEntryModel v) => v.decisao;
  static const Field<VisitAnimalEntryModel, String> _f$decisao = Field(
    'decisao',
    _$decisao,
    opt: true,
  );
  static DateTime? _$dataPrimeiroParto(VisitAnimalEntryModel v) =>
      v.dataPrimeiroParto;
  static const Field<VisitAnimalEntryModel, DateTime> _f$dataPrimeiroParto =
      Field(
        'dataPrimeiroParto',
        _$dataPrimeiroParto,
        opt: true,
        hook: _NullableDateTimeHook(),
      );
  static DateTime? _$dataUltimoParto(VisitAnimalEntryModel v) =>
      v.dataUltimoParto;
  static const Field<VisitAnimalEntryModel, DateTime> _f$dataUltimoParto =
      Field(
        'dataUltimoParto',
        _$dataUltimoParto,
        opt: true,
        hook: _NullableDateTimeHook(),
      );
  static DateTime? _$dataPartoAnterior(VisitAnimalEntryModel v) =>
      v.dataPartoAnterior;
  static const Field<VisitAnimalEntryModel, DateTime> _f$dataPartoAnterior =
      Field(
        'dataPartoAnterior',
        _$dataPartoAnterior,
        opt: true,
        hook: _NullableDateTimeHook(),
      );
  static int? _$numeroPartos(VisitAnimalEntryModel v) => v.numeroPartos;
  static const Field<VisitAnimalEntryModel, int> _f$numeroPartos = Field(
    'numeroPartos',
    _$numeroPartos,
    opt: true,
  );
  static DateTime? _$dataPrimeiraIa(VisitAnimalEntryModel v) =>
      v.dataPrimeiraIa;
  static const Field<VisitAnimalEntryModel, DateTime> _f$dataPrimeiraIa = Field(
    'dataPrimeiraIa',
    _$dataPrimeiraIa,
    opt: true,
    hook: _NullableDateTimeHook(),
  );
  static DateTime? _$dataSegundaIa(VisitAnimalEntryModel v) => v.dataSegundaIa;
  static const Field<VisitAnimalEntryModel, DateTime> _f$dataSegundaIa = Field(
    'dataSegundaIa',
    _$dataSegundaIa,
    opt: true,
    hook: _NullableDateTimeHook(),
  );
  static DateTime? _$dataTerceiraIa(VisitAnimalEntryModel v) =>
      v.dataTerceiraIa;
  static const Field<VisitAnimalEntryModel, DateTime> _f$dataTerceiraIa = Field(
    'dataTerceiraIa',
    _$dataTerceiraIa,
    opt: true,
    hook: _NullableDateTimeHook(),
  );
  static DateTime? _$dataQuartaIa(VisitAnimalEntryModel v) => v.dataQuartaIa;
  static const Field<VisitAnimalEntryModel, DateTime> _f$dataQuartaIa = Field(
    'dataQuartaIa',
    _$dataQuartaIa,
    opt: true,
    hook: _NullableDateTimeHook(),
  );
  static DateTime? _$dataQuintaIa(VisitAnimalEntryModel v) => v.dataQuintaIa;
  static const Field<VisitAnimalEntryModel, DateTime> _f$dataQuintaIa = Field(
    'dataQuintaIa',
    _$dataQuintaIa,
    opt: true,
    hook: _NullableDateTimeHook(),
  );
  static DateTime? _$dataUltimaIa(VisitAnimalEntryModel v) => v.dataUltimaIa;
  static const Field<VisitAnimalEntryModel, DateTime> _f$dataUltimaIa = Field(
    'dataUltimaIa',
    _$dataUltimaIa,
    opt: true,
    hook: _NullableDateTimeHook(),
  );
  static int? _$numeroIaRecebida(VisitAnimalEntryModel v) => v.numeroIaRecebida;
  static const Field<VisitAnimalEntryModel, int> _f$numeroIaRecebida = Field(
    'numeroIaRecebida',
    _$numeroIaRecebida,
    opt: true,
  );
  static DateTime? _$dataSecagemEfetiva(VisitAnimalEntryModel v) =>
      v.dataSecagemEfetiva;
  static const Field<VisitAnimalEntryModel, DateTime> _f$dataSecagemEfetiva =
      Field(
        'dataSecagemEfetiva',
        _$dataSecagemEfetiva,
        opt: true,
        hook: _NullableDateTimeHook(),
      );
  static DateTime? _$entradaPreParto(VisitAnimalEntryModel v) =>
      v.entradaPreParto;
  static const Field<VisitAnimalEntryModel, DateTime> _f$entradaPreParto =
      Field(
        'entradaPreParto',
        _$entradaPreParto,
        opt: true,
        hook: _NullableDateTimeHook(),
      );
  static double? _$controleLeiteiro(VisitAnimalEntryModel v) =>
      v.controleLeiteiro;
  static const Field<VisitAnimalEntryModel, double> _f$controleLeiteiro = Field(
    'controleLeiteiro',
    _$controleLeiteiro,
    opt: true,
  );
  static int? _$diasPrenhez(VisitAnimalEntryModel v) => v.diasPrenhez;
  static const Field<VisitAnimalEntryModel, int> _f$diasPrenhez = Field(
    'diasPrenhez',
    _$diasPrenhez,
    opt: true,
  );
  static String? _$diagnostico(VisitAnimalEntryModel v) => v.diagnostico;
  static const Field<VisitAnimalEntryModel, String> _f$diagnostico = Field(
    'diagnostico',
    _$diagnostico,
    opt: true,
  );
  static int? _$del(VisitAnimalEntryModel v) => v.del;
  static const Field<VisitAnimalEntryModel, int> _f$del = Field(
    'del',
    _$del,
    opt: true,
  );
  static double? _$idadePrimeiroPartoMeses(VisitAnimalEntryModel v) =>
      v.idadePrimeiroPartoMeses;
  static const Field<VisitAnimalEntryModel, double> _f$idadePrimeiroPartoMeses =
      Field('idadePrimeiroPartoMeses', _$idadePrimeiroPartoMeses, opt: true);
  static double? _$idadePrimeiraIa(VisitAnimalEntryModel v) =>
      v.idadePrimeiraIa;
  static const Field<VisitAnimalEntryModel, double> _f$idadePrimeiraIa = Field(
    'idadePrimeiraIa',
    _$idadePrimeiraIa,
    opt: true,
  );
  static String? _$mesParto(VisitAnimalEntryModel v) => v.mesParto;
  static const Field<VisitAnimalEntryModel, String> _f$mesParto = Field(
    'mesParto',
    _$mesParto,
    opt: true,
  );
  static int? _$anoUltimoParto(VisitAnimalEntryModel v) => v.anoUltimoParto;
  static const Field<VisitAnimalEntryModel, int> _f$anoUltimoParto = Field(
    'anoUltimoParto',
    _$anoUltimoParto,
    opt: true,
  );
  static double? _$iepAtual(VisitAnimalEntryModel v) => v.iepAtual;
  static const Field<VisitAnimalEntryModel, double> _f$iepAtual = Field(
    'iepAtual',
    _$iepAtual,
    opt: true,
  );
  static String? _$classificacaoPartos(VisitAnimalEntryModel v) =>
      v.classificacaoPartos;
  static const Field<VisitAnimalEntryModel, String> _f$classificacaoPartos =
      Field('classificacaoPartos', _$classificacaoPartos, opt: true);
  static bool? _$vacaApta(VisitAnimalEntryModel v) => v.vacaApta;
  static const Field<VisitAnimalEntryModel, bool> _f$vacaApta = Field(
    'vacaApta',
    _$vacaApta,
    opt: true,
  );
  static int? _$intervalo1e2Ia(VisitAnimalEntryModel v) => v.intervalo1e2Ia;
  static const Field<VisitAnimalEntryModel, int> _f$intervalo1e2Ia = Field(
    'intervalo1e2Ia',
    _$intervalo1e2Ia,
    opt: true,
  );
  static int? _$intervalo2e3Ia(VisitAnimalEntryModel v) => v.intervalo2e3Ia;
  static const Field<VisitAnimalEntryModel, int> _f$intervalo2e3Ia = Field(
    'intervalo2e3Ia',
    _$intervalo2e3Ia,
    opt: true,
  );
  static int? _$intervalo3e4Ia(VisitAnimalEntryModel v) => v.intervalo3e4Ia;
  static const Field<VisitAnimalEntryModel, int> _f$intervalo3e4Ia = Field(
    'intervalo3e4Ia',
    _$intervalo3e4Ia,
    opt: true,
  );
  static int? _$intervalo4e5Ia(VisitAnimalEntryModel v) => v.intervalo4e5Ia;
  static const Field<VisitAnimalEntryModel, int> _f$intervalo4e5Ia = Field(
    'intervalo4e5Ia',
    _$intervalo4e5Ia,
    opt: true,
  );
  static double? _$mediaIntervaloIa(VisitAnimalEntryModel v) =>
      v.mediaIntervaloIa;
  static const Field<VisitAnimalEntryModel, double> _f$mediaIntervaloIa = Field(
    'mediaIntervaloIa',
    _$mediaIntervaloIa,
    opt: true,
  );
  static DateTime? _$previsaoRetornoCio(VisitAnimalEntryModel v) =>
      v.previsaoRetornoCio;
  static const Field<VisitAnimalEntryModel, DateTime> _f$previsaoRetornoCio =
      Field(
        'previsaoRetornoCio',
        _$previsaoRetornoCio,
        opt: true,
        hook: _NullableDateTimeHook(),
      );
  static int? _$delPrimeiraIa(VisitAnimalEntryModel v) => v.delPrimeiraIa;
  static const Field<VisitAnimalEntryModel, int> _f$delPrimeiraIa = Field(
    'delPrimeiraIa',
    _$delPrimeiraIa,
    opt: true,
  );
  static int? _$periodoServico(VisitAnimalEntryModel v) => v.periodoServico;
  static const Field<VisitAnimalEntryModel, int> _f$periodoServico = Field(
    'periodoServico',
    _$periodoServico,
    opt: true,
  );
  static int? _$diasParaSecar(VisitAnimalEntryModel v) => v.diasParaSecar;
  static const Field<VisitAnimalEntryModel, int> _f$diasParaSecar = Field(
    'diasParaSecar',
    _$diasParaSecar,
    opt: true,
  );
  static DateTime? _$previsaoSecagem(VisitAnimalEntryModel v) =>
      v.previsaoSecagem;
  static const Field<VisitAnimalEntryModel, DateTime> _f$previsaoSecagem =
      Field(
        'previsaoSecagem',
        _$previsaoSecagem,
        opt: true,
        hook: _NullableDateTimeHook(),
      );
  static String? _$mesSecagem(VisitAnimalEntryModel v) => v.mesSecagem;
  static const Field<VisitAnimalEntryModel, String> _f$mesSecagem = Field(
    'mesSecagem',
    _$mesSecagem,
    opt: true,
  );
  static int? _$diferencaSecagem(VisitAnimalEntryModel v) => v.diferencaSecagem;
  static const Field<VisitAnimalEntryModel, int> _f$diferencaSecagem = Field(
    'diferencaSecagem',
    _$diferencaSecagem,
    opt: true,
  );
  static int? _$periodoLactacao(VisitAnimalEntryModel v) => v.periodoLactacao;
  static const Field<VisitAnimalEntryModel, int> _f$periodoLactacao = Field(
    'periodoLactacao',
    _$periodoLactacao,
    opt: true,
  );
  static DateTime? _$dataPreParto(VisitAnimalEntryModel v) => v.dataPreParto;
  static const Field<VisitAnimalEntryModel, DateTime> _f$dataPreParto = Field(
    'dataPreParto',
    _$dataPreParto,
    opt: true,
    hook: _NullableDateTimeHook(),
  );
  static String? _$mesPreParto(VisitAnimalEntryModel v) => v.mesPreParto;
  static const Field<VisitAnimalEntryModel, String> _f$mesPreParto = Field(
    'mesPreParto',
    _$mesPreParto,
    opt: true,
  );
  static int? _$duracaoPreParto(VisitAnimalEntryModel v) => v.duracaoPreParto;
  static const Field<VisitAnimalEntryModel, int> _f$duracaoPreParto = Field(
    'duracaoPreParto',
    _$duracaoPreParto,
    opt: true,
  );
  static DateTime? _$previsaoParto(VisitAnimalEntryModel v) => v.previsaoParto;
  static const Field<VisitAnimalEntryModel, DateTime> _f$previsaoParto = Field(
    'previsaoParto',
    _$previsaoParto,
    opt: true,
    hook: _NullableDateTimeHook(),
  );
  static String? _$mesPrevistoParto(VisitAnimalEntryModel v) =>
      v.mesPrevistoParto;
  static const Field<VisitAnimalEntryModel, String> _f$mesPrevistoParto = Field(
    'mesPrevistoParto',
    _$mesPrevistoParto,
    opt: true,
  );
  static double? _$iepProjetado(VisitAnimalEntryModel v) => v.iepProjetado;
  static const Field<VisitAnimalEntryModel, double> _f$iepProjetado = Field(
    'iepProjetado',
    _$iepProjetado,
    opt: true,
  );
  static double? _$controleLeiteiroComDesconto(VisitAnimalEntryModel v) =>
      v.controleLeiteiroComDesconto;
  static const Field<VisitAnimalEntryModel, double>
  _f$controleLeiteiroComDesconto = Field(
    'controleLeiteiroComDesconto',
    _$controleLeiteiroComDesconto,
    opt: true,
  );

  @override
  final MappableFields<VisitAnimalEntryModel> fields = const {
    #animalId: _f$animalId,
    #animalIdExterno: _f$animalIdExterno,
    #animalCodigo: _f$animalCodigo,
    #animalCategoria: _f$animalCategoria,
    #idadeMeses: _f$idadeMeses,
    #dataNascimento: _f$dataNascimento,
    #situacaoProdutiva: _f$situacaoProdutiva,
    #situacaoReprodutiva: _f$situacaoReprodutiva,
    #decisao: _f$decisao,
    #dataPrimeiroParto: _f$dataPrimeiroParto,
    #dataUltimoParto: _f$dataUltimoParto,
    #dataPartoAnterior: _f$dataPartoAnterior,
    #numeroPartos: _f$numeroPartos,
    #dataPrimeiraIa: _f$dataPrimeiraIa,
    #dataSegundaIa: _f$dataSegundaIa,
    #dataTerceiraIa: _f$dataTerceiraIa,
    #dataQuartaIa: _f$dataQuartaIa,
    #dataQuintaIa: _f$dataQuintaIa,
    #dataUltimaIa: _f$dataUltimaIa,
    #numeroIaRecebida: _f$numeroIaRecebida,
    #dataSecagemEfetiva: _f$dataSecagemEfetiva,
    #entradaPreParto: _f$entradaPreParto,
    #controleLeiteiro: _f$controleLeiteiro,
    #diasPrenhez: _f$diasPrenhez,
    #diagnostico: _f$diagnostico,
    #del: _f$del,
    #idadePrimeiroPartoMeses: _f$idadePrimeiroPartoMeses,
    #idadePrimeiraIa: _f$idadePrimeiraIa,
    #mesParto: _f$mesParto,
    #anoUltimoParto: _f$anoUltimoParto,
    #iepAtual: _f$iepAtual,
    #classificacaoPartos: _f$classificacaoPartos,
    #vacaApta: _f$vacaApta,
    #intervalo1e2Ia: _f$intervalo1e2Ia,
    #intervalo2e3Ia: _f$intervalo2e3Ia,
    #intervalo3e4Ia: _f$intervalo3e4Ia,
    #intervalo4e5Ia: _f$intervalo4e5Ia,
    #mediaIntervaloIa: _f$mediaIntervaloIa,
    #previsaoRetornoCio: _f$previsaoRetornoCio,
    #delPrimeiraIa: _f$delPrimeiraIa,
    #periodoServico: _f$periodoServico,
    #diasParaSecar: _f$diasParaSecar,
    #previsaoSecagem: _f$previsaoSecagem,
    #mesSecagem: _f$mesSecagem,
    #diferencaSecagem: _f$diferencaSecagem,
    #periodoLactacao: _f$periodoLactacao,
    #dataPreParto: _f$dataPreParto,
    #mesPreParto: _f$mesPreParto,
    #duracaoPreParto: _f$duracaoPreParto,
    #previsaoParto: _f$previsaoParto,
    #mesPrevistoParto: _f$mesPrevistoParto,
    #iepProjetado: _f$iepProjetado,
    #controleLeiteiroComDesconto: _f$controleLeiteiroComDesconto,
  };

  static VisitAnimalEntryModel _instantiate(DecodingData data) {
    return VisitAnimalEntryModel(
      animalId: data.dec(_f$animalId),
      animalIdExterno: data.dec(_f$animalIdExterno),
      animalCodigo: data.dec(_f$animalCodigo),
      animalCategoria: data.dec(_f$animalCategoria),
      idadeMeses: data.dec(_f$idadeMeses),
      dataNascimento: data.dec(_f$dataNascimento),
      situacaoProdutiva: data.dec(_f$situacaoProdutiva),
      situacaoReprodutiva: data.dec(_f$situacaoReprodutiva),
      decisao: data.dec(_f$decisao),
      dataPrimeiroParto: data.dec(_f$dataPrimeiroParto),
      dataUltimoParto: data.dec(_f$dataUltimoParto),
      dataPartoAnterior: data.dec(_f$dataPartoAnterior),
      numeroPartos: data.dec(_f$numeroPartos),
      dataPrimeiraIa: data.dec(_f$dataPrimeiraIa),
      dataSegundaIa: data.dec(_f$dataSegundaIa),
      dataTerceiraIa: data.dec(_f$dataTerceiraIa),
      dataQuartaIa: data.dec(_f$dataQuartaIa),
      dataQuintaIa: data.dec(_f$dataQuintaIa),
      dataUltimaIa: data.dec(_f$dataUltimaIa),
      numeroIaRecebida: data.dec(_f$numeroIaRecebida),
      dataSecagemEfetiva: data.dec(_f$dataSecagemEfetiva),
      entradaPreParto: data.dec(_f$entradaPreParto),
      controleLeiteiro: data.dec(_f$controleLeiteiro),
      diasPrenhez: data.dec(_f$diasPrenhez),
      diagnostico: data.dec(_f$diagnostico),
      del: data.dec(_f$del),
      idadePrimeiroPartoMeses: data.dec(_f$idadePrimeiroPartoMeses),
      idadePrimeiraIa: data.dec(_f$idadePrimeiraIa),
      mesParto: data.dec(_f$mesParto),
      anoUltimoParto: data.dec(_f$anoUltimoParto),
      iepAtual: data.dec(_f$iepAtual),
      classificacaoPartos: data.dec(_f$classificacaoPartos),
      vacaApta: data.dec(_f$vacaApta),
      intervalo1e2Ia: data.dec(_f$intervalo1e2Ia),
      intervalo2e3Ia: data.dec(_f$intervalo2e3Ia),
      intervalo3e4Ia: data.dec(_f$intervalo3e4Ia),
      intervalo4e5Ia: data.dec(_f$intervalo4e5Ia),
      mediaIntervaloIa: data.dec(_f$mediaIntervaloIa),
      previsaoRetornoCio: data.dec(_f$previsaoRetornoCio),
      delPrimeiraIa: data.dec(_f$delPrimeiraIa),
      periodoServico: data.dec(_f$periodoServico),
      diasParaSecar: data.dec(_f$diasParaSecar),
      previsaoSecagem: data.dec(_f$previsaoSecagem),
      mesSecagem: data.dec(_f$mesSecagem),
      diferencaSecagem: data.dec(_f$diferencaSecagem),
      periodoLactacao: data.dec(_f$periodoLactacao),
      dataPreParto: data.dec(_f$dataPreParto),
      mesPreParto: data.dec(_f$mesPreParto),
      duracaoPreParto: data.dec(_f$duracaoPreParto),
      previsaoParto: data.dec(_f$previsaoParto),
      mesPrevistoParto: data.dec(_f$mesPrevistoParto),
      iepProjetado: data.dec(_f$iepProjetado),
      controleLeiteiroComDesconto: data.dec(_f$controleLeiteiroComDesconto),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static VisitAnimalEntryModel fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<VisitAnimalEntryModel>(map);
  }

  static VisitAnimalEntryModel fromJson(String json) {
    return ensureInitialized().decodeJson<VisitAnimalEntryModel>(json);
  }
}

mixin VisitAnimalEntryModelMappable {
  String toJson() {
    return VisitAnimalEntryModelMapper.ensureInitialized()
        .encodeJson<VisitAnimalEntryModel>(this as VisitAnimalEntryModel);
  }

  Map<String, dynamic> toMap() {
    return VisitAnimalEntryModelMapper.ensureInitialized()
        .encodeMap<VisitAnimalEntryModel>(this as VisitAnimalEntryModel);
  }

  VisitAnimalEntryModelCopyWith<
    VisitAnimalEntryModel,
    VisitAnimalEntryModel,
    VisitAnimalEntryModel
  >
  get copyWith =>
      _VisitAnimalEntryModelCopyWithImpl<
        VisitAnimalEntryModel,
        VisitAnimalEntryModel
      >(this as VisitAnimalEntryModel, $identity, $identity);
  @override
  String toString() {
    return VisitAnimalEntryModelMapper.ensureInitialized().stringifyValue(
      this as VisitAnimalEntryModel,
    );
  }

  @override
  bool operator ==(Object other) {
    return VisitAnimalEntryModelMapper.ensureInitialized().equalsValue(
      this as VisitAnimalEntryModel,
      other,
    );
  }

  @override
  int get hashCode {
    return VisitAnimalEntryModelMapper.ensureInitialized().hashValue(
      this as VisitAnimalEntryModel,
    );
  }
}

extension VisitAnimalEntryModelValueCopy<$R, $Out>
    on ObjectCopyWith<$R, VisitAnimalEntryModel, $Out> {
  VisitAnimalEntryModelCopyWith<$R, VisitAnimalEntryModel, $Out>
  get $asVisitAnimalEntryModel => $base.as(
    (v, t, t2) => _VisitAnimalEntryModelCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class VisitAnimalEntryModelCopyWith<
  $R,
  $In extends VisitAnimalEntryModel,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    int? animalId,
    String? animalIdExterno,
    String? animalCodigo,
    String? animalCategoria,
    double? idadeMeses,
    DateTime? dataNascimento,
    String? situacaoProdutiva,
    String? situacaoReprodutiva,
    String? decisao,
    DateTime? dataPrimeiroParto,
    DateTime? dataUltimoParto,
    DateTime? dataPartoAnterior,
    int? numeroPartos,
    DateTime? dataPrimeiraIa,
    DateTime? dataSegundaIa,
    DateTime? dataTerceiraIa,
    DateTime? dataQuartaIa,
    DateTime? dataQuintaIa,
    DateTime? dataUltimaIa,
    int? numeroIaRecebida,
    DateTime? dataSecagemEfetiva,
    DateTime? entradaPreParto,
    double? controleLeiteiro,
    int? diasPrenhez,
    String? diagnostico,
    int? del,
    double? idadePrimeiroPartoMeses,
    double? idadePrimeiraIa,
    String? mesParto,
    int? anoUltimoParto,
    double? iepAtual,
    String? classificacaoPartos,
    bool? vacaApta,
    int? intervalo1e2Ia,
    int? intervalo2e3Ia,
    int? intervalo3e4Ia,
    int? intervalo4e5Ia,
    double? mediaIntervaloIa,
    DateTime? previsaoRetornoCio,
    int? delPrimeiraIa,
    int? periodoServico,
    int? diasParaSecar,
    DateTime? previsaoSecagem,
    String? mesSecagem,
    int? diferencaSecagem,
    int? periodoLactacao,
    DateTime? dataPreParto,
    String? mesPreParto,
    int? duracaoPreParto,
    DateTime? previsaoParto,
    String? mesPrevistoParto,
    double? iepProjetado,
    double? controleLeiteiroComDesconto,
  });
  VisitAnimalEntryModelCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _VisitAnimalEntryModelCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, VisitAnimalEntryModel, $Out>
    implements VisitAnimalEntryModelCopyWith<$R, VisitAnimalEntryModel, $Out> {
  _VisitAnimalEntryModelCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<VisitAnimalEntryModel> $mapper =
      VisitAnimalEntryModelMapper.ensureInitialized();
  @override
  $R call({
    int? animalId,
    String? animalIdExterno,
    String? animalCodigo,
    String? animalCategoria,
    Object? idadeMeses = $none,
    Object? dataNascimento = $none,
    Object? situacaoProdutiva = $none,
    Object? situacaoReprodutiva = $none,
    Object? decisao = $none,
    Object? dataPrimeiroParto = $none,
    Object? dataUltimoParto = $none,
    Object? dataPartoAnterior = $none,
    Object? numeroPartos = $none,
    Object? dataPrimeiraIa = $none,
    Object? dataSegundaIa = $none,
    Object? dataTerceiraIa = $none,
    Object? dataQuartaIa = $none,
    Object? dataQuintaIa = $none,
    Object? dataUltimaIa = $none,
    Object? numeroIaRecebida = $none,
    Object? dataSecagemEfetiva = $none,
    Object? entradaPreParto = $none,
    Object? controleLeiteiro = $none,
    Object? diasPrenhez = $none,
    Object? diagnostico = $none,
    Object? del = $none,
    Object? idadePrimeiroPartoMeses = $none,
    Object? idadePrimeiraIa = $none,
    Object? mesParto = $none,
    Object? anoUltimoParto = $none,
    Object? iepAtual = $none,
    Object? classificacaoPartos = $none,
    Object? vacaApta = $none,
    Object? intervalo1e2Ia = $none,
    Object? intervalo2e3Ia = $none,
    Object? intervalo3e4Ia = $none,
    Object? intervalo4e5Ia = $none,
    Object? mediaIntervaloIa = $none,
    Object? previsaoRetornoCio = $none,
    Object? delPrimeiraIa = $none,
    Object? periodoServico = $none,
    Object? diasParaSecar = $none,
    Object? previsaoSecagem = $none,
    Object? mesSecagem = $none,
    Object? diferencaSecagem = $none,
    Object? periodoLactacao = $none,
    Object? dataPreParto = $none,
    Object? mesPreParto = $none,
    Object? duracaoPreParto = $none,
    Object? previsaoParto = $none,
    Object? mesPrevistoParto = $none,
    Object? iepProjetado = $none,
    Object? controleLeiteiroComDesconto = $none,
  }) => $apply(
    FieldCopyWithData({
      if (animalId != null) #animalId: animalId,
      if (animalIdExterno != null) #animalIdExterno: animalIdExterno,
      if (animalCodigo != null) #animalCodigo: animalCodigo,
      if (animalCategoria != null) #animalCategoria: animalCategoria,
      if (idadeMeses != $none) #idadeMeses: idadeMeses,
      if (dataNascimento != $none) #dataNascimento: dataNascimento,
      if (situacaoProdutiva != $none) #situacaoProdutiva: situacaoProdutiva,
      if (situacaoReprodutiva != $none)
        #situacaoReprodutiva: situacaoReprodutiva,
      if (decisao != $none) #decisao: decisao,
      if (dataPrimeiroParto != $none) #dataPrimeiroParto: dataPrimeiroParto,
      if (dataUltimoParto != $none) #dataUltimoParto: dataUltimoParto,
      if (dataPartoAnterior != $none) #dataPartoAnterior: dataPartoAnterior,
      if (numeroPartos != $none) #numeroPartos: numeroPartos,
      if (dataPrimeiraIa != $none) #dataPrimeiraIa: dataPrimeiraIa,
      if (dataSegundaIa != $none) #dataSegundaIa: dataSegundaIa,
      if (dataTerceiraIa != $none) #dataTerceiraIa: dataTerceiraIa,
      if (dataQuartaIa != $none) #dataQuartaIa: dataQuartaIa,
      if (dataQuintaIa != $none) #dataQuintaIa: dataQuintaIa,
      if (dataUltimaIa != $none) #dataUltimaIa: dataUltimaIa,
      if (numeroIaRecebida != $none) #numeroIaRecebida: numeroIaRecebida,
      if (dataSecagemEfetiva != $none) #dataSecagemEfetiva: dataSecagemEfetiva,
      if (entradaPreParto != $none) #entradaPreParto: entradaPreParto,
      if (controleLeiteiro != $none) #controleLeiteiro: controleLeiteiro,
      if (diasPrenhez != $none) #diasPrenhez: diasPrenhez,
      if (diagnostico != $none) #diagnostico: diagnostico,
      if (del != $none) #del: del,
      if (idadePrimeiroPartoMeses != $none)
        #idadePrimeiroPartoMeses: idadePrimeiroPartoMeses,
      if (idadePrimeiraIa != $none) #idadePrimeiraIa: idadePrimeiraIa,
      if (mesParto != $none) #mesParto: mesParto,
      if (anoUltimoParto != $none) #anoUltimoParto: anoUltimoParto,
      if (iepAtual != $none) #iepAtual: iepAtual,
      if (classificacaoPartos != $none)
        #classificacaoPartos: classificacaoPartos,
      if (vacaApta != $none) #vacaApta: vacaApta,
      if (intervalo1e2Ia != $none) #intervalo1e2Ia: intervalo1e2Ia,
      if (intervalo2e3Ia != $none) #intervalo2e3Ia: intervalo2e3Ia,
      if (intervalo3e4Ia != $none) #intervalo3e4Ia: intervalo3e4Ia,
      if (intervalo4e5Ia != $none) #intervalo4e5Ia: intervalo4e5Ia,
      if (mediaIntervaloIa != $none) #mediaIntervaloIa: mediaIntervaloIa,
      if (previsaoRetornoCio != $none) #previsaoRetornoCio: previsaoRetornoCio,
      if (delPrimeiraIa != $none) #delPrimeiraIa: delPrimeiraIa,
      if (periodoServico != $none) #periodoServico: periodoServico,
      if (diasParaSecar != $none) #diasParaSecar: diasParaSecar,
      if (previsaoSecagem != $none) #previsaoSecagem: previsaoSecagem,
      if (mesSecagem != $none) #mesSecagem: mesSecagem,
      if (diferencaSecagem != $none) #diferencaSecagem: diferencaSecagem,
      if (periodoLactacao != $none) #periodoLactacao: periodoLactacao,
      if (dataPreParto != $none) #dataPreParto: dataPreParto,
      if (mesPreParto != $none) #mesPreParto: mesPreParto,
      if (duracaoPreParto != $none) #duracaoPreParto: duracaoPreParto,
      if (previsaoParto != $none) #previsaoParto: previsaoParto,
      if (mesPrevistoParto != $none) #mesPrevistoParto: mesPrevistoParto,
      if (iepProjetado != $none) #iepProjetado: iepProjetado,
      if (controleLeiteiroComDesconto != $none)
        #controleLeiteiroComDesconto: controleLeiteiroComDesconto,
    }),
  );
  @override
  VisitAnimalEntryModel $make(CopyWithData data) => VisitAnimalEntryModel(
    animalId: data.get(#animalId, or: $value.animalId),
    animalIdExterno: data.get(#animalIdExterno, or: $value.animalIdExterno),
    animalCodigo: data.get(#animalCodigo, or: $value.animalCodigo),
    animalCategoria: data.get(#animalCategoria, or: $value.animalCategoria),
    idadeMeses: data.get(#idadeMeses, or: $value.idadeMeses),
    dataNascimento: data.get(#dataNascimento, or: $value.dataNascimento),
    situacaoProdutiva: data.get(
      #situacaoProdutiva,
      or: $value.situacaoProdutiva,
    ),
    situacaoReprodutiva: data.get(
      #situacaoReprodutiva,
      or: $value.situacaoReprodutiva,
    ),
    decisao: data.get(#decisao, or: $value.decisao),
    dataPrimeiroParto: data.get(
      #dataPrimeiroParto,
      or: $value.dataPrimeiroParto,
    ),
    dataUltimoParto: data.get(#dataUltimoParto, or: $value.dataUltimoParto),
    dataPartoAnterior: data.get(
      #dataPartoAnterior,
      or: $value.dataPartoAnterior,
    ),
    numeroPartos: data.get(#numeroPartos, or: $value.numeroPartos),
    dataPrimeiraIa: data.get(#dataPrimeiraIa, or: $value.dataPrimeiraIa),
    dataSegundaIa: data.get(#dataSegundaIa, or: $value.dataSegundaIa),
    dataTerceiraIa: data.get(#dataTerceiraIa, or: $value.dataTerceiraIa),
    dataQuartaIa: data.get(#dataQuartaIa, or: $value.dataQuartaIa),
    dataQuintaIa: data.get(#dataQuintaIa, or: $value.dataQuintaIa),
    dataUltimaIa: data.get(#dataUltimaIa, or: $value.dataUltimaIa),
    numeroIaRecebida: data.get(#numeroIaRecebida, or: $value.numeroIaRecebida),
    dataSecagemEfetiva: data.get(
      #dataSecagemEfetiva,
      or: $value.dataSecagemEfetiva,
    ),
    entradaPreParto: data.get(#entradaPreParto, or: $value.entradaPreParto),
    controleLeiteiro: data.get(#controleLeiteiro, or: $value.controleLeiteiro),
    diasPrenhez: data.get(#diasPrenhez, or: $value.diasPrenhez),
    diagnostico: data.get(#diagnostico, or: $value.diagnostico),
    del: data.get(#del, or: $value.del),
    idadePrimeiroPartoMeses: data.get(
      #idadePrimeiroPartoMeses,
      or: $value.idadePrimeiroPartoMeses,
    ),
    idadePrimeiraIa: data.get(#idadePrimeiraIa, or: $value.idadePrimeiraIa),
    mesParto: data.get(#mesParto, or: $value.mesParto),
    anoUltimoParto: data.get(#anoUltimoParto, or: $value.anoUltimoParto),
    iepAtual: data.get(#iepAtual, or: $value.iepAtual),
    classificacaoPartos: data.get(
      #classificacaoPartos,
      or: $value.classificacaoPartos,
    ),
    vacaApta: data.get(#vacaApta, or: $value.vacaApta),
    intervalo1e2Ia: data.get(#intervalo1e2Ia, or: $value.intervalo1e2Ia),
    intervalo2e3Ia: data.get(#intervalo2e3Ia, or: $value.intervalo2e3Ia),
    intervalo3e4Ia: data.get(#intervalo3e4Ia, or: $value.intervalo3e4Ia),
    intervalo4e5Ia: data.get(#intervalo4e5Ia, or: $value.intervalo4e5Ia),
    mediaIntervaloIa: data.get(#mediaIntervaloIa, or: $value.mediaIntervaloIa),
    previsaoRetornoCio: data.get(
      #previsaoRetornoCio,
      or: $value.previsaoRetornoCio,
    ),
    delPrimeiraIa: data.get(#delPrimeiraIa, or: $value.delPrimeiraIa),
    periodoServico: data.get(#periodoServico, or: $value.periodoServico),
    diasParaSecar: data.get(#diasParaSecar, or: $value.diasParaSecar),
    previsaoSecagem: data.get(#previsaoSecagem, or: $value.previsaoSecagem),
    mesSecagem: data.get(#mesSecagem, or: $value.mesSecagem),
    diferencaSecagem: data.get(#diferencaSecagem, or: $value.diferencaSecagem),
    periodoLactacao: data.get(#periodoLactacao, or: $value.periodoLactacao),
    dataPreParto: data.get(#dataPreParto, or: $value.dataPreParto),
    mesPreParto: data.get(#mesPreParto, or: $value.mesPreParto),
    duracaoPreParto: data.get(#duracaoPreParto, or: $value.duracaoPreParto),
    previsaoParto: data.get(#previsaoParto, or: $value.previsaoParto),
    mesPrevistoParto: data.get(#mesPrevistoParto, or: $value.mesPrevistoParto),
    iepProjetado: data.get(#iepProjetado, or: $value.iepProjetado),
    controleLeiteiroComDesconto: data.get(
      #controleLeiteiroComDesconto,
      or: $value.controleLeiteiroComDesconto,
    ),
  );

  @override
  VisitAnimalEntryModelCopyWith<$R2, VisitAnimalEntryModel, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _VisitAnimalEntryModelCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

