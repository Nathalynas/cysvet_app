// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'property_summary.dart';

class PropertySummaryMapper extends ClassMapperBase<PropertySummary> {
  PropertySummaryMapper._();

  static PropertySummaryMapper? _instance;
  static PropertySummaryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PropertySummaryMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'PropertySummary';

  static int _$id(PropertySummary v) => v.id;
  static const Field<PropertySummary, int> _f$id = Field(
    'id',
    _$id,
    opt: true,
    def: 0,
  );
  static String _$idExterno(PropertySummary v) => v.idExterno;
  static const Field<PropertySummary, String> _f$idExterno = Field(
    'idExterno',
    _$idExterno,
    opt: true,
    def: '',
  );
  static String _$nome(PropertySummary v) => v.nome;
  static const Field<PropertySummary, String> _f$nome = Field(
    'nome',
    _$nome,
    opt: true,
    def: '',
  );
  static String _$nomeProprietario(PropertySummary v) => v.nomeProprietario;
  static const Field<PropertySummary, String> _f$nomeProprietario = Field(
    'nomeProprietario',
    _$nomeProprietario,
    opt: true,
    def: '',
  );
  static String? _$cidade(PropertySummary v) => v.cidade;
  static const Field<PropertySummary, String> _f$cidade = Field(
    'cidade',
    _$cidade,
    opt: true,
  );
  static String? _$estado(PropertySummary v) => v.estado;
  static const Field<PropertySummary, String> _f$estado = Field(
    'estado',
    _$estado,
    opt: true,
  );
  static String? _$observacoes(PropertySummary v) => v.observacoes;
  static const Field<PropertySummary, String> _f$observacoes = Field(
    'observacoes',
    _$observacoes,
    opt: true,
  );

  @override
  final MappableFields<PropertySummary> fields = const {
    #id: _f$id,
    #idExterno: _f$idExterno,
    #nome: _f$nome,
    #nomeProprietario: _f$nomeProprietario,
    #cidade: _f$cidade,
    #estado: _f$estado,
    #observacoes: _f$observacoes,
  };

  static PropertySummary _instantiate(DecodingData data) {
    return PropertySummary(
      id: data.dec(_f$id),
      idExterno: data.dec(_f$idExterno),
      nome: data.dec(_f$nome),
      nomeProprietario: data.dec(_f$nomeProprietario),
      cidade: data.dec(_f$cidade),
      estado: data.dec(_f$estado),
      observacoes: data.dec(_f$observacoes),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PropertySummary fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PropertySummary>(map);
  }

  static PropertySummary fromJson(String json) {
    return ensureInitialized().decodeJson<PropertySummary>(json);
  }
}

mixin PropertySummaryMappable {
  String toJson() {
    return PropertySummaryMapper.ensureInitialized()
        .encodeJson<PropertySummary>(this as PropertySummary);
  }

  Map<String, dynamic> toMap() {
    return PropertySummaryMapper.ensureInitialized().encodeMap<PropertySummary>(
      this as PropertySummary,
    );
  }

  PropertySummaryCopyWith<PropertySummary, PropertySummary, PropertySummary>
  get copyWith =>
      _PropertySummaryCopyWithImpl<PropertySummary, PropertySummary>(
        this as PropertySummary,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return PropertySummaryMapper.ensureInitialized().stringifyValue(
      this as PropertySummary,
    );
  }

  @override
  bool operator ==(Object other) {
    return PropertySummaryMapper.ensureInitialized().equalsValue(
      this as PropertySummary,
      other,
    );
  }

  @override
  int get hashCode {
    return PropertySummaryMapper.ensureInitialized().hashValue(
      this as PropertySummary,
    );
  }
}

extension PropertySummaryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PropertySummary, $Out> {
  PropertySummaryCopyWith<$R, PropertySummary, $Out> get $asPropertySummary =>
      $base.as((v, t, t2) => _PropertySummaryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class PropertySummaryCopyWith<$R, $In extends PropertySummary, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    int? id,
    String? idExterno,
    String? nome,
    String? nomeProprietario,
    String? cidade,
    String? estado,
    String? observacoes,
  });
  PropertySummaryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _PropertySummaryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PropertySummary, $Out>
    implements PropertySummaryCopyWith<$R, PropertySummary, $Out> {
  _PropertySummaryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PropertySummary> $mapper =
      PropertySummaryMapper.ensureInitialized();
  @override
  $R call({
    int? id,
    String? idExterno,
    String? nome,
    String? nomeProprietario,
    Object? cidade = $none,
    Object? estado = $none,
    Object? observacoes = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (idExterno != null) #idExterno: idExterno,
      if (nome != null) #nome: nome,
      if (nomeProprietario != null) #nomeProprietario: nomeProprietario,
      if (cidade != $none) #cidade: cidade,
      if (estado != $none) #estado: estado,
      if (observacoes != $none) #observacoes: observacoes,
    }),
  );
  @override
  PropertySummary $make(CopyWithData data) => PropertySummary(
    id: data.get(#id, or: $value.id),
    idExterno: data.get(#idExterno, or: $value.idExterno),
    nome: data.get(#nome, or: $value.nome),
    nomeProprietario: data.get(#nomeProprietario, or: $value.nomeProprietario),
    cidade: data.get(#cidade, or: $value.cidade),
    estado: data.get(#estado, or: $value.estado),
    observacoes: data.get(#observacoes, or: $value.observacoes),
  );

  @override
  PropertySummaryCopyWith<$R2, PropertySummary, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _PropertySummaryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

