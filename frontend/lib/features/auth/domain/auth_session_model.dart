import 'package:dart_mappable/dart_mappable.dart';

part 'auth_session_model.mapper.dart';

@MappableClass()
class AuthSessionModel with AuthSessionModelMappable {
  const AuthSessionModel({
    this.accessToken = '',
    this.refreshToken = '',
    this.user = const AuthenticatedUserModel(),
  });

  final String accessToken;
  final String refreshToken;
  final AuthenticatedUserModel user;
}

@MappableClass()
class AuthenticatedUserModel with AuthenticatedUserModelMappable {
  const AuthenticatedUserModel({
    this.id = 0,
    this.name = '',
    this.email = '',
    this.perfil = 'USER',
  });

  final int id;
  final String name;
  final String email;
  final String perfil;
}

extension AuthenticatedUserModelPermissions on AuthenticatedUserModel {
  bool get isAdmin => perfil.toUpperCase() == 'ADMIN';
}
