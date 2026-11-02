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
      DashboardMonthlyRateModelMapper.ensureInitialized();
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
  static double? _$taxaConcepcao(DashboardMetricsModel v) => v.taxaConcepcao;
  static const Field<DashboardMetricsModel, double> _f$taxaConcepcao = Field(
    'taxaConcepcao',
    _$taxaConcepcao,
    opt: true,
  );
  static double? _$taxaConcepcaoIa(DashboardMetricsModel v) =>
      v.taxaConcepcaoIa;
  static const Field<DashboardMetricsModel, double> _f$taxaConcepcaoIa = Field(
    'taxaConcepcaoIa',
    _$taxaConcepcaoIa,
    opt: true,
  );
  static int _$ciclos(DashboardMetricsModel v) => v.ciclos;
  static const Field<DashboardMetricsModel, int> _f$ciclos = Field(
    'ciclos',
    _$ciclos,
    opt: true,
    def: 0,
  );
  static int _$aptas(DashboardMetricsModel v) => v.aptas;
  static const Field<DashboardMetricsModel, int> _f$aptas = Field(
    'aptas',
    _$aptas,
    opt: true,
    def: 0,
  );
  static int _$servidas(DashboardMetricsModel v) => v.servidas;
  static const Field<DashboardMetricsModel, int> _f$servidas = Field(
    'servidas',
    _$servidas,
    opt: true,
    def: 0,
  );
  static int _$concebidas(DashboardMetricsModel v) => v.concebidas;
  static const Field<DashboardMetricsModel, int> _f$concebidas = Field(
    'concebidas',
    _$concebidas,
    opt: true,
    def: 0,
  );
  static List<DashboardMonthlyRateModel> _$serieMensal(
    DashboardMetricsModel v,
  ) => v.serieMensal;
  static const Field<DashboardMetricsModel, List<DashboardMonthlyRateModel>>
  _f$serieMensal = Field(
    'serieMensal',
    _$serieMensal,
    opt: true,
    def: const [],
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
    #taxaConcepcao: _f$taxaConcepcao,
    #taxaConcepcaoIa: _f$taxaConcepcaoIa,
    #ciclos: _f$ciclos,
    #aptas: _f$aptas,
    #servidas: _f$servidas,
    #concebidas: _f$concebidas,
    #serieMensal: _f$serieMensal,
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
      taxaConcepcao: data.dec(_f$taxaConcepcao),
      taxaConcepcaoIa: data.dec(_f$taxaConcepcaoIa),
      ciclos: data.dec(_f$ciclos),
      aptas: data.dec(_f$aptas),
      servidas: data.dec(_f$servidas),
      concebidas: data.dec(_f$concebidas),
      serieMensal: data.dec(_f$serieMensal),
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
  ListCopyWith<
    $R,
    DashboardMonthlyRateModel,
    DashboardMonthlyRateModelCopyWith<
      $R,
      DashboardMonthlyRateModel,
      DashboardMonthlyRateModel
    >
  >
  get serieMensal;
  $R call({
    int? totalPropriedades,
    int? totalAnimais,
    int? totalEventos,
    double? taxaPrenhez,
    double? taxaServico,
    double? mediaInseminacoes,
    double? intervaloMedioPartos,
    double? taxaConcepcao,
    double? taxaConcepcaoIa,
    int? ciclos,
    int? aptas,
    int? servidas,
    int? concebidas,
    List<DashboardMonthlyRateModel>? serieMensal,
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
  ListCopyWith<
    $R,
    DashboardMonthlyRateModel,
    DashboardMonthlyRateModelCopyWith<
      $R,
      DashboardMonthlyRateModel,
      DashboardMonthlyRateModel
    >
  >
  get serieMensal => ListCopyWith(
    $value.serieMensal,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(serieMensal: v),
  );
  @override
  $R call({
    int? totalPropriedades,
    int? totalAnimais,
    int? totalEventos,
    double? taxaPrenhez,
    double? taxaServico,
    double? mediaInseminacoes,
    double? intervaloMedioPartos,
    Object? taxaConcepcao = $none,
    Object? taxaConcepcaoIa = $none,
    int? ciclos,
    int? aptas,
    int? servidas,
    int? concebidas,
    List<DashboardMonthlyRateModel>? serieMensal,
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
      if (taxaConcepcao != $none) #taxaConcepcao: taxaConcepcao,
      if (taxaConcepcaoIa != $none) #taxaConcepcaoIa: taxaConcepcaoIa,
      if (ciclos != null) #ciclos: ciclos,
      if (aptas != null) #aptas: aptas,
      if (servidas != null) #servidas: servidas,
      if (concebidas != null) #concebidas: concebidas,
      if (serieMensal != null) #serieMensal: serieMensal,
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
    taxaConcepcao: data.get(#taxaConcepcao, or: $value.taxaConcepcao),
    taxaConcepcaoIa: data.get(#taxaConcepcaoIa, or: $value.taxaConcepcaoIa),
    ciclos: data.get(#ciclos, or: $value.ciclos),
    aptas: data.get(#aptas, or: $value.aptas),
    servidas: data.get(#servidas, or: $value.servidas),
    concebidas: data.get(#concebidas, or: $value.concebidas),
    serieMensal: data.get(#serieMensal, or: $value.serieMensal),
  );

  @override
  DashboardMetricsModelCopyWith<$R2, DashboardMetricsModel, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _DashboardMetricsModelCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class DashboardMonthlyRateModelMapper
    extends ClassMapperBase<DashboardMonthlyRateModel> {
  DashboardMonthlyRateModelMapper._();

  static DashboardMonthlyRateModelMapper? _instance;
  static DashboardMonthlyRateModelMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = DashboardMonthlyRateModelMapper._(),
      );
    }
    return _instance!;
  }

  @override
  final String id = 'DashboardMonthlyRateModel';

  static String _$mes(DashboardMonthlyRateModel v) => v.mes;
  static const Field<DashboardMonthlyRateModel, String> _f$mes = Field(
    'mes',
    _$mes,
    opt: true,
    def: '',
  );
  static double? _$taxaServico(DashboardMonthlyRateModel v) => v.taxaServico;
  static const Field<DashboardMonthlyRateModel, double> _f$taxaServico = Field(
    'taxaServico',
    _$taxaServico,
    opt: true,
  );
  static double? _$taxaConcepcao(DashboardMonthlyRateModel v) =>
      v.taxaConcepcao;
  static const Field<DashboardMonthlyRateModel, double> _f$taxaConcepcao =
      Field('taxaConcepcao', _$taxaConcepcao, opt: true);
  static double? _$taxaPrenhez(DashboardMonthlyRateModel v) => v.taxaPrenhez;
  static const Field<DashboardMonthlyRateModel, double> _f$taxaPrenhez = Field(
    'taxaPrenhez',
    _$taxaPrenhez,
    opt: true,
  );

  @override
  final MappableFields<DashboardMonthlyRateModel> fields = const {
    #mes: _f$mes,
    #taxaServico: _f$taxaServico,
    #taxaConcepcao: _f$taxaConcepcao,
    #taxaPrenhez: _f$taxaPrenhez,
  };

  static DashboardMonthlyRateModel _instantiate(DecodingData data) {
    return DashboardMonthlyRateModel(
      mes: data.dec(_f$mes),
      taxaServico: data.dec(_f$taxaServico),
      taxaConcepcao: data.dec(_f$taxaConcepcao),
      taxaPrenhez: data.dec(_f$taxaPrenhez),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static DashboardMonthlyRateModel fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DashboardMonthlyRateModel>(map);
  }

  static DashboardMonthlyRateModel fromJson(String json) {
    return ensureInitialized().decodeJson<DashboardMonthlyRateModel>(json);
  }
}

mixin DashboardMonthlyRateModelMappable {
  String toJson() {
    return DashboardMonthlyRateModelMapper.ensureInitialized()
        .encodeJson<DashboardMonthlyRateModel>(
          this as DashboardMonthlyRateModel,
        );
  }

  Map<String, dynamic> toMap() {
    return DashboardMonthlyRateModelMapper.ensureInitialized()
        .encodeMap<DashboardMonthlyRateModel>(
          this as DashboardMonthlyRateModel,
        );
  }

  DashboardMonthlyRateModelCopyWith<
    DashboardMonthlyRateModel,
    DashboardMonthlyRateModel,
    DashboardMonthlyRateModel
  >
  get copyWith =>
      _DashboardMonthlyRateModelCopyWithImpl<
        DashboardMonthlyRateModel,
        DashboardMonthlyRateModel
      >(this as DashboardMonthlyRateModel, $identity, $identity);
  @override
  String toString() {
    return DashboardMonthlyRateModelMapper.ensureInitialized().stringifyValue(
      this as DashboardMonthlyRateModel,
    );
  }

  @override
  bool operator ==(Object other) {
    return DashboardMonthlyRateModelMapper.ensureInitialized().equalsValue(
      this as DashboardMonthlyRateModel,
      other,
    );
  }

  @override
  int get hashCode {
    return DashboardMonthlyRateModelMapper.ensureInitialized().hashValue(
      this as DashboardMonthlyRateModel,
    );
  }
}

extension DashboardMonthlyRateModelValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DashboardMonthlyRateModel, $Out> {
  DashboardMonthlyRateModelCopyWith<$R, DashboardMonthlyRateModel, $Out>
  get $asDashboardMonthlyRateModel => $base.as(
    (v, t, t2) => _DashboardMonthlyRateModelCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class DashboardMonthlyRateModelCopyWith<
  $R,
  $In extends DashboardMonthlyRateModel,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? mes,
    double? taxaServico,
    double? taxaConcepcao,
    double? taxaPrenhez,
  });
  DashboardMonthlyRateModelCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _DashboardMonthlyRateModelCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DashboardMonthlyRateModel, $Out>
    implements
        DashboardMonthlyRateModelCopyWith<$R, DashboardMonthlyRateModel, $Out> {
  _DashboardMonthlyRateModelCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DashboardMonthlyRateModel> $mapper =
      DashboardMonthlyRateModelMapper.ensureInitialized();
  @override
  $R call({
    String? mes,
    Object? taxaServico = $none,
    Object? taxaConcepcao = $none,
    Object? taxaPrenhez = $none,
  }) => $apply(
    FieldCopyWithData({
      if (mes != null) #mes: mes,
      if (taxaServico != $none) #taxaServico: taxaServico,
      if (taxaConcepcao != $none) #taxaConcepcao: taxaConcepcao,
      if (taxaPrenhez != $none) #taxaPrenhez: taxaPrenhez,
    }),
  );
  @override
  DashboardMonthlyRateModel $make(CopyWithData data) =>
      DashboardMonthlyRateModel(
        mes: data.get(#mes, or: $value.mes),
        taxaServico: data.get(#taxaServico, or: $value.taxaServico),
        taxaConcepcao: data.get(#taxaConcepcao, or: $value.taxaConcepcao),
        taxaPrenhez: data.get(#taxaPrenhez, or: $value.taxaPrenhez),
      );

  @override
  DashboardMonthlyRateModelCopyWith<$R2, DashboardMonthlyRateModel, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _DashboardMonthlyRateModelCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

