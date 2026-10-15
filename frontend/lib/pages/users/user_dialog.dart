import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/core/enums/user_status.dart';
import 'package:cysvet_app/core/presentation/app_scaffold_messenger.dart';
import 'package:cysvet_app/core/widgets/app_dialog.dart';
import 'package:cysvet_app/core/widgets/app_form.dart';
import 'package:cysvet_app/core/widgets/app_text_field.dart';
import 'package:cysvet_app/providers/auth_state.dart';
import 'package:cysvet_app/models/auth_session_model.dart';
import 'package:cysvet_app/providers/users_provider.dart';
import 'package:cysvet_app/models/user_summary_model.dart';

class UserDialog extends StatelessWidget {
  const UserDialog({super.key, this.user});

  final UserSummaryModel? user;

  static Future<void> show(BuildContext context, {UserSummaryModel? user}) {
    return AppDialog.show<void>(
      context: context,
      title: user == null ? 'Novo membro da equipe' : 'Editar membro',
      width: 560,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      fullscreenBodyPadding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      headerIndent: 16,
      useInternalScroll: true,
      fullscreenOnMobile: true,
      content: UserDialog(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _UserForm(user: user);
  }
}

class _UserForm extends ConsumerStatefulWidget {
  const _UserForm({this.user});

  final UserSummaryModel? user;

  @override
  ConsumerState<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends ConsumerState<_UserForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _name.text = user?.name ?? '';
    _email.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = ref.watch(usersBusyProvider);
    final session = ref.watch(authSessionProvider);
    final user = widget.user;
    final isEditing = user != null;

    return AppForm(
      internalScroll: true,
      isLoading: isBusy,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      fieldsSpacing: 14,
      actionsSpacing: 10,
      actionButtonHeight: 38,
      actionButtonFontSize: 14,
      actionButtonPadding: const EdgeInsets.symmetric(horizontal: 14),
      submitText: 'Salvar',
      onCancel: () => Navigator.of(context).maybePop(),
      onSubmit: () async {
        final activeCompany = session?.activeCompany;
        final navigator = Navigator.of(context);
        try {
          final controller = ref.read(usersControllerProvider);
          if (isEditing) {
            final payload = user.copyWith(
              name: _name.text.trim(),
              email: _email.text.trim(),
            );
            await controller.update(payload);
            if (mounted) {
              await navigator.maybePop();
              showAppSuccess('Membro atualizado com sucesso.');
            }
            return;
          }

          final payload = UserSummaryModel(
            name: _name.text.trim(),
            email: _email.text.trim(),
            companyName: activeCompany?.name,
            status: UserStatus.active,
          );
          final result = await controller.save(payload);
          if (mounted) {
            await navigator.maybePop();
            _showCreateResult(result);
          }
        } catch (error) {
          showAppError(error);
        }
      },
      fields: [
        AppTextField(
          label: 'Nome',
          controller: _name,
          required: true,
          textInputAction: TextInputAction.next,
        ),
        AppTextField(
          label: 'E-mail',
          controller: _email,
          required: true,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          validator: _validateEmail,
        ),
        if (!isEditing)
          Text(
            'O novo membro entra como veterinário e recebe uma senha '
            'provisória neste e-mail. No primeiro acesso ele define a '
            'própria senha.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  void _showCreateResult(CreateUserResult result) {
    if (result.existingAccount) {
      showAppSuccess(
        '${result.user.name} já tinha conta no CYSVET e foi adicionado à '
        'equipe. Ele entra com a senha que já usa.',
      );
    } else if (result.emailSent) {
      showAppSuccess(
        'Membro adicionado. A senha provisória foi enviada para '
        '${result.user.email}.',
      );
    } else {
      showTypedAppSnackBar(
        'Membro adicionado, mas o e-mail com a senha não foi enviado. '
        'Use "Reenviar acesso" na lista da equipe.',
        type: AppSnackBarType.warning,
        duration: const Duration(seconds: 6),
      );
    }
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
}
