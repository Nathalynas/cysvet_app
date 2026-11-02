import '../models/auth_session_model.dart';

const _splashRoute = '/splash';
const _loginRoute = '/login';
const _superRoute = '/super';
const _changePasswordRoute = '/trocar-senha';
const _dashboardRoute = '/dashboard';
const _teamRoute = '/usuarios';

String? resolveAuthRedirect({
  required bool bootstrapComplete,
  required AuthSessionModel? session,
  required String location,
  String homeRoute = _dashboardRoute,
}) {
  if (!bootstrapComplete) {
    return location == _splashRoute ? null : _splashRoute;
  }

  if (session == null) {
    return location == _loginRoute ? null : _loginRoute;
  }

  final userHome = _homeRoute(session.user, homeRoute);
  if (location == _splashRoute) {
    return userHome;
  }

  if (session.user.trocarSenha) {
    return location == _changePasswordRoute ? null : _changePasswordRoute;
  }

  if (session.user.isSuperAdmin) {
    return location == _superRoute ? null : _superRoute;
  }

  if (location == _loginRoute ||
      location == _superRoute ||
      location == _changePasswordRoute) {
    return homeRoute;
  }

  // So o administrador da empresa cadastra a equipe.
  if (location.startsWith(_teamRoute) && !session.user.isAdmin) {
    return homeRoute;
  }

  return null;
}

String _homeRoute(AuthenticatedUserModel user, String homeRoute) {
  if (user.trocarSenha) {
    return _changePasswordRoute;
  }

  return user.isSuperAdmin ? _superRoute : homeRoute;
}
