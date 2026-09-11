import 'package:cysvet_app/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cysvet_app/core/network/api_error.dart';
import 'package:cysvet_app/core/widgets/app_button.dart';
import 'package:cysvet_app/core/widgets/app_text_field.dart';
import 'package:cysvet_app/providers/auth_state.dart';

const _authPrimaryColor = AppTheme.primary1Color;

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await ref
          .read(authControllerProvider)
          .register(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          );

      if (!mounted) {
        return;
      }

      context.go('/dashboard');
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(describeError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = ref.watch(authBusyProvider);
    return _buildRegisterForm(context, isBusy);
  }

  Widget _buildRegisterForm(BuildContext context, bool isBusy) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cadastro',
            style: theme.textTheme.titleMedium?.copyWith(
              color: _authPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Cadastre o administrador da empresa.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.mutedTextColor,
              fontSize: 10.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18),
          AppTextField(
            controller: _nameController,
            enabled: !isBusy,
            required: true,
            label: 'Nome',
            textInputAction: TextInputAction.next,
            fillColor: Colors.white,
            borderColor: AppTheme.borderColor.withValues(alpha: 0.7),
            focusedBorderColor: _authPrimaryColor,
            suffixIcon: const Icon(
              Icons.person_outline,
              size: 17,
              color: AppTheme.mutedTextColor,
            ),
            validator: _validateName,
          ),
          const SizedBox(height: 13),
          AppTextField(
            controller: _emailController,
            enabled: !isBusy,
            required: true,
            label: 'E-mail',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            fillColor: Colors.white,
            borderColor: AppTheme.borderColor.withValues(alpha: 0.7),
            focusedBorderColor: _authPrimaryColor,
            suffixIcon: const Icon(
              Icons.email_outlined,
              size: 17,
              color: AppTheme.mutedTextColor,
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 13),
          AppTextField(
            controller: _passwordController,
            enabled: !isBusy,
            required: true,
            label: 'Senha',
            obscureText: !_showPassword,
            textInputAction: TextInputAction.next,
            fillColor: Colors.white,
            borderColor: AppTheme.borderColor.withValues(alpha: 0.7),
            focusedBorderColor: _authPrimaryColor,
            suffixIcon: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isBusy
                  ? null
                  : () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
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
            controller: _confirmPasswordController,
            enabled: !isBusy,
            required: true,
            label: 'Confirmar senha',
            obscureText: !_showConfirmPassword,
            textInputAction: TextInputAction.done,
            fillColor: Colors.white,
            borderColor: AppTheme.borderColor.withValues(alpha: 0.7),
            focusedBorderColor: _authPrimaryColor,
            suffixIcon: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isBusy
                  ? null
                  : () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
              child: Icon(
                _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                size: 17,
                color: AppTheme.mutedTextColor,
              ),
            ),
            validator: _validateConfirmPassword,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Criar conta',
            trailingIcon: const Icon(Icons.person_add_alt_1, size: 15),
            loading: isBusy,
            disabled: isBusy,
            expanded: true,
            height: 36,
            borderRadius: 9,
            onPressed: _submit,
          ),
          const SizedBox(height: 11),
          AppButton(
            text: 'Voltar para login',
            outlined: true,
            disabled: isBusy,
            expanded: true,
            height: 36,
            borderRadius: 9,
            onPressed: () => context.go('/login'),
          ),
          const SizedBox(height: 16),
          Text(
            'O cadastro cria o primeiro usuário como administrador da empresa.',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.mutedTextColor,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o nome.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Informe o e-mail.';
    }

    if (!email.contains('@')) {
      return 'Informe um e-mail válido.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe a senha.';
    }
    if (value.length < 6) {
      return 'Use pelo menos 6 caracteres.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme a senha.';
    }
    if (value != _passwordController.text) {
      return 'As senhas não conferem.';
    }
    return null;
  }
}
