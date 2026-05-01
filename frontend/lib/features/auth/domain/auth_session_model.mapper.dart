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

  @override
  final MappableFields<AuthSessionModel> fields = const {
    #accessToken: _f$accessToken,
    #refreshToken: _f$refreshToken,
    #user: _f$user,
  };

  static AuthSessionModel _instantiate(DecodingData data) {
    return AuthSessionModel(
      accessToken: data.dec(_f$accessToken),
      refreshToken: data.dec(_f$refreshToken),
      user: data.dec(_f$user),
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
  $R call({
    String? accessToken,
    String? refreshToken,
    AuthenticatedUserModel? user,
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
  $R call({
    String? accessToken,
    String? refreshToken,
    AuthenticatedUserModel? user,
  }) => $apply(
    FieldCopyWithData({
      if (accessToken != null) #accessToken: accessToken,
      if (refreshToken != null) #refreshToken: refreshToken,
      if (user != null) #user: user,
    }),
  );
  @override
  AuthSessionModel $make(CopyWithData data) => AuthSessionModel(
    accessToken: data.get(#accessToken, or: $value.accessToken),
    refreshToken: data.get(#refreshToken, or: $value.refreshToken),
    user: data.get(#user, or: $value.user),
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

  @override
  final MappableFields<AuthenticatedUserModel> fields = const {
    #id: _f$id,
    #name: _f$name,
    #email: _f$email,
  };

  static AuthenticatedUserModel _instantiate(DecodingData data) {
    return AuthenticatedUserModel(
      id: data.dec(_f$id),
      name: data.dec(_f$name),
      email: data.dec(_f$email),
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
  $R call({int? id, String? name, String? email});
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
  $R call({int? id, String? name, String? email}) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (name != null) #name: name,
      if (email != null) #email: email,
    }),
  );
  @override
  AuthenticatedUserModel $make(CopyWithData data) => AuthenticatedUserModel(
    id: data.get(#id, or: $value.id),
    name: data.get(#name, or: $value.name),
    email: data.get(#email, or: $value.email),
  );

  @override
  AuthenticatedUserModelCopyWith<$R2, AuthenticatedUserModel, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _AuthenticatedUserModelCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

