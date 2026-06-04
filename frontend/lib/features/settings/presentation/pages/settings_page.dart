import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dropdown.dart';
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            _AppearanceCard(themeMode: themeMode),

            const SizedBox(height: 16),

            _EditableSettingsCard(
              title: 'Meus Dados',
              subtitle: 'Informações básicas do seu usuário.',
              canEdit: true,
              isEditing: _isEditingUser,
              isLoading: _isSavingUser,
              onEdit: () => setState(() => _isEditingUser = true),
              onCancel: () => _cancelUserEditing(session),
              onSubmit: _saveUserData,
              fields: [
                ..._buildUserFields(isEditing: _isEditingUser),
                _InfoRow(label: 'Perfil', value: session.user.displayRole),
              ],
            ),

            const SizedBox(height: 16),

            _SettingsCard(
              title: 'Empresa Ativa',
              subtitle: 'Selecione a empresa usada nesta sessão.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppDropdown<int>(
                    value: activeCompany?.id,
                    labelText: 'Empresa',
                    options: session.companies
                        .map(
                          (company) => AppDropdownOption<int>(
                            label: company.name,
                            value: company.id,
                          ),
                        )
                        .toList(growable: false),
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
                ],
              ),
            ),

            const SizedBox(height: 16),

            _EditableSettingsCard(
              title: 'Dados da Empresa',
              subtitle: canEditCompanyData
                  ? 'Gerencie as informações da empresa ativa.'
                  : 'Você não tem permissão para editar estes dados.',
              canEdit: canEditCompanyData,
              isEditing: _isEditingCompany,
              isLoading: _isSavingCompany,
              onEdit: () => setState(() => _isEditingCompany = true),
              onCancel: _cancelCompanyEditing,
              onSubmit: _saveCompanyData,
              fields: _buildCompanyFields(
                canEdit: canEditCompanyData,
                isEditing: _isEditingCompany,
              ),
            ),

            const SizedBox(height: 20),

            _LogoutCard(isBusy: isBusy, onLogout: _logout),
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
      title: 'Preferências do Sistema',
      subtitle: 'Personalize a aparência da interface.',
      breakTrailingOnMobile: true,
      trailing: _ThemeSegmentedSelector(
        value: selectedMode,
        onChanged: (mode) {
          ref.read(appThemeModeProvider.notifier).setThemeMode(mode);
        },
      ),
    );
  }
}

class _ThemeSegmentedSelector extends StatelessWidget {
  const _ThemeSegmentedSelector({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 38,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeSegmentButton(
            label: 'Claro',
            icon: Icons.wb_sunny_outlined,
            selected: value == ThemeMode.light,
            onTap: () => onChanged(ThemeMode.light),
          ),
          _ThemeSegmentButton(
            label: 'Escuro',
            icon: Icons.dark_mode_outlined,
            selected: value == ThemeMode.dark,
            onTap: () => onChanged(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _ThemeSegmentButton extends StatelessWidget {
  const _ThemeSegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final selectedBackground = colorScheme.surface;
    final selectedBorder = colorScheme.outline.withValues(alpha: 0.16);

    final foreground = selected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: selected ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? selectedBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: selected ? Border.all(color: selectedBorder) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
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
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool canEdit;
  final bool isEditing;
  final bool isLoading;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final List<Widget> fields;

  static const double _actionButtonHeight = 34;
  static const double _actionButtonFontSize = 13;
  static const double _actionIconSize = 16;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: title,
      subtitle: subtitle,
      trailing: canEdit && !isEditing
          ? AppButton(
              text: 'Editar',
              icon: const Icon(Icons.edit_outlined, size: _actionIconSize),
              height: _actionButtonHeight,
              fontSize: _actionButtonFontSize,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              onPressed: onEdit,
            )
          : null,
      child: AppForm(
        padding: EdgeInsets.zero,
        fields: fields,
        isLoading: isLoading,
        showDefaultActions: canEdit && isEditing,
        actionButtonHeight: _actionButtonHeight,
        actionButtonFontSize: _actionButtonFontSize,
        actionButtonPadding: const EdgeInsets.symmetric(horizontal: 12),
        actionsSpacing: 8,
        onCancel: onCancel,
        onSubmit: onSubmit,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    this.subtitle,
    this.trailing,
    this.child,
    this.breakTrailingOnMobile = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? child;
  final bool breakTrailingOnMobile;

  static const double _mobileBreakpoint = 560;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(20),
      shadow: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shouldBreakTrailing =
              breakTrailingOnMobile && constraints.maxWidth < _mobileBreakpoint;

          final titleContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (trailing == null)
                titleContent
              else if (shouldBreakTrailing)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleContent,
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerLeft, child: trailing!),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: titleContent),
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ),
              if (child != null) ...[const SizedBox(height: 18), child!],
            ],
          );
        },
      ),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.isBusy, required this.onLogout});

  final bool isBusy;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      shadow: true,
      borderColor: colorScheme.error.withValues(alpha: 0.35),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Encerrar sessão',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AppButton(
            text: 'Sair',
            icon: const Icon(Icons.logout, size: 18),
            color: colorScheme.error,
            loading: isBusy,
            outlined: true,
            disabled: isBusy,
            height: 42,
            onPressed: onLogout,
          ),
        ],
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
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
