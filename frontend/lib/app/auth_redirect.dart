import '../models/auth_session_model.dart';

const _splashRoute = '/splash';
const _loginRoute = '/login';
const _superRoute = '/super';
const _changePasswordRoute = '/trocar-senha';
const _dashboardRoute = '/dashboard';

String? resolveAuthRedirect({
  required bool bootstrapComplete,
  required AuthSessionModel? session,
  required String location,
}) {
  if (!bootstrapComplete) {
    return location == _splashRoute ? null : _splashRoute;
  }

  if (session == null) {
    return location == _loginRoute ? null : _loginRoute;
  }

  final homeRoute = _homeRoute(session.user);
  if (location == _splashRoute) {
    return homeRoute;
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
    return _dashboardRoute;
  }

  return null;
}

String _homeRoute(AuthenticatedUserModel user) {
  if (user.trocarSenha) {
    return _changePasswordRoute;
  }

  return user.isSuperAdmin ? _superRoute : _dashboardRoute;
}
