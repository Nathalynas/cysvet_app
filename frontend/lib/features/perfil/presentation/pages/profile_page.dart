import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/config/api_config.dart';
import '../../../auth/application/auth_state.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final isBusy = ref.watch(authBusyProvider);

    if (session == null) {
      return const Scaffold(body: Center(child: Text('Sessao indisponivel.')));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Usuario autenticado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ProfileLine(label: 'Nome', value: session.user.name),
                    _ProfileLine(label: 'E-mail', value: session.user.email),
                    _ProfileLine(
                      label: 'ID do usuario',
                      value: session.user.id.toString(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Conexao',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ProfileLine(label: 'Backend', value: ApiConfig.baseUrl),
                    _ProfileLine(
                      label: 'Access token',
                      value: _shortToken(session.accessToken),
                    ),
                    _ProfileLine(
                      label: 'Refresh token',
                      value: _shortToken(session.refreshToken),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isBusy
                  ? null
                  : () async {
                      await ref.read(authControllerProvider).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
              icon: const Icon(Icons.logout),
              label: Text(isBusy ? 'Saindo...' : 'Sair'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: AppTheme.bodyTextColor),
            ),
          ],
        ),
      ),
    );
  }
}

String _shortToken(String token) {
  if (token.length <= 18) {
    return token;
  }

  return '${token.substring(0, 10)}...${token.substring(token.length - 8)}';
}
