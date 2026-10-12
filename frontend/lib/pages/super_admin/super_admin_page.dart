import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cysvet_app/app/theme.dart';
import 'package:cysvet_app/core/presentation/app_scaffold_messenger.dart';
import 'package:cysvet_app/core/widgets/app_button.dart';
import 'package:cysvet_app/core/widgets/status_badge.dart';
import 'package:cysvet_app/models/client_company_model.dart';
import 'package:cysvet_app/pages/super_admin/client_company_dialog.dart';
import 'package:cysvet_app/providers/auth_state.dart';
import 'package:cysvet_app/providers/super_admin_provider.dart';

const _narrowBreakpoint = 600.0;

class SuperAdminPage extends ConsumerStatefulWidget {
  const SuperAdminPage({super.key});

  @override
  ConsumerState<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends ConsumerState<SuperAdminPage> {
  String _query = '';

  List<ClientCompanyModel> _filter(List<ClientCompanyModel> items) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items
        .where(
          (c) =>
              c.name.toLowerCase().contains(query) ||
              c.responsibleEmail.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider).logout();
    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _create() async {
    final result = await showClientCompanyDialog(context);
    if (result == null) return;
    if (result.emailSent) {
      showAppSuccess(
        'Empresa criada. A senha provisória foi enviada para ${result.email}.',
      );
    } else {
      showAppWarning(
        'Empresa criada, mas o e-mail não foi enviado. Use Reenviar senha.',
      );
    }
  }

  Future<void> _deactivate(ClientCompanyModel company) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Desativar ${company.name}?'),
        content: const Text(
          'Os usuários dessa empresa perdem o acesso na hora. '
          'Os dados não são apagados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _setActive(company, false);
  }

  Future<void> _setActive(ClientCompanyModel company, bool active) async {
    try {
      await ref
          .read(superAdminCompaniesProvider.notifier)
          .setActive(company.id, active);
    } catch (error) {
      showAppError(error);
    }
  }

  Future<void> _resend(ClientCompanyModel company) async {
    try {
      final sent = await ref
          .read(superAdminCompaniesProvider.notifier)
          .resendAccess(company.id);
      if (sent) {
        showAppSuccess(
          'Nova senha provisória enviada para ${company.responsibleEmail}.',
        );
      } else {
        showAppWarning('Não foi possível enviar o e-mail. Tente novamente.');
      }
    } catch (error) {
      showAppError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companies = ref.watch(superAdminCompaniesProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary1Color,
        foregroundColor: Colors.white,
        title: const Text(
          'CYSVET · Super usuário',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 18, color: Colors.white),
            label: const Text('Sair'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Toolbar(
                    onSearch: (value) => setState(() => _query = value),
                    onCreate: _create,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: companies.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => _ErrorView(
                        onRetry: () => ref
                            .read(superAdminCompaniesProvider.notifier)
                            .refresh(),
                      ),
                      data: (items) {
                        if (items.isEmpty) {
                          return const Center(
                            child: Text('Nenhuma empresa cadastrada.'),
                          );
                        }
                        final filtered = _filter(items);
                        if (filtered.isEmpty) {
                          return const Center(
                            child: Text('Nenhuma empresa encontrada.'),
                          );
                        }
                        return _CompaniesList(
                          companies: filtered,
                          onResend: _resend,
                          onDeactivate: _deactivate,
                          onReactivate: (c) => _setActive(c, true),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.onSearch, required this.onCreate});

  final ValueChanged<String> onSearch;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: onSearch,
            decoration: const InputDecoration(
              hintText: 'Buscar empresa ou e-mail',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        AppButton(text: '+ Nova empresa', onPressed: onCreate),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Não foi possível carregar as empresas.'),
          const SizedBox(height: 12),
          AppButton(text: 'Tentar novamente', onPressed: onRetry),
        ],
      ),
    );
  }
}

class _CompaniesList extends StatelessWidget {
  const _CompaniesList({
    required this.companies,
    required this.onResend,
    required this.onDeactivate,
    required this.onReactivate,
  });

  final List<ClientCompanyModel> companies;
  final ValueChanged<ClientCompanyModel> onResend;
  final ValueChanged<ClientCompanyModel> onDeactivate;
  final ValueChanged<ClientCompanyModel> onReactivate;

  Widget _actions(ClientCompanyModel company) => _Actions(
    company: company,
    onResend: onResend,
    onDeactivate: onDeactivate,
    onReactivate: onReactivate,
  );

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < _narrowBreakpoint;

    if (narrow) {
      return ListView.separated(
        itemCount: companies.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final company = companies[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _ResponsibleText(company),
                  const SizedBox(height: 8),
                  _StatusPill(company.status),
                  const SizedBox(height: 10),
                  _actions(company),
                ],
              ),
            ),
          );
        },
      );
    }

    return ListView(
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const _TableHeader(),
              for (final company in companies) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          company.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor,
                          ),
                        ),
                      ),
                      Expanded(flex: 3, child: _ResponsibleText(company)),
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _StatusPill(company.status),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _actions(company),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontWeight: FontWeight.w600, fontSize: 12);
    return Container(
      color: AppTheme.secondaryColor.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('Empresa', style: style)),
          Expanded(flex: 3, child: Text('Responsável', style: style)),
          Expanded(flex: 3, child: Text('Situação', style: style)),
          Expanded(flex: 4, child: SizedBox.shrink()),
        ],
      ),
    );
  }
}

class _ResponsibleText extends StatelessWidget {
  const _ResponsibleText(this.company);

  final ClientCompanyModel company;

  @override
  Widget build(BuildContext context) {
    final hasName = company.responsibleName.isNotEmpty;
    final hasEmail = company.responsibleEmail.isNotEmpty;
    if (!hasName && !hasEmail) {
      return const Text('—', style: TextStyle(color: AppTheme.mutedTextColor));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasName) Text(company.responsibleName),
        if (hasEmail)
          Text(
            company.responsibleEmail,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.mutedTextColor,
            ),
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);

  final ClientCompanyStatus status;

  @override
  Widget build(BuildContext context) {
    final badge = switch (status) {
      ClientCompanyStatus.ativa => const StatusBadge(
        label: 'Ativa',
        type: StatusBadgeType.success,
      ),
      ClientCompanyStatus.aguardandoPrimeiroAcesso => const StatusBadge(
        label: 'Aguardando 1º acesso',
        type: StatusBadgeType.warning,
      ),
      ClientCompanyStatus.desativada => const StatusBadge(
        label: 'Desativada',
        type: StatusBadgeType.neutral,
      ),
    };
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: badge,
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.company,
    required this.onResend,
    required this.onDeactivate,
    required this.onReactivate,
  });

  final ClientCompanyModel company;
  final ValueChanged<ClientCompanyModel> onResend;
  final ValueChanged<ClientCompanyModel> onDeactivate;
  final ValueChanged<ClientCompanyModel> onReactivate;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        AppButton(
          text: 'Reenviar senha',
          outlined: true,
          onPressed: () => onResend(company),
        ),
        if (company.isActive)
          AppButton(
            text: 'Desativar',
            outlined: true,
            color: AppTheme.dangerColor,
            onPressed: () => onDeactivate(company),
          )
        else
          AppButton(text: 'Reativar', onPressed: () => onReactivate(company)),
      ],
    );
  }
}
