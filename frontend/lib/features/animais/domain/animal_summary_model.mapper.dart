// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'animal_summary_model.dart';

class AnimalSummaryModelMapper extends ClassMapperBase<AnimalSummaryModel> {
  AnimalSummaryModelMapper._();

  static AnimalSummaryModelMapper? _instance;
  static AnimalSummaryModelMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AnimalSummaryModelMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'AnimalSummaryModel';

  static int _$id(AnimalSummaryModel v) => v.id;
  static const Field<AnimalSummaryModel, int> _f$id = Field(
    'id',
    _$id,
    opt: true,
    def: 0,
  );
  static String _$idExterno(AnimalSummaryModel v) => v.idExterno;
  static const Field<AnimalSummaryModel, String> _f$idExterno = Field(
    'idExterno',
    _$idExterno,
    opt: true,
    def: '',
  );
  static int _$idPropriedade(AnimalSummaryModel v) => v.idPropriedade;
  static const Field<AnimalSummaryModel, int> _f$idPropriedade = Field(
    'idPropriedade',
    _$idPropriedade,
    opt: true,
    def: 0,
  );
  static String _$idExternoPropriedade(AnimalSummaryModel v) =>
      v.idExternoPropriedade;
  static const Field<AnimalSummaryModel, String> _f$idExternoPropriedade =
      Field('idExternoPropriedade', _$idExternoPropriedade, opt: true, def: '');
  static String _$codigo(AnimalSummaryModel v) => v.codigo;
  static const Field<AnimalSummaryModel, String> _f$codigo = Field(
    'codigo',
    _$codigo,
    opt: true,
    def: '',
  );
  static String _$categoria(AnimalSummaryModel v) => v.categoria;
  static const Field<AnimalSummaryModel, String> _f$categoria = Field(
    'categoria',
    _$categoria,
    opt: true,
    def: '',
  );
  static DateTime? _$dataNascimento(AnimalSummaryModel v) => v.dataNascimento;
  static const Field<AnimalSummaryModel, DateTime> _f$dataNascimento = Field(
    'dataNascimento',
    _$dataNascimento,
    opt: true,
    hook: _NullableDateTimeHook(),
  );
  static int _$numeroLactacao(AnimalSummaryModel v) => v.numeroLactacao;
  static const Field<AnimalSummaryModel, int> _f$numeroLactacao = Field(
    'numeroLactacao',
    _$numeroLactacao,
    opt: true,
    def: 0,
  );
  static DateTime? _$dataUltimoParto(AnimalSummaryModel v) => v.dataUltimoParto;
  static const Field<AnimalSummaryModel, DateTime> _f$dataUltimoParto = Field(
    'dataUltimoParto',
    _$dataUltimoParto,
    opt: true,
    hook: _NullableDateTimeHook(),
  );
  static int? _$diasEmLactacao(AnimalSummaryModel v) => v.diasEmLactacao;
  static const Field<AnimalSummaryModel, int> _f$diasEmLactacao = Field(
    'diasEmLactacao',
    _$diasEmLactacao,
    opt: true,
  );
  static String? _$historicoReprodutivo(AnimalSummaryModel v) =>
      v.historicoReprodutivo;
  static const Field<AnimalSummaryModel, String> _f$historicoReprodutivo =
      Field('historicoReprodutivo', _$historicoReprodutivo, opt: true);

  @override
  final MappableFields<AnimalSummaryModel> fields = const {
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

  static AnimalSummaryModel _instantiate(DecodingData data) {
    return AnimalSummaryModel(
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

  static AnimalSummaryModel fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<AnimalSummaryModel>(map);
  }

  static AnimalSummaryModel fromJson(String json) {
    return ensureInitialized().decodeJson<AnimalSummaryModel>(json);
  }
}

mixin AnimalSummaryModelMappable {
  String toJson() {
    return AnimalSummaryModelMapper.ensureInitialized()
        .encodeJson<AnimalSummaryModel>(this as AnimalSummaryModel);
  }

  Map<String, dynamic> toMap() {
    return AnimalSummaryModelMapper.ensureInitialized()
        .encodeMap<AnimalSummaryModel>(this as AnimalSummaryModel);
  }

  AnimalSummaryModelCopyWith<
    AnimalSummaryModel,
    AnimalSummaryModel,
    AnimalSummaryModel
  >
  get copyWith =>
      _AnimalSummaryModelCopyWithImpl<AnimalSummaryModel, AnimalSummaryModel>(
        this as AnimalSummaryModel,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return AnimalSummaryModelMapper.ensureInitialized().stringifyValue(
      this as AnimalSummaryModel,
    );
  }

  @override
  bool operator ==(Object other) {
    return AnimalSummaryModelMapper.ensureInitialized().equalsValue(
      this as AnimalSummaryModel,
      other,
    );
  }

  @override
  int get hashCode {
    return AnimalSummaryModelMapper.ensureInitialized().hashValue(
      this as AnimalSummaryModel,
    );
  }
}

extension AnimalSummaryModelValueCopy<$R, $Out>
    on ObjectCopyWith<$R, AnimalSummaryModel, $Out> {
  AnimalSummaryModelCopyWith<$R, AnimalSummaryModel, $Out>
  get $asAnimalSummaryModel => $base.as(
    (v, t, t2) => _AnimalSummaryModelCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class AnimalSummaryModelCopyWith<
  $R,
  $In extends AnimalSummaryModel,
  $Out
>
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
  AnimalSummaryModelCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _AnimalSummaryModelCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, AnimalSummaryModel, $Out>
    implements AnimalSummaryModelCopyWith<$R, AnimalSummaryModel, $Out> {
  _AnimalSummaryModelCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<AnimalSummaryModel> $mapper =
      AnimalSummaryModelMapper.ensureInitialized();
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
  AnimalSummaryModel $make(CopyWithData data) => AnimalSummaryModel(
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
  AnimalSummaryModelCopyWith<$R2, AnimalSummaryModel, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _AnimalSummaryModelCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

