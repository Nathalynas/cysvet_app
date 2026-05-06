import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/animais/presentation/pages/animals_page.dart';
import '../features/auth/application/auth_state.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/perfil/presentation/pages/profile_page.dart';
import '../features/propriedades/presentation/pages/properties_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../features/visitas/presentation/pages/visits_page.dart';
import 'app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(authSessionProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = session != null;
      final location = state.matchedLocation;

      final isPublicRoute = location == '/splash' || location == '/login';

      if (!isAuthenticated && !isPublicRoute) {
        return '/login';
      }

      if (isAuthenticated && location == '/login') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
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
            path: '/perfil',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );
});