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

  @override
  final MappableFields<VisitSummaryModel> fields = const {
    #id: _f$id,
    #idExterno: _f$idExterno,
    #idPropriedade: _f$idPropriedade,
    #idExternoPropriedade: _f$idExternoPropriedade,
    #dataVisita: _f$dataVisita,
    #observacoes: _f$observacoes,
  };

  static VisitSummaryModel _instantiate(DecodingData data) {
    return VisitSummaryModel(
      id: data.dec(_f$id),
      idExterno: data.dec(_f$idExterno),
      idPropriedade: data.dec(_f$idPropriedade),
      idExternoPropriedade: data.dec(_f$idExternoPropriedade),
      dataVisita: data.dec(_f$dataVisita),
      observacoes: data.dec(_f$observacoes),
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
  $R call({
    int? id,
    String? idExterno,
    int? idPropriedade,
    String? idExternoPropriedade,
    DateTime? dataVisita,
    String? observacoes,
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
  $R call({
    int? id,
    String? idExterno,
    int? idPropriedade,
    String? idExternoPropriedade,
    Object? dataVisita = $none,
    Object? observacoes = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (idExterno != null) #idExterno: idExterno,
      if (idPropriedade != null) #idPropriedade: idPropriedade,
      if (idExternoPropriedade != null)
        #idExternoPropriedade: idExternoPropriedade,
      if (dataVisita != $none) #dataVisita: dataVisita,
      if (observacoes != $none) #observacoes: observacoes,
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
  );

  @override
  VisitSummaryModelCopyWith<$R2, VisitSummaryModel, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _VisitSummaryModelCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

