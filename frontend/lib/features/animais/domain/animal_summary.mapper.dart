// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'animal_summary.dart';

class AnimalSummaryMapper extends ClassMapperBase<AnimalSummary> {
  AnimalSummaryMapper._();

  static AnimalSummaryMapper? _instance;
  static AnimalSummaryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AnimalSummaryMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'AnimalSummary';

  static int _$id(AnimalSummary v) => v.id;
  static const Field<AnimalSummary, int> _f$id = Field(
    'id',
    _$id,
    opt: true,
    def: 0,
  );
  static String _$idExterno(AnimalSummary v) => v.idExterno;
  static const Field<AnimalSummary, String> _f$idExterno = Field(
    'idExterno',
    _$idExterno,
    opt: true,
    def: '',
  );
  static int _$idPropriedade(AnimalSummary v) => v.idPropriedade;
  static const Field<AnimalSummary, int> _f$idPropriedade = Field(
    'idPropriedade',
    _$idPropriedade,
    opt: true,
    def: 0,
  );
  static String _$idExternoPropriedade(AnimalSummary v) =>
      v.idExternoPropriedade;
  static const Field<AnimalSummary, String> _f$idExternoPropriedade = Field(
    'idExternoPropriedade',
    _$idExternoPropriedade,
    opt: true,
    def: '',
  );
  static String _$codigo(AnimalSummary v) => v.codigo;
  static const Field<AnimalSummary, String> _f$codigo = Field(
    'codigo',
    _$codigo,
    opt: true,
    def: '',
  );
  static String _$categoria(AnimalSummary v) => v.categoria;
  static const Field<AnimalSummary, String> _f$categoria = Field(
    'categoria',
    _$categoria,
    opt: true,
    def: '',
  );
  static DateTime? _$dataNascimento(AnimalSummary v) => v.dataNascimento;
  static const Field<AnimalSummary, DateTime> _f$dataNascimento = Field(
    'dataNascimento',
    _$dataNascimento,
    opt: true,
    hook: _NullableDateTimeHook(),
  );
  static int _$numeroLactacao(AnimalSummary v) => v.numeroLactacao;
  static const Field<AnimalSummary, int> _f$numeroLactacao = Field(
    'numeroLactacao',
    _$numeroLactacao,
    opt: true,
    def: 0,
  );
  static DateTime? _$dataUltimoParto(AnimalSummary v) => v.dataUltimoParto;
  static const Field<AnimalSummary, DateTime> _f$dataUltimoParto = Field(
    'dataUltimoParto',
    _$dataUltimoParto,
    opt: true,
    hook: _NullableDateTimeHook(),
  );
  static int? _$diasEmLactacao(AnimalSummary v) => v.diasEmLactacao;
  static const Field<AnimalSummary, int> _f$diasEmLactacao = Field(
    'diasEmLactacao',
    _$diasEmLactacao,
    opt: true,
  );
  static String? _$historicoReprodutivo(AnimalSummary v) =>
      v.historicoReprodutivo;
  static const Field<AnimalSummary, String> _f$historicoReprodutivo = Field(
    'historicoReprodutivo',
    _$historicoReprodutivo,
    opt: true,
  );

  @override
  final MappableFields<AnimalSummary> fields = const {
    #id: _f$id,
    #idExterno: _f$idExterno,
    #idPropriedade: _f$idPropriedade,
    #idExternoPropriedade: _f$idExternoPropriedade,
    #codigo: _f$codigo,
    #categoria: _f$categoria,
    #dataNascimento: _f$dataNascimento,
    #numeroLactacao: _f$numeroLactacao,
    #dataUltimoParto: _f$dataUltimoParto,
    #diasEmLactacao: _f$diasEmLactacao,
    #historicoReprodutivo: _f$historicoReprodutivo,
  };

