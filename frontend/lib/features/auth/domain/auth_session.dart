import 'package:dart_mappable/dart_mappable.dart';

part 'auth_session.mapper.dart';

@MappableClass()
class AuthSession with AuthSessionMappable {
  const AuthSession({
    this.accessToken = '',
    this.refreshToken = '',
    this.user = const AuthenticatedUser(),
  });

  final String accessToken;
  final String refreshToken;
  final AuthenticatedUser user;
}

@MappableClass()
class AuthenticatedUser with AuthenticatedUserMappable {
  const AuthenticatedUser({
    this.id = 0,
    this.name = '',
    this.email = '',
  });

  final int id;
  final String name;
  final String email;
}
