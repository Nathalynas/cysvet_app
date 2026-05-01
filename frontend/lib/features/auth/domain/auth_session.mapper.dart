// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'auth_session.dart';

class AuthSessionMapper extends ClassMapperBase<AuthSession> {
  AuthSessionMapper._();

  static AuthSessionMapper? _instance;
  static AuthSessionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AuthSessionMapper._());
      AuthenticatedUserMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'AuthSession';

  static String _$accessToken(AuthSession v) => v.accessToken;
  static const Field<AuthSession, String> _f$accessToken = Field(
    'accessToken',
    _$accessToken,
    opt: true,
    def: '',
  );
  static String _$refreshToken(AuthSession v) => v.refreshToken;
  static const Field<AuthSession, String> _f$refreshToken = Field(
    'refreshToken',
    _$refreshToken,
    opt: true,
    def: '',
  );
  static AuthenticatedUser _$user(AuthSession v) => v.user;
  static const Field<AuthSession, AuthenticatedUser> _f$user = Field(
    'user',
    _$user,
    opt: true,
    def: const AuthenticatedUser(),
  );

  @override
  final MappableFields<AuthSession> fields = const {
    #accessToken: _f$accessToken,
    #refreshToken: _f$refreshToken,
    #user: _f$user,
  };

  static AuthSession _instantiate(DecodingData data) {
    return AuthSession(
      accessToken: data.dec(_f$accessToken),
      refreshToken: data.dec(_f$refreshToken),
      user: data.dec(_f$user),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static AuthSession fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<AuthSession>(map);
  }

  static AuthSession fromJson(String json) {
    return ensureInitialized().decodeJson<AuthSession>(json);
  }
}

mixin AuthSessionMappable {
  String toJson() {
    return AuthSessionMapper.ensureInitialized().encodeJson<AuthSession>(
      this as AuthSession,
    );
  }

  Map<String, dynamic> toMap() {
    return AuthSessionMapper.ensureInitialized().encodeMap<AuthSession>(
      this as AuthSession,
    );
  }

  AuthSessionCopyWith<AuthSession, AuthSession, AuthSession> get copyWith =>
      _AuthSessionCopyWithImpl<AuthSession, AuthSession>(
        this as AuthSession,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return AuthSessionMapper.ensureInitialized().stringifyValue(
      this as AuthSession,
    );
  }

  @override
  bool operator ==(Object other) {
    return AuthSessionMapper.ensureInitialized().equalsValue(
      this as AuthSession,
      other,
    );
  }

  @override
  int get hashCode {
    return AuthSessionMapper.ensureInitialized().hashValue(this as AuthSession);
  }
}

