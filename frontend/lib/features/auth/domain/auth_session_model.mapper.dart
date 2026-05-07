// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'auth_session_model.dart';

class AuthSessionModelMapper extends ClassMapperBase<AuthSessionModel> {
  AuthSessionModelMapper._();

  static AuthSessionModelMapper? _instance;
  static AuthSessionModelMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AuthSessionModelMapper._());
      AuthenticatedUserModelMapper.ensureInitialized();
      AllowedCompanyModelMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'AuthSessionModel';

  static String _$accessToken(AuthSessionModel v) => v.accessToken;
  static const Field<AuthSessionModel, String> _f$accessToken = Field(
    'accessToken',
    _$accessToken,
    opt: true,
    def: '',
  );
  static String _$refreshToken(AuthSessionModel v) => v.refreshToken;
  static const Field<AuthSessionModel, String> _f$refreshToken = Field(
    'refreshToken',
    _$refreshToken,
    opt: true,
    def: '',
  );
  static AuthenticatedUserModel _$user(AuthSessionModel v) => v.user;
  static const Field<AuthSessionModel, AuthenticatedUserModel> _f$user = Field(
    'user',
    _$user,
    opt: true,
    def: const AuthenticatedUserModel(),
  );
  static int _$activeCompanyId(AuthSessionModel v) => v.activeCompanyId;
  static const Field<AuthSessionModel, int> _f$activeCompanyId = Field(
    'activeCompanyId',
    _$activeCompanyId,
    key: r'empresaAtivaId',
    opt: true,
    def: 0,
  );
  static List<AllowedCompanyModel> _$companies(AuthSessionModel v) =>
      v.companies;
  static const Field<AuthSessionModel, List<AllowedCompanyModel>> _f$companies =
      Field(
        'companies',
        _$companies,
        key: r'empresas',
        opt: true,
        def: const [],
      );

  @override
  final MappableFields<AuthSessionModel> fields = const {
    #accessToken: _f$accessToken,
    #refreshToken: _f$refreshToken,
    #user: _f$user,
    #activeCompanyId: _f$activeCompanyId,
    #companies: _f$companies,
  };

  static AuthSessionModel _instantiate(DecodingData data) {
    return AuthSessionModel(
      accessToken: data.dec(_f$accessToken),
      refreshToken: data.dec(_f$refreshToken),
      user: data.dec(_f$user),
      activeCompanyId: data.dec(_f$activeCompanyId),
      companies: data.dec(_f$companies),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static AuthSessionModel fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<AuthSessionModel>(map);
  }

  static AuthSessionModel fromJson(String json) {
    return ensureInitialized().decodeJson<AuthSessionModel>(json);
  }
}

mixin AuthSessionModelMappable {
  String toJson() {
    return AuthSessionModelMapper.ensureInitialized()
        .encodeJson<AuthSessionModel>(this as AuthSessionModel);
  }

  Map<String, dynamic> toMap() {
    return AuthSessionModelMapper.ensureInitialized()
        .encodeMap<AuthSessionModel>(this as AuthSessionModel);
  }

  AuthSessionModelCopyWith<AuthSessionModel, AuthSessionModel, AuthSessionModel>
  get copyWith =>
      _AuthSessionModelCopyWithImpl<AuthSessionModel, AuthSessionModel>(
        this as AuthSessionModel,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return AuthSessionModelMapper.ensureInitialized().stringifyValue(
      this as AuthSessionModel,
    );
  }

  @override
  bool operator ==(Object other) {
    return AuthSessionModelMapper.ensureInitialized().equalsValue(
      this as AuthSessionModel,
      other,
    );
  }

  @override
  int get hashCode {
    return AuthSessionModelMapper.ensureInitialized().hashValue(
      this as AuthSessionModel,
    );
  }
}

