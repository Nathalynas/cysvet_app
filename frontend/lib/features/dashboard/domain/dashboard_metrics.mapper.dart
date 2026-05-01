// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'dashboard_metrics.dart';

class DashboardMetricsMapper extends ClassMapperBase<DashboardMetrics> {
  DashboardMetricsMapper._();

  static DashboardMetricsMapper? _instance;
  static DashboardMetricsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DashboardMetricsMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'DashboardMetrics';

  static int _$totalPropriedades(DashboardMetrics v) => v.totalPropriedades;
  static const Field<DashboardMetrics, int> _f$totalPropriedades = Field(
    'totalPropriedades',
    _$totalPropriedades,
    opt: true,
    def: 0,
  );
  static int _$totalAnimais(DashboardMetrics v) => v.totalAnimais;
  static const Field<DashboardMetrics, int> _f$totalAnimais = Field(
    'totalAnimais',
    _$totalAnimais,
    opt: true,
    def: 0,
  );
  static int _$totalEventos(DashboardMetrics v) => v.totalEventos;
  static const Field<DashboardMetrics, int> _f$totalEventos = Field(
    'totalEventos',
    _$totalEventos,
    opt: true,
    def: 0,
  );
  static double _$taxaPrenhez(DashboardMetrics v) => v.taxaPrenhez;
  static const Field<DashboardMetrics, double> _f$taxaPrenhez = Field(
    'taxaPrenhez',
    _$taxaPrenhez,
    opt: true,
    def: 0.0,
  );
  static double _$taxaServico(DashboardMetrics v) => v.taxaServico;
  static const Field<DashboardMetrics, double> _f$taxaServico = Field(
    'taxaServico',
    _$taxaServico,
    opt: true,
    def: 0.0,
  );
  static double _$mediaInseminacoes(DashboardMetrics v) => v.mediaInseminacoes;
  static const Field<DashboardMetrics, double> _f$mediaInseminacoes = Field(
    'mediaInseminacoes',
    _$mediaInseminacoes,
    opt: true,
    def: 0.0,
  );
  static double _$intervaloMedioPartos(DashboardMetrics v) =>
      v.intervaloMedioPartos;
  static const Field<DashboardMetrics, double> _f$intervaloMedioPartos = Field(
    'intervaloMedioPartos',
    _$intervaloMedioPartos,
    opt: true,
    def: 0.0,
  );

  @override
  final MappableFields<DashboardMetrics> fields = const {
    #totalPropriedades: _f$totalPropriedades,
    #totalAnimais: _f$totalAnimais,
    #totalEventos: _f$totalEventos,
    #taxaPrenhez: _f$taxaPrenhez,
    #taxaServico: _f$taxaServico,
    #mediaInseminacoes: _f$mediaInseminacoes,
    #intervaloMedioPartos: _f$intervaloMedioPartos,
  };

  static DashboardMetrics _instantiate(DecodingData data) {
    return DashboardMetrics(
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

  static DashboardMetrics fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DashboardMetrics>(map);
  }

  static DashboardMetrics fromJson(String json) {
    return ensureInitialized().decodeJson<DashboardMetrics>(json);
  }
}

mixin DashboardMetricsMappable {
  String toJson() {
    return DashboardMetricsMapper.ensureInitialized()
        .encodeJson<DashboardMetrics>(this as DashboardMetrics);
  }

  Map<String, dynamic> toMap() {
    return DashboardMetricsMapper.ensureInitialized()
        .encodeMap<DashboardMetrics>(this as DashboardMetrics);
  }

  DashboardMetricsCopyWith<DashboardMetrics, DashboardMetrics, DashboardMetrics>
  get copyWith =>
      _DashboardMetricsCopyWithImpl<DashboardMetrics, DashboardMetrics>(
        this as DashboardMetrics,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return DashboardMetricsMapper.ensureInitialized().stringifyValue(
      this as DashboardMetrics,
    );
  }

  @override
  bool operator ==(Object other) {
    return DashboardMetricsMapper.ensureInitialized().equalsValue(
      this as DashboardMetrics,
      other,
    );
  }

  @override
  int get hashCode {
    return DashboardMetricsMapper.ensureInitialized().hashValue(
      this as DashboardMetrics,
    );
  }
}

extension DashboardMetricsValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DashboardMetrics, $Out> {
  DashboardMetricsCopyWith<$R, DashboardMetrics, $Out>
  get $asDashboardMetrics =>
      $base.as((v, t, t2) => _DashboardMetricsCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class DashboardMetricsCopyWith<$R, $In extends DashboardMetrics, $Out>
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
  DashboardMetricsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _DashboardMetricsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DashboardMetrics, $Out>
    implements DashboardMetricsCopyWith<$R, DashboardMetrics, $Out> {
  _DashboardMetricsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DashboardMetrics> $mapper =
      DashboardMetricsMapper.ensureInitialized();
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
  DashboardMetrics $make(CopyWithData data) => DashboardMetrics(
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
  DashboardMetricsCopyWith<$R2, DashboardMetrics, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _DashboardMetricsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

