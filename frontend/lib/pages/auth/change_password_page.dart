import 'package:cysvet_app/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/api/account_api.dart';
import 'package:cysvet_app/core/presentation/app_scaffold_messenger.dart';
import 'package:cysvet_app/core/widgets/app_button.dart';
import 'package:cysvet_app/core/widgets/app_text_field.dart';
import 'package:cysvet_app/providers/auth_state.dart';

const _authPrimaryColor = AppTheme.primary1Color;

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _showPassword = false;
  bool _saving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(accountRepositoryProvider)
          .changeRequiredPassword(_passwordController.text);
      // O roteador redireciona para o destino assim que trocarSenha for false.
      await ref.read(authSessionProvider.notifier).markPasswordChanged();
    } catch (error) {
      if (mounted) {
        showAppError(error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBusy = _saving || ref.watch(authBusyProvider);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Defina sua senha',
            style: theme.textTheme.titleMedium?.copyWith(
              color: _authPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Por segurança, troque a senha provisória antes de continuar.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.mutedTextColor,
              fontSize: 10.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18),
          AppTextField(
            controller: _passwordController,
            enabled: !isBusy,
            required: true,
            label: 'Nova senha',
            obscureText: !_showPassword,
            textInputAction: TextInputAction.next,
            fillColor: Colors.white,
            borderColor: AppTheme.borderColor.withValues(alpha: 0.7),
            focusedBorderColor: _authPrimaryColor,
            suffixIcon: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isBusy
                  ? null
                  : () => setState(() => _showPassword = !_showPassword),
              child: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
                size: 17,
                color: AppTheme.mutedTextColor,
              ),
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: 13),
          AppTextField(
            controller: _confirmController,
            enabled: !isBusy,
            required: true,
            label: 'Confirmar senha',
            obscureText: !_showPassword,
            textInputAction: TextInputAction.done,
            fillColor: Colors.white,
            borderColor: AppTheme.borderColor.withValues(alpha: 0.7),
            focusedBorderColor: _authPrimaryColor,
            validator: _validateConfirmation,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Salvar senha',
            loading: isBusy,
            disabled: isBusy,
            expanded: true,
            height: 36,
            borderRadius: 9,
            onPressed: _submit,
          ),
          const SizedBox(height: 11),
          Center(
            child: TextButton(
              onPressed: isBusy
                  ? null
                  : () => ref.read(authControllerProvider).logout(),
              child: const Text('Sair'),
            ),
          ),
        ],
      ),
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe a nova senha.';
    }
    if (value.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value != _passwordController.text) {
      return 'As senhas não conferem.';
    }
    return null;
  }
}
