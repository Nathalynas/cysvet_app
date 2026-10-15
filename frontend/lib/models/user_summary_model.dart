import 'package:cysvet_app/core/enums/user_status.dart';

class UserSummaryModel {
  const UserSummaryModel({
    this.id = 0,
    this.name = '',
    this.email = '',
    this.perfil = 'VETERINARIO',
    this.companyName,
    this.status = UserStatus.active,
    this.awaitingFirstAccess = false,
  });

  final int id;
  final String name;
  final String email;
  final String perfil;
  final String? companyName;
  final UserStatus status;

  /// Ainda nao trocou a senha provisoria recebida por e-mail.
  final bool awaitingFirstAccess;

  bool get isAdmin => perfil.toUpperCase() == 'ADMIN';

  String get displayRole {
    switch (perfil.toUpperCase()) {
      case 'ADMIN':
        return 'Administrador';
      case 'VETERINARIO':
        return 'Veterinário';
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
    bool? awaitingFirstAccess,
  }) {
    return UserSummaryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      perfil: perfil ?? this.perfil,
      companyName: companyName ?? this.companyName,
      status: status ?? this.status,
      awaitingFirstAccess: awaitingFirstAccess ?? this.awaitingFirstAccess,
    );
  }
}

/// Resultado do cadastro: o membro recebe a senha provisoria por e-mail,
/// exceto quando o e-mail ja tinha conta (ela so e vinculada a empresa).
class CreateUserResult {
  const CreateUserResult({
    required this.user,
    required this.emailSent,
    required this.existingAccount,
  });

  final UserSummaryModel user;
  final bool emailSent;
  final bool existingAccount;
}