  static AnimalSummary _instantiate(DecodingData data) {
    return AnimalSummary(
      id: data.dec(_f$id),
      idExterno: data.dec(_f$idExterno),
      idPropriedade: data.dec(_f$idPropriedade),
      idExternoPropriedade: data.dec(_f$idExternoPropriedade),
      codigo: data.dec(_f$codigo),
      categoria: data.dec(_f$categoria),
      dataNascimento: data.dec(_f$dataNascimento),
      numeroLactacao: data.dec(_f$numeroLactacao),
      dataUltimoParto: data.dec(_f$dataUltimoParto),
      diasEmLactacao: data.dec(_f$diasEmLactacao),
      historicoReprodutivo: data.dec(_f$historicoReprodutivo),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static AnimalSummary fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<AnimalSummary>(map);
  }

  static AnimalSummary fromJson(String json) {
    return ensureInitialized().decodeJson<AnimalSummary>(json);
  }
}

mixin AnimalSummaryMappable {
  String toJson() {
    return AnimalSummaryMapper.ensureInitialized().encodeJson<AnimalSummary>(
      this as AnimalSummary,
    );
  }

  Map<String, dynamic> toMap() {
    return AnimalSummaryMapper.ensureInitialized().encodeMap<AnimalSummary>(
      this as AnimalSummary,
    );
  }

  AnimalSummaryCopyWith<AnimalSummary, AnimalSummary, AnimalSummary>
  get copyWith => _AnimalSummaryCopyWithImpl<AnimalSummary, AnimalSummary>(
    this as AnimalSummary,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return AnimalSummaryMapper.ensureInitialized().stringifyValue(
      this as AnimalSummary,
    );
  }

  @override
  bool operator ==(Object other) {
    return AnimalSummaryMapper.ensureInitialized().equalsValue(
      this as AnimalSummary,
      other,
    );
  }

  @override
  int get hashCode {
    return AnimalSummaryMapper.ensureInitialized().hashValue(
      this as AnimalSummary,
    );
  }
}

extension AnimalSummaryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, AnimalSummary, $Out> {
  AnimalSummaryCopyWith<$R, AnimalSummary, $Out> get $asAnimalSummary =>
      $base.as((v, t, t2) => _AnimalSummaryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class AnimalSummaryCopyWith<$R, $In extends AnimalSummary, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    int? id,
    String? idExterno,
    int? idPropriedade,
    String? idExternoPropriedade,
    String? codigo,
    String? categoria,
    DateTime? dataNascimento,
    int? numeroLactacao,
    DateTime? dataUltimoParto,
    int? diasEmLactacao,
    String? historicoReprodutivo,
  });
  AnimalSummaryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _AnimalSummaryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, AnimalSummary, $Out>
    implements AnimalSummaryCopyWith<$R, AnimalSummary, $Out> {
  _AnimalSummaryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<AnimalSummary> $mapper =
      AnimalSummaryMapper.ensureInitialized();
  @override
  $R call({
    int? id,
    String? idExterno,
    int? idPropriedade,
    String? idExternoPropriedade,
    String? codigo,
    String? categoria,
    Object? dataNascimento = $none,
    int? numeroLactacao,
    Object? dataUltimoParto = $none,
    Object? diasEmLactacao = $none,
    Object? historicoReprodutivo = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (idExterno != null) #idExterno: idExterno,
      if (idPropriedade != null) #idPropriedade: idPropriedade,
      if (idExternoPropriedade != null)
        #idExternoPropriedade: idExternoPropriedade,
      if (codigo != null) #codigo: codigo,
      if (categoria != null) #categoria: categoria,
      if (dataNascimento != $none) #dataNascimento: dataNascimento,
      if (numeroLactacao != null) #numeroLactacao: numeroLactacao,
      if (dataUltimoParto != $none) #dataUltimoParto: dataUltimoParto,
      if (diasEmLactacao != $none) #diasEmLactacao: diasEmLactacao,
      if (historicoReprodutivo != $none)
        #historicoReprodutivo: historicoReprodutivo,
    }),
  );
  @override
  AnimalSummary $make(CopyWithData data) => AnimalSummary(
    id: data.get(#id, or: $value.id),
    idExterno: data.get(#idExterno, or: $value.idExterno),
    idPropriedade: data.get(#idPropriedade, or: $value.idPropriedade),
    idExternoPropriedade: data.get(
      #idExternoPropriedade,
      or: $value.idExternoPropriedade,
    ),
    codigo: data.get(#codigo, or: $value.codigo),
    categoria: data.get(#categoria, or: $value.categoria),
    dataNascimento: data.get(#dataNascimento, or: $value.dataNascimento),
    numeroLactacao: data.get(#numeroLactacao, or: $value.numeroLactacao),
    dataUltimoParto: data.get(#dataUltimoParto, or: $value.dataUltimoParto),
    diasEmLactacao: data.get(#diasEmLactacao, or: $value.diasEmLactacao),
    historicoReprodutivo: data.get(
      #historicoReprodutivo,
      or: $value.historicoReprodutivo,
    ),
  );

  @override
  AnimalSummaryCopyWith<$R2, AnimalSummary, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _AnimalSummaryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

