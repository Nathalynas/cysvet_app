import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/animals/presentation/animals_page.dart';
import '../features/auth/application/auth_state.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/auth/presentation/auth_page_shell.dart';
import '../features/settings/settings_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/properties/presentation/property_details_page.dart';
import '../features/properties/presentation/properties_page.dart';
import '../features/splash/splash_page.dart';
import '../features/users/presentation/users_page.dart';
import '../features/visits/presentation/visit_form_page.dart';
import '../features/visits/presentation/visit_report_page.dart';
import '../features/visits/presentation/visits_page.dart';
import 'app_shell.dart';
import 'theme.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final bootstrapComplete = ref.watch(authBootstrapProvider);
  final session = ref.watch(authSessionProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthenticated = session != null;

      if (!bootstrapComplete && location != '/splash') {
        return '/splash';
      }

      if (!bootstrapComplete) {
        return null;
      }

      if (location == '/splash') {
        return isAuthenticated ? '/dashboard' : '/login';
      }

      if (!isAuthenticated && location != '/login' && location != '/register') {
        return '/login';
      }

      if (isAuthenticated &&
          (location == '/login' || location == '/register')) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => _buildPublicRoute(const SplashPage()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildAuthPage(const LoginPage()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _buildAuthPage(const RegisterPage()),
      ),
      ShellRoute(
        pageBuilder: (context, state, child) =>
            _buildAppShellPage(AppShell(child: child)),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                _buildShellChildPage(state, const DashboardPage()),
          ),
          GoRoute(
            path: '/propriedades',
            pageBuilder: (context, state) =>
                _buildShellChildPage(state, const PropertiesPage()),
          ),
          GoRoute(
            path: '/propriedades/:propertyId',
            pageBuilder: (context, state) {
              return _buildShellChildPage(
                state,
                PropertyDetailsPage(
                  propertyId:
                      int.tryParse(state.pathParameters['propertyId'] ?? '') ??
                      0,
                  initialTab: propertyTabFromQuery(
                    state.uri.queryParameters['aba'] ??
                        state.uri.queryParameters['tab'],
                  ),
                ),
              );
            },
          ),
          GoRoute(
            path: '/animais',
            pageBuilder: (context, state) =>
                _buildShellChildPage(state, const AnimalsPage()),
          ),
          GoRoute(
            path: '/visitas/nova',
            pageBuilder: (context, state) => _buildShellChildPage(
              state,
              VisitFormPage(
                initialPropertyId: int.tryParse(
                  state.uri.queryParameters['propriedade'] ?? '',
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/visitas/:visitId/detalhes',
            pageBuilder: (context, state) {
              final routeData = state.extra is VisitReportRouteData
                  ? state.extra! as VisitReportRouteData
                  : null;

              return _buildShellChildPage(
                state,
                VisitReportPage(
                  visitId:
                      int.tryParse(state.pathParameters['visitId'] ?? '') ?? 0,
                  initialData: routeData,
                  returnRoute: state.uri.queryParameters['retorno'],
                ),
              );
            },
          ),
          GoRoute(
            path: '/visitas',
            pageBuilder: (context, state) =>
                _buildShellChildPage(state, const VisitsPage()),
          ),
          GoRoute(
            path: '/usuarios',
            pageBuilder: (context, state) =>
                _buildShellChildPage(state, const UsuariosPage()),
          ),
          GoRoute(
            path: '/configuracoes',
            pageBuilder: (context, state) =>
                _buildShellChildPage(state, const ConfiguracoesPage()),
          ),
          GoRoute(
            path: '/perfil',
            redirect: (context, state) => '/configuracoes',
          ),
        ],
      ),
    ],
  );
});

Page<void> _buildAppShellPage(Widget child) {
  return NoTransitionPage<void>(key: const ValueKey('app-shell'), child: child);
}

Page<void> _buildShellChildPage(GoRouterState state, Widget child) {
  return NoTransitionPage<void>(
    key: state.pageKey,
    name: state.name ?? state.path,
    arguments: <String, String>{
      ...state.pathParameters,
      ...state.uri.queryParameters,
    },
    restorationId: state.pageKey.value,
    child: child,
  );
}

Page<void> _buildAuthPage(Widget form) {
  return NoTransitionPage<void>(
    key: const ValueKey('auth-page'),
    child: _buildPublicRoute(AuthPageShell(form: form)),
  );
}

Widget _buildPublicRoute(Widget child) {
  return Theme(data: AppTheme.lightTheme, child: child);
}
