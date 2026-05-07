import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/application/auth_state.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/auth_session_model.dart';

class ConfiguracoesPage extends ConsumerStatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  ConsumerState<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends ConsumerState<ConfiguracoesPage> {
  final _userNameController = TextEditingController();
  final _userEmailController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyEmailController = TextEditingController();

  bool _isEditingUser = false;
  bool _isSavingUser = false;
  bool _isEditingCompany = false;
  bool _isSavingCompany = false;

  int? _syncedUserId;
  String _syncedUserName = '';
  String _syncedUserEmail = '';

  int? _syncedCompanyId;
  String _companyName = '';
  String _companyEmail = '';

  @override
  void dispose() {
    _userNameController.dispose();
    _userEmailController.dispose();
    _companyNameController.dispose();
    _companyEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final isBusy = ref.watch(authBusyProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final theme = Theme.of(context);

    _syncUserControllers(session);
    _syncCompanyControllers(session);

    if (session == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: Text('Sessão indisponível.')),
      );
    }

    final activeCompany = session.activeCompany;
    final canEditCompanyData = _canEditCompanyData(session.user);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AppearanceCard(themeMode: themeMode),
            const SizedBox(height: 16),

            _EditableSettingsCard(
              title: 'Meus Dados',
              canEdit: true,
              isEditing: _isEditingUser,
              isLoading: _isSavingUser,
              onEdit: () => setState(() => _isEditingUser = true),
              onCancel: () => _cancelUserEditing(session),
              onSubmit: _saveUserData,
              fields: [
                ..._buildUserFields(isEditing: _isEditingUser),
                const SizedBox(height: 12),
                _InfoRow(label: 'Perfil', value: session.user.displayRole),
              ],
            ),

            const SizedBox(height: 16),