extension AuthSessionModelValueCopy<$R, $Out>
    on ObjectCopyWith<$R, AuthSessionModel, $Out> {
  AuthSessionModelCopyWith<$R, AuthSessionModel, $Out>
  get $asAuthSessionModel =>
      $base.as((v, t, t2) => _AuthSessionModelCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class AuthSessionModelCopyWith<$R, $In extends AuthSessionModel, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  AuthenticatedUserModelCopyWith<
    $R,
    AuthenticatedUserModel,
    AuthenticatedUserModel
  >
  get user;
  ListCopyWith<
    $R,
    AllowedCompanyModel,
    AllowedCompanyModelCopyWith<$R, AllowedCompanyModel, AllowedCompanyModel>
  >
  get companies;
  $R call({
    String? accessToken,
    String? refreshToken,
    AuthenticatedUserModel? user,
    int? activeCompanyId,
    List<AllowedCompanyModel>? companies,
  });
  AuthSessionModelCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _AuthSessionModelCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, AuthSessionModel, $Out>
    implements AuthSessionModelCopyWith<$R, AuthSessionModel, $Out> {
  _AuthSessionModelCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<AuthSessionModel> $mapper =
      AuthSessionModelMapper.ensureInitialized();
  @override
  AuthenticatedUserModelCopyWith<
    $R,
    AuthenticatedUserModel,
    AuthenticatedUserModel
  >
  get user => $value.user.copyWith.$chain((v) => call(user: v));
  @override
  ListCopyWith<
    $R,
    AllowedCompanyModel,
    AllowedCompanyModelCopyWith<$R, AllowedCompanyModel, AllowedCompanyModel>
  >
  get companies => ListCopyWith(
    $value.companies,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(companies: v),
  );
  @override
  $R call({
    String? accessToken,
    String? refreshToken,
    AuthenticatedUserModel? user,
    int? activeCompanyId,
    List<AllowedCompanyModel>? companies,
  }) => $apply(
    FieldCopyWithData({
      if (accessToken != null) #accessToken: accessToken,
      if (refreshToken != null) #refreshToken: refreshToken,
      if (user != null) #user: user,
      if (activeCompanyId != null) #activeCompanyId: activeCompanyId,
      if (companies != null) #companies: companies,
    }),
  );
  @override
  AuthSessionModel $make(CopyWithData data) => AuthSessionModel(
    accessToken: data.get(#accessToken, or: $value.accessToken),
    refreshToken: data.get(#refreshToken, or: $value.refreshToken),
    user: data.get(#user, or: $value.user),
    activeCompanyId: data.get(#activeCompanyId, or: $value.activeCompanyId),
    companies: data.get(#companies, or: $value.companies),
  );

  @override
  AuthSessionModelCopyWith<$R2, AuthSessionModel, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _AuthSessionModelCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class AuthenticatedUserModelMapper
    extends ClassMapperBase<AuthenticatedUserModel> {
  AuthenticatedUserModelMapper._();

  static AuthenticatedUserModelMapper? _instance;
  static AuthenticatedUserModelMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AuthenticatedUserModelMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'AuthenticatedUserModel';

  static int _$id(AuthenticatedUserModel v) => v.id;
  static const Field<AuthenticatedUserModel, int> _f$id = Field(
    'id',
    _$id,
    opt: true,
    def: 0,
  );
  static String _$name(AuthenticatedUserModel v) => v.name;
  static const Field<AuthenticatedUserModel, String> _f$name = Field(
    'name',
    _$name,
    opt: true,
    def: '',
  );
  static String _$email(AuthenticatedUserModel v) => v.email;
  static const Field<AuthenticatedUserModel, String> _f$email = Field(
    'email',
    _$email,
    opt: true,
    def: '',
  );
  static String _$perfil(AuthenticatedUserModel v) => v.perfil;
  static const Field<AuthenticatedUserModel, String> _f$perfil = Field(
    'perfil',
    _$perfil,
    opt: true,
    def: 'VETERINARIAN',
  );

  @override
  final MappableFields<AuthenticatedUserModel> fields = const {
    #id: _f$id,
    #name: _f$name,
    #email: _f$email,
    #perfil: _f$perfil,
  };

  static AuthenticatedUserModel _instantiate(DecodingData data) {
    return AuthenticatedUserModel(
      id: data.dec(_f$id),
      name: data.dec(_f$name),
      email: data.dec(_f$email),
      perfil: data.dec(_f$perfil),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static AuthenticatedUserModel fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<AuthenticatedUserModel>(map);
  }

  static AuthenticatedUserModel fromJson(String json) {
    return ensureInitialized().decodeJson<AuthenticatedUserModel>(json);
  }
}

mixin AuthenticatedUserModelMappable {
  String toJson() {
    return AuthenticatedUserModelMapper.ensureInitialized()
        .encodeJson<AuthenticatedUserModel>(this as AuthenticatedUserModel);
  }

  Map<String, dynamic> toMap() {
    return AuthenticatedUserModelMapper.ensureInitialized()
        .encodeMap<AuthenticatedUserModel>(this as AuthenticatedUserModel);
  }

  AuthenticatedUserModelCopyWith<
    AuthenticatedUserModel,
    AuthenticatedUserModel,
    AuthenticatedUserModel
  >
  get copyWith =>
      _AuthenticatedUserModelCopyWithImpl<
        AuthenticatedUserModel,
        AuthenticatedUserModel
      >(this as AuthenticatedUserModel, $identity, $identity);
  @override
  String toString() {
    return AuthenticatedUserModelMapper.ensureInitialized().stringifyValue(
      this as AuthenticatedUserModel,
    );
  }

  @override
  bool operator ==(Object other) {
    return AuthenticatedUserModelMapper.ensureInitialized().equalsValue(
      this as AuthenticatedUserModel,
      other,
    );
  }

  @override
  int get hashCode {
    return AuthenticatedUserModelMapper.ensureInitialized().hashValue(
      this as AuthenticatedUserModel,
    );
  }
}

extension AuthenticatedUserModelValueCopy<$R, $Out>
    on ObjectCopyWith<$R, AuthenticatedUserModel, $Out> {
  AuthenticatedUserModelCopyWith<$R, AuthenticatedUserModel, $Out>
  get $asAuthenticatedUserModel => $base.as(
    (v, t, t2) => _AuthenticatedUserModelCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class AuthenticatedUserModelCopyWith<
  $R,
  $In extends AuthenticatedUserModel,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? id, String? name, String? email, String? perfil});
  AuthenticatedUserModelCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _AuthenticatedUserModelCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, AuthenticatedUserModel, $Out>
    implements
        AuthenticatedUserModelCopyWith<$R, AuthenticatedUserModel, $Out> {
  _AuthenticatedUserModelCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<AuthenticatedUserModel> $mapper =
      AuthenticatedUserModelMapper.ensureInitialized();
  @override
  $R call({int? id, String? name, String? email, String? perfil}) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (name != null) #name: name,
      if (email != null) #email: email,
      if (perfil != null) #perfil: perfil,
    }),
  );
  @override
  AuthenticatedUserModel $make(CopyWithData data) => AuthenticatedUserModel(
    id: data.get(#id, or: $value.id),
    name: data.get(#name, or: $value.name),
    email: data.get(#email, or: $value.email),
    perfil: data.get(#perfil, or: $value.perfil),
  );

  @override
  AuthenticatedUserModelCopyWith<$R2, AuthenticatedUserModel, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _AuthenticatedUserModelCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class AllowedCompanyModelMapper extends ClassMapperBase<AllowedCompanyModel> {
  AllowedCompanyModelMapper._();

  static AllowedCompanyModelMapper? _instance;
  static AllowedCompanyModelMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AllowedCompanyModelMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'AllowedCompanyModel';

  static int _$id(AllowedCompanyModel v) => v.id;
  static const Field<AllowedCompanyModel, int> _f$id = Field(
    'id',
    _$id,
    opt: true,
    def: 0,
  );
  static String _$name(AllowedCompanyModel v) => v.name;
  static const Field<AllowedCompanyModel, String> _f$name = Field(
    'name',
    _$name,
    opt: true,
    def: '',
  );
  static String _$email(AllowedCompanyModel v) => v.email;
  static const Field<AllowedCompanyModel, String> _f$email = Field(
    'email',
    _$email,
    opt: true,
    def: '',
  );

  @override
  final MappableFields<AllowedCompanyModel> fields = const {
    #id: _f$id,
    #name: _f$name,
    #email: _f$email,
  };

  static AllowedCompanyModel _instantiate(DecodingData data) {
    return AllowedCompanyModel(
      id: data.dec(_f$id),
      name: data.dec(_f$name),
      email: data.dec(_f$email),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static AllowedCompanyModel fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<AllowedCompanyModel>(map);
  }

  static AllowedCompanyModel fromJson(String json) {
    return ensureInitialized().decodeJson<AllowedCompanyModel>(json);
  }
}

mixin AllowedCompanyModelMappable {
  String toJson() {
    return AllowedCompanyModelMapper.ensureInitialized()
        .encodeJson<AllowedCompanyModel>(this as AllowedCompanyModel);
  }

  Map<String, dynamic> toMap() {
    return AllowedCompanyModelMapper.ensureInitialized()
        .encodeMap<AllowedCompanyModel>(this as AllowedCompanyModel);
  }

  AllowedCompanyModelCopyWith<
    AllowedCompanyModel,
    AllowedCompanyModel,
    AllowedCompanyModel
  >
  get copyWith =>
      _AllowedCompanyModelCopyWithImpl<
        AllowedCompanyModel,
        AllowedCompanyModel
      >(this as AllowedCompanyModel, $identity, $identity);
  @override
  String toString() {
    return AllowedCompanyModelMapper.ensureInitialized().stringifyValue(
      this as AllowedCompanyModel,
    );
  }

  @override
  bool operator ==(Object other) {
    return AllowedCompanyModelMapper.ensureInitialized().equalsValue(
      this as AllowedCompanyModel,
      other,
    );
  }

  @override
  int get hashCode {
    return AllowedCompanyModelMapper.ensureInitialized().hashValue(
      this as AllowedCompanyModel,
    );
  }
}

extension AllowedCompanyModelValueCopy<$R, $Out>
    on ObjectCopyWith<$R, AllowedCompanyModel, $Out> {
  AllowedCompanyModelCopyWith<$R, AllowedCompanyModel, $Out>
  get $asAllowedCompanyModel => $base.as(
    (v, t, t2) => _AllowedCompanyModelCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class AllowedCompanyModelCopyWith<
  $R,
  $In extends AllowedCompanyModel,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? id, String? name, String? email});
  AllowedCompanyModelCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _AllowedCompanyModelCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, AllowedCompanyModel, $Out>
    implements AllowedCompanyModelCopyWith<$R, AllowedCompanyModel, $Out> {
  _AllowedCompanyModelCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<AllowedCompanyModel> $mapper =
      AllowedCompanyModelMapper.ensureInitialized();
  @override
  $R call({int? id, String? name, String? email}) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (name != null) #name: name,
      if (email != null) #email: email,
    }),
  );
  @override
  AllowedCompanyModel $make(CopyWithData data) => AllowedCompanyModel(
    id: data.get(#id, or: $value.id),
    name: data.get(#name, or: $value.name),
    email: data.get(#email, or: $value.email),
  );

  @override
  AllowedCompanyModelCopyWith<$R2, AllowedCompanyModel, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _AllowedCompanyModelCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

