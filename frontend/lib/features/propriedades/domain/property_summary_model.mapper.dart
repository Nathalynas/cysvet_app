// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'property_summary_model.dart';

class PropertySummaryModelMapper extends ClassMapperBase<PropertySummaryModel> {
  PropertySummaryModelMapper._();

  static PropertySummaryModelMapper? _instance;
  static PropertySummaryModelMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PropertySummaryModelMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'PropertySummaryModel';

  static int _$id(PropertySummaryModel v) => v.id;
  static const Field<PropertySummaryModel, int> _f$id = Field(
    'id',
    _$id,
    opt: true,
    def: 0,
  );
  static String _$idExterno(PropertySummaryModel v) => v.idExterno;
  static const Field<PropertySummaryModel, String> _f$idExterno = Field(
    'idExterno',
    _$idExterno,
    opt: true,
    def: '',
  );
  static String _$nome(PropertySummaryModel v) => v.nome;
  static const Field<PropertySummaryModel, String> _f$nome = Field(
    'nome',
    _$nome,
    opt: true,
    def: '',
  );
  static String _$nomeProprietario(PropertySummaryModel v) =>
      v.nomeProprietario;
  static const Field<PropertySummaryModel, String> _f$nomeProprietario = Field(
    'nomeProprietario',
    _$nomeProprietario,
    opt: true,
    def: '',
  );
  static String? _$cidade(PropertySummaryModel v) => v.cidade;
  static const Field<PropertySummaryModel, String> _f$cidade = Field(
    'cidade',
    _$cidade,
    opt: true,
  );
  static String? _$estado(PropertySummaryModel v) => v.estado;
  static const Field<PropertySummaryModel, String> _f$estado = Field(
    'estado',
    _$estado,
    opt: true,
  );
  static String? _$observacoes(PropertySummaryModel v) => v.observacoes;
  static const Field<PropertySummaryModel, String> _f$observacoes = Field(
    'observacoes',
    _$observacoes,
    opt: true,
  );

  @override
  final MappableFields<PropertySummaryModel> fields = const {
    #id: _f$id,
    #idExterno: _f$idExterno,
    #nome: _f$nome,
    #nomeProprietario: _f$nomeProprietario,
    #cidade: _f$cidade,
    #estado: _f$estado,
    #observacoes: _f$observacoes,
  };

  static PropertySummaryModel _instantiate(DecodingData data) {
    return PropertySummaryModel(
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

  static PropertySummaryModel fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PropertySummaryModel>(map);
  }

  static PropertySummaryModel fromJson(String json) {
    return ensureInitialized().decodeJson<PropertySummaryModel>(json);
  }
}

mixin PropertySummaryModelMappable {
  String toJson() {
    return PropertySummaryModelMapper.ensureInitialized()
        .encodeJson<PropertySummaryModel>(this as PropertySummaryModel);
  }

  Map<String, dynamic> toMap() {
    return PropertySummaryModelMapper.ensureInitialized()
        .encodeMap<PropertySummaryModel>(this as PropertySummaryModel);
  }

  PropertySummaryModelCopyWith<
    PropertySummaryModel,
    PropertySummaryModel,
    PropertySummaryModel
  >
  get copyWith =>
      _PropertySummaryModelCopyWithImpl<
        PropertySummaryModel,
        PropertySummaryModel
      >(this as PropertySummaryModel, $identity, $identity);
  @override
  String toString() {
    return PropertySummaryModelMapper.ensureInitialized().stringifyValue(
      this as PropertySummaryModel,
    );
  }

  @override
  bool operator ==(Object other) {
    return PropertySummaryModelMapper.ensureInitialized().equalsValue(
      this as PropertySummaryModel,
      other,
    );
  }

  @override
  int get hashCode {
    return PropertySummaryModelMapper.ensureInitialized().hashValue(
      this as PropertySummaryModel,
    );
  }
}

extension PropertySummaryModelValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PropertySummaryModel, $Out> {
  PropertySummaryModelCopyWith<$R, PropertySummaryModel, $Out>
  get $asPropertySummaryModel => $base.as(
    (v, t, t2) => _PropertySummaryModelCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class PropertySummaryModelCopyWith<
  $R,
  $In extends PropertySummaryModel,
  $Out
>
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
  PropertySummaryModelCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _PropertySummaryModelCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PropertySummaryModel, $Out>
    implements PropertySummaryModelCopyWith<$R, PropertySummaryModel, $Out> {
  _PropertySummaryModelCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PropertySummaryModel> $mapper =
      PropertySummaryModelMapper.ensureInitialized();
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
  PropertySummaryModel $make(CopyWithData data) => PropertySummaryModel(
    id: data.get(#id, or: $value.id),
    idExterno: data.get(#idExterno, or: $value.idExterno),
    nome: data.get(#nome, or: $value.nome),
    nomeProprietario: data.get(#nomeProprietario, or: $value.nomeProprietario),
    cidade: data.get(#cidade, or: $value.cidade),
    estado: data.get(#estado, or: $value.estado),
    observacoes: data.get(#observacoes, or: $value.observacoes),
  );

  @override
  PropertySummaryModelCopyWith<$R2, PropertySummaryModel, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _PropertySummaryModelCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

