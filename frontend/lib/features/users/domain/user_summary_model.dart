import '../../../core/enums/user_status.dart';

class UserSummaryModel {
  const UserSummaryModel({
    this.id = 0,
    this.name = '',
    this.email = '',
    this.perfil = 'VETERINARIO',
    this.companyName,
    this.status = UserStatus.active,
  });

  final int id;
  final String name;
  final String email;
  final String perfil;
  final String? companyName;
  final UserStatus status;

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

  UserSummaryModel copyWith({
    int? id,
    String? name,
    String? email,
    String? perfil,
    String? companyName,
    UserStatus? status,
  }) {
    return UserSummaryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      perfil: perfil ?? this.perfil,
      companyName: companyName ?? this.companyName,
      status: status ?? this.status,
    );
  }
}