            _SettingsCard(
              title: 'Empresa Ativa',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: activeCompany?.id,
                    decoration: const InputDecoration(labelText: 'Empresa'),
                    items: session.companies
                        .map(
                          (company) => DropdownMenuItem(
                            value: company.id,
                            child: Text(company.name),
                          ),
                        )
                        .toList(),
                    onChanged: (companyId) async {
                      if (companyId == null ||
                          companyId == session.activeCompanyId) {
                        return;
                      }

                      await ref
                          .read(authSessionProvider.notifier)
                          .switchActiveCompany(companyId);

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Empresa ativa atualizada para esta sessão.',
                          ),
                        ),
                      );
                    },
                  ),
                  if (activeCompany != null) ...[
                    const SizedBox(height: 16),
                    _InfoRow(label: 'Tenant ID', value: activeCompany.id.toString()),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            _EditableSettingsCard(
              title: 'Dados da Empresa',
              canEdit: canEditCompanyData,
              isEditing: _isEditingCompany,
              isLoading: _isSavingCompany,
              onEdit: () => setState(() => _isEditingCompany = true),
              onCancel: _cancelCompanyEditing,
              onSubmit: () {
                _saveCompanyData();
              },
              fields: _buildCompanyFields(
                canEdit: canEditCompanyData,
                isEditing: _isEditingCompany,
              ),
            ),

            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                text: 'Sair',
                icon: const Icon(Icons.logout, size: 18),
                loading: isBusy,
                disabled: isBusy,
                height: 44,
                onPressed: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildUserFields({required bool isEditing}) {
    final isEnabled = !_isSavingUser;

    return [
      AppTextField(
        controller: _userNameController,
        label: 'Nome',
        required: true,
        enabled: isEnabled,
        readOnly: !isEditing || _isSavingUser,
        textInputAction: TextInputAction.next,
        validator: _validateRequired,
      ),
      AppTextField(
        controller: _userEmailController,
        label: 'E-mail',
        required: true,
        enabled: isEnabled,
        readOnly: !isEditing || _isSavingUser,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        validator: _validateEmail,
      ),
    ];
  }

  List<Widget> _buildCompanyFields({
    required bool canEdit,
    required bool isEditing,
  }) {
    final isEnabled = !_isSavingCompany;
    final isReadOnly = !canEdit || !isEditing || _isSavingCompany;

    return [
      AppTextField(
        controller: _companyNameController,
        label: 'Nome da empresa',
        required: true,
        enabled: isEnabled,
        readOnly: isReadOnly,
        textInputAction: TextInputAction.next,
        validator: _validateRequired,
      ),
      AppTextField(
        controller: _companyEmailController,
        label: 'E-mail da empresa',
        required: true,
        enabled: isEnabled,
        readOnly: isReadOnly,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        validator: _validateEmail,
      ),
    ];
  }

  void _syncUserControllers(AuthSessionModel? session) {
    if (session == null || _isEditingUser) {
      return;
    }

    final user = session.user;
    final userChanged =
        _syncedUserId != user.id ||
        _syncedUserName != user.name ||
        _syncedUserEmail != user.email;

    if (!userChanged) {
      return;
    }

    _userNameController.text = user.name;
    _userEmailController.text = user.email;
    _syncedUserId = user.id;
    _syncedUserName = user.name;
    _syncedUserEmail = user.email;
  }

  void _syncCompanyControllers(AuthSessionModel? session) {
    if (session == null || _isEditingCompany) {
      return;
    }

    final activeCompany = session.activeCompany;

    if (activeCompany == null) {
      _companyNameController.clear();
      _companyEmailController.clear();
      _syncedCompanyId = null;
      _companyName = '';
      _companyEmail = '';
      return;
    }

    final companyChanged =
        _syncedCompanyId != activeCompany.id ||
        _companyName != activeCompany.name ||
        _companyEmail != activeCompany.email;

    if (!companyChanged) {
      return;
    }

    _companyNameController.text = activeCompany.name;
    _companyEmailController.text = activeCompany.email;
    _syncedCompanyId = activeCompany.id;
    _companyName = activeCompany.name;
    _companyEmail = activeCompany.email;
  }

  void _cancelUserEditing(AuthSessionModel session) {
    _userNameController.text = session.user.name;
    _userEmailController.text = session.user.email;
    setState(() => _isEditingUser = false);
  }

  void _saveUserData() {
    if (_isSavingUser) {
      return;
    }

    final session = ref.read(authSessionProvider);
    if (session == null) {
      return;
    }

    setState(() => _isSavingUser = true);

    final user = AuthenticatedUserModel(
      id: session.user.id,
      name: _userNameController.text.trim(),
      email: _userEmailController.text.trim(),
      perfil: session.user.perfil,
    );

    final updatedSession = AuthSessionModel(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      user: user,
      companies: session.companies,
      activeCompanyId: session.activeCompanyId,
    );

    ref.read(authSessionProvider.notifier).setSession(updatedSession);

    _syncedUserId = user.id;
    _syncedUserName = user.name;
    _syncedUserEmail = user.email;

    setState(() {
      _isSavingUser = false;
      _isEditingUser = false;
    });

    _showSessionUpdateMessage('Dados do usuário atualizados nesta sessão.');
  }

  void _cancelCompanyEditing() {
    _companyNameController.text = _companyName;
    _companyEmailController.text = _companyEmail;
    setState(() => _isEditingCompany = false);
  }

  Future<void> _saveCompanyData() async {
    if (_isSavingCompany) {
      return;
    }

    final session = ref.read(authSessionProvider);

    if (session == null || !_canEditCompanyData(session.user)) {
      setState(() => _isEditingCompany = false);
      return;
    }

    setState(() => _isSavingCompany = true);

    try {
      final updatedCompany = await ref
          .read(authRepositoryProvider)
          .updateActiveCompany(
            name: _companyNameController.text,
            email: _companyEmailController.text,
          );

      final updatedCompanies = session.companies
          .map(
            (company) =>
                company.id == updatedCompany.id ? updatedCompany : company,
          )
          .toList(growable: false);

      final updatedSession = AuthSessionModel(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        user: session.user,
        companies: updatedCompanies,
        activeCompanyId: session.activeCompanyId,
      );

      await ref.read(authSessionProvider.notifier).setSession(updatedSession);

      _companyName = updatedCompany.name;
      _companyEmail = updatedCompany.email;

      setState(() {
        _isSavingCompany = false;
        _isEditingCompany = false;
      });

      _showSessionUpdateMessage('Dados da empresa atualizados.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isSavingCompany = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(describeError(error))));
    }
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider).logout();

    if (!mounted) {
      return;
    }

    context.go('/login');
  }

  void _showSessionUpdateMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Campo obrigatório';
    }

    if (!email.contains('@')) {
      return 'Informe um e-mail válido';
    }

    return null;
  }

  bool _canEditCompanyData(AuthenticatedUserModel user) {
    final perfil = user.perfil.trim().toUpperCase();
    return perfil == 'ADMIN' || perfil == 'ROLE_ADMIN';
  }
}

class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard({required this.themeMode});

  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMode = themeMode == ThemeMode.dark
        ? ThemeMode.dark
        : ThemeMode.light;

    return _SettingsCard(
      title: 'Aparência do Sistema',
      child: DropdownButtonFormField<ThemeMode>(
        key: ValueKey(selectedMode),
        initialValue: selectedMode,
        decoration: const InputDecoration(labelText: 'Tema'),
        items: const [
          DropdownMenuItem(value: ThemeMode.light, child: Text('Claro')),
          DropdownMenuItem(value: ThemeMode.dark, child: Text('Escuro')),
        ],
        onChanged: (mode) {
          if (mode == null) {
            return;
          }

          ref.read(appThemeModeProvider.notifier).setThemeMode(mode);
        },
      ),
    );
  }
}

class _EditableSettingsCard extends StatelessWidget {
  const _EditableSettingsCard({
    required this.title,
    required this.canEdit,
    required this.isEditing,
    required this.isLoading,
    required this.onEdit,
    required this.onCancel,
    required this.onSubmit,
    required this.fields,
  });

  final String title;
  final bool canEdit;
  final bool isEditing;
  final bool isLoading;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final List<Widget> fields;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: title,
      trailing: canEdit && !isEditing
          ? AppButton(
              text: 'Editar',
              icon: const Icon(Icons.edit_outlined, size: 18),
              height: 40,
              onPressed: onEdit,
            )
          : null,
      child: AppForm(
        padding: EdgeInsets.zero,
        fields: fields,
        isLoading: isLoading,
        showDefaultActions: canEdit && isEditing,
        onCancel: onCancel,
        onSubmit: onSubmit,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }
}
