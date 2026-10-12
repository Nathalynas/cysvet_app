import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../pages/animals/animals_page.dart';
import '../providers/auth_state.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/change_password_page.dart';
import '../pages/auth/auth_page_shell.dart';
import '../pages/settings/settings_page.dart';
import '../pages/dashboard/dashboard_page.dart';
import '../pages/properties/property_details_page.dart';
import '../pages/properties/properties_page.dart';
import '../pages/splash/splash_page.dart';
import '../pages/users/users_page.dart';
import '../pages/visits/visit_form_page.dart';
import '../pages/visits/visit_report_page.dart';
import '../pages/visits/visits_page.dart';
import 'app_shell.dart';
import 'auth_redirect.dart';
import 'theme.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final bootstrapComplete = ref.watch(authBootstrapProvider);
  final session = ref.watch(authSessionProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) => resolveAuthRedirect(
      bootstrapComplete: bootstrapComplete,
      session: session,
      location: state.matchedLocation,
    ),
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
        path: '/super',
        builder: (context, state) =>
            _buildPublicRoute(const _RoutePlaceholder('/super')),
      ),
      GoRoute(
        path: '/trocar-senha',
        pageBuilder: (context, state) =>
            _buildAuthPage(const ChangePasswordPage()),
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
            path: '/visitas/editar/:idExterno',
            pageBuilder: (context, state) => _buildShellChildPage(
              state,
              VisitFormPage(
                editingIdExterno: state.pathParameters['idExterno'],
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

// Substituído pelas páginas reais nas tarefas seguintes.
class _RoutePlaceholder extends StatelessWidget {
  const _RoutePlaceholder(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(name)));
  }
}
