import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/animals/presentation/pages/animals_page.dart';
import '../features/auth/application/auth_state.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/properties/presentation/pages/properties_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../features/users/presentation/pages/users_page.dart';
import '../features/visits/presentation/pages/visits_page.dart';
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

      if (isAuthenticated && (location == '/login' || location == '/register')) {
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
        builder: (context, state) => _buildPublicRoute(const LoginPage()),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => _buildPublicRoute(const RegisterPage()),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/propriedades',
            builder: (context, state) => const PropertiesPage(),
          ),
          GoRoute(
            path: '/animais',
            builder: (context, state) => const AnimalsPage(),
          ),
          GoRoute(
            path: '/visitas',
            builder: (context, state) => const VisitsPage(),
          ),
          GoRoute(
            path: '/usuarios',
            builder: (context, state) => const UsuariosPage(),
          ),
          GoRoute(
            path: '/configuracoes',
            builder: (context, state) => const ConfiguracoesPage(),
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

Widget _buildPublicRoute(Widget child) {
  return Theme(data: AppTheme.lightTheme, child: child);
}
