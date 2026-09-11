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
      title: user == null ? 'Novo usuário' : 'Editar usuário',
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
  final _password = TextEditingController();

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
    _password.dispose();
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
          } else {
            final payload = UserSummaryModel(
              name: _name.text.trim(),
              email: _email.text.trim(),
              perfil: 'VETERINÁRIO',
              companyName: activeCompany?.name,
              status: UserStatus.active,
            );
            await controller.save(payload, password: _password.text.trim());
          }
          if (mounted) {
            await navigator.maybePop();
            showAppSuccess(
              isEditing
                  ? 'Usuário atualizado com sucesso.'
                  : 'Usuário criado com sucesso.',
            );
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
          textInputAction: isEditing
              ? TextInputAction.done
              : TextInputAction.next,
          validator: _validateEmail,
        ),
        if (!isEditing)
          AppTextField(
            label: 'Senha',
            controller: _password,
            required: true,
            obscureText: true,
            minChars: 6,
            textInputAction: TextInputAction.done,
          ),
      ],
    );
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
