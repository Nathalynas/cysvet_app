// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'dashboard_metrics_model.dart';

class DashboardMetricsModelMapper
    extends ClassMapperBase<DashboardMetricsModel> {
  DashboardMetricsModelMapper._();

  static DashboardMetricsModelMapper? _instance;
  static DashboardMetricsModelMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DashboardMetricsModelMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'DashboardMetricsModel';

  static int _$totalPropriedades(DashboardMetricsModel v) =>
      v.totalPropriedades;
  static const Field<DashboardMetricsModel, int> _f$totalPropriedades = Field(
    'totalPropriedades',
    _$totalPropriedades,
    opt: true,
    def: 0,
  );
  static int _$totalAnimais(DashboardMetricsModel v) => v.totalAnimais;
  static const Field<DashboardMetricsModel, int> _f$totalAnimais = Field(
    'totalAnimais',
    _$totalAnimais,
    opt: true,
    def: 0,
  );
  static int _$totalEventos(DashboardMetricsModel v) => v.totalEventos;
  static const Field<DashboardMetricsModel, int> _f$totalEventos = Field(
    'totalEventos',
    _$totalEventos,
    opt: true,
    def: 0,
  );
  static double _$taxaPrenhez(DashboardMetricsModel v) => v.taxaPrenhez;
  static const Field<DashboardMetricsModel, double> _f$taxaPrenhez = Field(
    'taxaPrenhez',
    _$taxaPrenhez,
    opt: true,
    def: 0.0,
  );
  static double _$taxaServico(DashboardMetricsModel v) => v.taxaServico;
  static const Field<DashboardMetricsModel, double> _f$taxaServico = Field(
    'taxaServico',
    _$taxaServico,
    opt: true,
    def: 0.0,
  );
  static double _$mediaInseminacoes(DashboardMetricsModel v) =>
      v.mediaInseminacoes;
  static const Field<DashboardMetricsModel, double> _f$mediaInseminacoes =
      Field('mediaInseminacoes', _$mediaInseminacoes, opt: true, def: 0.0);
  static double _$intervaloMedioPartos(DashboardMetricsModel v) =>
      v.intervaloMedioPartos;
  static const Field<DashboardMetricsModel, double> _f$intervaloMedioPartos =
      Field(
        'intervaloMedioPartos',
        _$intervaloMedioPartos,
        opt: true,
        def: 0.0,
      );

  @override
  final MappableFields<DashboardMetricsModel> fields = const {
    #totalPropriedades: _f$totalPropriedades,
    #totalAnimais: _f$totalAnimais,
    #totalEventos: _f$totalEventos,
    #taxaPrenhez: _f$taxaPrenhez,
    #taxaServico: _f$taxaServico,
    #mediaInseminacoes: _f$mediaInseminacoes,
    #intervaloMedioPartos: _f$intervaloMedioPartos,
  };

  static DashboardMetricsModel _instantiate(DecodingData data) {
    return DashboardMetricsModel(
      totalPropriedades: data.dec(_f$totalPropriedades),
      totalAnimais: data.dec(_f$totalAnimais),
      totalEventos: data.dec(_f$totalEventos),
      taxaPrenhez: data.dec(_f$taxaPrenhez),
      taxaServico: data.dec(_f$taxaServico),
      mediaInseminacoes: data.dec(_f$mediaInseminacoes),
      intervaloMedioPartos: data.dec(_f$intervaloMedioPartos),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static DashboardMetricsModel fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DashboardMetricsModel>(map);
  }

  static DashboardMetricsModel fromJson(String json) {
    return ensureInitialized().decodeJson<DashboardMetricsModel>(json);
  }
}

mixin DashboardMetricsModelMappable {
  String toJson() {
    return DashboardMetricsModelMapper.ensureInitialized()
        .encodeJson<DashboardMetricsModel>(this as DashboardMetricsModel);
  }

  Map<String, dynamic> toMap() {
    return DashboardMetricsModelMapper.ensureInitialized()
        .encodeMap<DashboardMetricsModel>(this as DashboardMetricsModel);
  }

  DashboardMetricsModelCopyWith<
    DashboardMetricsModel,
    DashboardMetricsModel,
    DashboardMetricsModel
  >
  get copyWith =>
      _DashboardMetricsModelCopyWithImpl<
        DashboardMetricsModel,
        DashboardMetricsModel
      >(this as DashboardMetricsModel, $identity, $identity);
  @override
  String toString() {
    return DashboardMetricsModelMapper.ensureInitialized().stringifyValue(
      this as DashboardMetricsModel,
    );
  }

  @override
  bool operator ==(Object other) {
    return DashboardMetricsModelMapper.ensureInitialized().equalsValue(
      this as DashboardMetricsModel,
      other,
    );
  }

  @override
  int get hashCode {
    return DashboardMetricsModelMapper.ensureInitialized().hashValue(
      this as DashboardMetricsModel,
    );
  }
}

extension DashboardMetricsModelValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DashboardMetricsModel, $Out> {
  DashboardMetricsModelCopyWith<$R, DashboardMetricsModel, $Out>
  get $asDashboardMetricsModel => $base.as(
    (v, t, t2) => _DashboardMetricsModelCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class DashboardMetricsModelCopyWith<
  $R,
  $In extends DashboardMetricsModel,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    int? totalPropriedades,
    int? totalAnimais,
    int? totalEventos,
    double? taxaPrenhez,
    double? taxaServico,
    double? mediaInseminacoes,
    double? intervaloMedioPartos,
  });
  DashboardMetricsModelCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _DashboardMetricsModelCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DashboardMetricsModel, $Out>
    implements DashboardMetricsModelCopyWith<$R, DashboardMetricsModel, $Out> {
  _DashboardMetricsModelCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DashboardMetricsModel> $mapper =
      DashboardMetricsModelMapper.ensureInitialized();
  @override
  $R call({
    int? totalPropriedades,
    int? totalAnimais,
    int? totalEventos,
    double? taxaPrenhez,
    double? taxaServico,
    double? mediaInseminacoes,
    double? intervaloMedioPartos,
  }) => $apply(
    FieldCopyWithData({
      if (totalPropriedades != null) #totalPropriedades: totalPropriedades,
      if (totalAnimais != null) #totalAnimais: totalAnimais,
      if (totalEventos != null) #totalEventos: totalEventos,
      if (taxaPrenhez != null) #taxaPrenhez: taxaPrenhez,
      if (taxaServico != null) #taxaServico: taxaServico,
      if (mediaInseminacoes != null) #mediaInseminacoes: mediaInseminacoes,
      if (intervaloMedioPartos != null)
        #intervaloMedioPartos: intervaloMedioPartos,
    }),
  );
  @override
  DashboardMetricsModel $make(CopyWithData data) => DashboardMetricsModel(
    totalPropriedades: data.get(
      #totalPropriedades,
      or: $value.totalPropriedades,
    ),
    totalAnimais: data.get(#totalAnimais, or: $value.totalAnimais),
    totalEventos: data.get(#totalEventos, or: $value.totalEventos),
    taxaPrenhez: data.get(#taxaPrenhez, or: $value.taxaPrenhez),
    taxaServico: data.get(#taxaServico, or: $value.taxaServico),
    mediaInseminacoes: data.get(
      #mediaInseminacoes,
      or: $value.mediaInseminacoes,
    ),
    intervaloMedioPartos: data.get(
      #intervaloMedioPartos,
      or: $value.intervaloMedioPartos,
    ),
  );

  @override
  DashboardMetricsModelCopyWith<$R2, DashboardMetricsModel, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _DashboardMetricsModelCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

