import 'package:dart_mappable/dart_mappable.dart';

part 'auth_session_model.mapper.dart';

@MappableClass()
class AuthSessionModel with AuthSessionModelMappable {
  const AuthSessionModel({
    this.accessToken = '',
    this.refreshToken = '',
    this.user = const AuthenticatedUserModel(),
    this.activeCompanyId = 0,
    this.companies = const [],
  });

  final String accessToken;
  final String refreshToken;
  final AuthenticatedUserModel user;
  @MappableField(key: 'empresaAtivaId')
  final int activeCompanyId;
  @MappableField(key: 'empresas')
  final List<AllowedCompanyModel> companies;
}

@MappableClass()
class AuthenticatedUserModel with AuthenticatedUserModelMappable {
  const AuthenticatedUserModel({
    this.id = 0,
    this.name = '',
    this.email = '',
    this.perfil = 'VETERINARIO',
  });

  final int id;
  final String name;
  final String email;
  final String perfil;
}

@MappableClass()
class AllowedCompanyModel with AllowedCompanyModelMappable {
  const AllowedCompanyModel({this.id = 0, this.name = '', this.email = ''});

  final int id;
  @MappableField(key: 'name')
  final String name;
  final String email;
}

extension AuthenticatedUserModelPermissions on AuthenticatedUserModel {
  bool get isAdmin => perfil.toUpperCase() == 'ADMIN';

  bool get isVeterinario => perfil.toUpperCase() == 'VETERINARIO';

  String get displayRole {
    switch (perfil.toUpperCase()) {
      case 'ADMIN':
        return 'Administrador';
      case 'VETERINARIO':
        return 'Veterinario';
      default:
        return perfil;
    }
  }
}

extension AuthSessionModelTenant on AuthSessionModel {
  AllowedCompanyModel? get activeCompany {
    for (final company in companies) {
      if (company.id == activeCompanyId) {
        return company;
      }
    }

    return companies.isEmpty ? null : companies.first;
  }
}