extension AuthSessionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, AuthSession, $Out> {
  AuthSessionCopyWith<$R, AuthSession, $Out> get $asAuthSession =>
      $base.as((v, t, t2) => _AuthSessionCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class AuthSessionCopyWith<$R, $In extends AuthSession, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  AuthenticatedUserCopyWith<$R, AuthenticatedUser, AuthenticatedUser> get user;
  $R call({String? accessToken, String? refreshToken, AuthenticatedUser? user});
  AuthSessionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _AuthSessionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, AuthSession, $Out>
    implements AuthSessionCopyWith<$R, AuthSession, $Out> {
  _AuthSessionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<AuthSession> $mapper =
      AuthSessionMapper.ensureInitialized();
  @override
  AuthenticatedUserCopyWith<$R, AuthenticatedUser, AuthenticatedUser>
  get user => $value.user.copyWith.$chain((v) => call(user: v));
  @override
  $R call({
    String? accessToken,
    String? refreshToken,
    AuthenticatedUser? user,
  }) => $apply(
    FieldCopyWithData({
      if (accessToken != null) #accessToken: accessToken,
      if (refreshToken != null) #refreshToken: refreshToken,
      if (user != null) #user: user,
    }),
  );
  @override
  AuthSession $make(CopyWithData data) => AuthSession(
    accessToken: data.get(#accessToken, or: $value.accessToken),
    refreshToken: data.get(#refreshToken, or: $value.refreshToken),
    user: data.get(#user, or: $value.user),
  );

  @override
  AuthSessionCopyWith<$R2, AuthSession, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _AuthSessionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class AuthenticatedUserMapper extends ClassMapperBase<AuthenticatedUser> {
  AuthenticatedUserMapper._();

  static AuthenticatedUserMapper? _instance;
  static AuthenticatedUserMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AuthenticatedUserMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'AuthenticatedUser';

  static int _$id(AuthenticatedUser v) => v.id;
  static const Field<AuthenticatedUser, int> _f$id = Field(
    'id',
    _$id,
    opt: true,
    def: 0,
  );
  static String _$name(AuthenticatedUser v) => v.name;
  static const Field<AuthenticatedUser, String> _f$name = Field(
    'name',
    _$name,
    opt: true,
    def: '',
  );
  static String _$email(AuthenticatedUser v) => v.email;
  static const Field<AuthenticatedUser, String> _f$email = Field(
    'email',
    _$email,
    opt: true,
    def: '',
  );

  @override
  final MappableFields<AuthenticatedUser> fields = const {
    #id: _f$id,
    #name: _f$name,
    #email: _f$email,
  };

  static AuthenticatedUser _instantiate(DecodingData data) {
    return AuthenticatedUser(
      id: data.dec(_f$id),
      name: data.dec(_f$name),
      email: data.dec(_f$email),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static AuthenticatedUser fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<AuthenticatedUser>(map);
  }

  static AuthenticatedUser fromJson(String json) {
    return ensureInitialized().decodeJson<AuthenticatedUser>(json);
  }
}

mixin AuthenticatedUserMappable {
  String toJson() {
    return AuthenticatedUserMapper.ensureInitialized()
        .encodeJson<AuthenticatedUser>(this as AuthenticatedUser);
  }

  Map<String, dynamic> toMap() {
    return AuthenticatedUserMapper.ensureInitialized()
        .encodeMap<AuthenticatedUser>(this as AuthenticatedUser);
  }

  AuthenticatedUserCopyWith<
    AuthenticatedUser,
    AuthenticatedUser,
    AuthenticatedUser
  >
  get copyWith =>
      _AuthenticatedUserCopyWithImpl<AuthenticatedUser, AuthenticatedUser>(
        this as AuthenticatedUser,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return AuthenticatedUserMapper.ensureInitialized().stringifyValue(
      this as AuthenticatedUser,
    );
  }

  @override
  bool operator ==(Object other) {
    return AuthenticatedUserMapper.ensureInitialized().equalsValue(
      this as AuthenticatedUser,
      other,
    );
  }

  @override
  int get hashCode {
    return AuthenticatedUserMapper.ensureInitialized().hashValue(
      this as AuthenticatedUser,
    );
  }
}

extension AuthenticatedUserValueCopy<$R, $Out>
    on ObjectCopyWith<$R, AuthenticatedUser, $Out> {
  AuthenticatedUserCopyWith<$R, AuthenticatedUser, $Out>
  get $asAuthenticatedUser => $base.as(
    (v, t, t2) => _AuthenticatedUserCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class AuthenticatedUserCopyWith<
  $R,
  $In extends AuthenticatedUser,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? id, String? name, String? email});
  AuthenticatedUserCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _AuthenticatedUserCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, AuthenticatedUser, $Out>
    implements AuthenticatedUserCopyWith<$R, AuthenticatedUser, $Out> {
  _AuthenticatedUserCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<AuthenticatedUser> $mapper =
      AuthenticatedUserMapper.ensureInitialized();
  @override
  $R call({int? id, String? name, String? email}) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (name != null) #name: name,
      if (email != null) #email: email,
    }),
  );
  @override
  AuthenticatedUser $make(CopyWithData data) => AuthenticatedUser(
    id: data.get(#id, or: $value.id),
    name: data.get(#name, or: $value.name),
    email: data.get(#email, or: $value.email),
  );

  @override
  AuthenticatedUserCopyWith<$R2, AuthenticatedUser, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _AuthenticatedUserCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

