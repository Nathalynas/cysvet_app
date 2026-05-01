// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'visit_summary.dart';

class VisitSummaryMapper extends ClassMapperBase<VisitSummary> {
  VisitSummaryMapper._();

  static VisitSummaryMapper? _instance;
  static VisitSummaryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = VisitSummaryMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'VisitSummary';

  static int _$id(VisitSummary v) => v.id;
  static const Field<VisitSummary, int> _f$id = Field(
    'id',
    _$id,
    opt: true,
    def: 0,
  );
  static String _$idExterno(VisitSummary v) => v.idExterno;
  static const Field<VisitSummary, String> _f$idExterno = Field(
    'idExterno',
    _$idExterno,
    opt: true,
    def: '',
  );
  static int _$idPropriedade(VisitSummary v) => v.idPropriedade;
  static const Field<VisitSummary, int> _f$idPropriedade = Field(
    'idPropriedade',
    _$idPropriedade,
    opt: true,
    def: 0,
  );
  static String _$idExternoPropriedade(VisitSummary v) =>
      v.idExternoPropriedade;
  static const Field<VisitSummary, String> _f$idExternoPropriedade = Field(
    'idExternoPropriedade',
    _$idExternoPropriedade,
    opt: true,
    def: '',
  );
  static DateTime? _$dataVisita(VisitSummary v) => v.dataVisita;
  static const Field<VisitSummary, DateTime> _f$dataVisita = Field(
    'dataVisita',
    _$dataVisita,
    opt: true,
    hook: _NullableDateTimeHook(),
  );
  static String? _$observacoes(VisitSummary v) => v.observacoes;
  static const Field<VisitSummary, String> _f$observacoes = Field(
    'observacoes',
    _$observacoes,
    opt: true,
  );

  @override
  final MappableFields<VisitSummary> fields = const {
    #id: _f$id,
    #idExterno: _f$idExterno,
    #idPropriedade: _f$idPropriedade,
    #idExternoPropriedade: _f$idExternoPropriedade,
    #dataVisita: _f$dataVisita,
    #observacoes: _f$observacoes,
  };

  static VisitSummary _instantiate(DecodingData data) {
    return VisitSummary(
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

  static VisitSummary fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<VisitSummary>(map);
  }

  static VisitSummary fromJson(String json) {
    return ensureInitialized().decodeJson<VisitSummary>(json);
  }
}

mixin VisitSummaryMappable {
  String toJson() {
    return VisitSummaryMapper.ensureInitialized().encodeJson<VisitSummary>(
      this as VisitSummary,
    );
  }

  Map<String, dynamic> toMap() {
    return VisitSummaryMapper.ensureInitialized().encodeMap<VisitSummary>(
      this as VisitSummary,
    );
  }

  VisitSummaryCopyWith<VisitSummary, VisitSummary, VisitSummary> get copyWith =>
      _VisitSummaryCopyWithImpl<VisitSummary, VisitSummary>(
        this as VisitSummary,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return VisitSummaryMapper.ensureInitialized().stringifyValue(
      this as VisitSummary,
    );
  }

  @override
  bool operator ==(Object other) {
    return VisitSummaryMapper.ensureInitialized().equalsValue(
      this as VisitSummary,
      other,
    );
  }

  @override
  int get hashCode {
    return VisitSummaryMapper.ensureInitialized().hashValue(
      this as VisitSummary,
    );
  }
}

extension VisitSummaryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, VisitSummary, $Out> {
  VisitSummaryCopyWith<$R, VisitSummary, $Out> get $asVisitSummary =>
      $base.as((v, t, t2) => _VisitSummaryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class VisitSummaryCopyWith<$R, $In extends VisitSummary, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    int? id,
    String? idExterno,
    int? idPropriedade,
    String? idExternoPropriedade,
    DateTime? dataVisita,
    String? observacoes,
  });
  VisitSummaryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _VisitSummaryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, VisitSummary, $Out>
    implements VisitSummaryCopyWith<$R, VisitSummary, $Out> {
  _VisitSummaryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<VisitSummary> $mapper =
      VisitSummaryMapper.ensureInitialized();
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
  VisitSummary $make(CopyWithData data) => VisitSummary(
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
  VisitSummaryCopyWith<$R2, VisitSummary, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _VisitSummaryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

