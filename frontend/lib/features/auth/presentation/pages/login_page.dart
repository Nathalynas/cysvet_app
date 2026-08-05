import 'package:cysvet_app/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/presentation/app_scaffold_messenger.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../application/auth_state.dart';

const _authPrimaryColor = AppTheme.primary1Color;

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _keepConnected = false;
  bool _showPassword = false;
  bool _forgotPasswordHovered = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await ref
          .read(authControllerProvider)
          .login(
            email: _emailController.text.trim(),
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

  Future<void> _openForgotPasswordDialog() async {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    void submitRecovery() {
      final email = emailController.text.trim();

      Navigator.of(context).maybePop();

      showAppSnackBar(
        SnackBar(
          content: Text(
            'Recuperação preparada para $email. Integração de envio pendente.',
          ),
        ),
      );
    }

    try {
      await AppDialog.show<void>(
        context: context,
        title: 'Recuperar senha',
        subtitle: 'Informe o e-mail cadastrado para iniciar a recuperação.',
        content: AppForm(
          padding: EdgeInsets.zero,
          fieldsSpacing: 16,
          actionButtonHeight: 40,
          actionButtonFontSize: 14,
          actionButtonPadding: const EdgeInsets.symmetric(horizontal: 16),
          cancelText: 'Cancelar',
          submitText: 'Enviar',
          onCancel: () => Navigator.of(context).maybePop(),
          onSubmit: submitRecovery,
          fields: [
            AppTextField(
              controller: emailController,
              label: 'E-mail',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              suffixIcon: const Icon(
                Icons.email_outlined,
                size: 17,
                color: AppTheme.mutedTextColor,
              ),
              validator: _validateEmail,
            ),
          ],
        ),
      );
    } finally {
      emailController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = ref.watch(authBusyProvider);
    return _buildLoginForm(context, isBusy);
  }

  Widget _buildLoginForm(BuildContext context, bool isBusy) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Acesso ao Sistema',
            style: theme.textTheme.titleMedium?.copyWith(
              color: _authPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Bem-vindo à gestão reprodutiva inteligente.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.mutedTextColor,
              fontSize: 10.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18),
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
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          _buildFormOptions(context, isBusy),
          const SizedBox(height: 16),
          AppButton(
            text: 'Entrar',
            trailingIcon: const Icon(Icons.arrow_forward, size: 15),
            loading: isBusy,
            disabled: isBusy,
            expanded: true,
            height: 36,
            borderRadius: 9,
            onPressed: _submit,
          ),
          const SizedBox(height: 11),
          AppButton(
            text: 'Criar conta',
            outlined: true,
            disabled: isBusy,
            expanded: true,
            height: 36,
            borderRadius: 9,
            onPressed: () => context.go('/register'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormOptions(BuildContext context, bool isBusy) {
    final theme = Theme.of(context);

    final optionTextStyle = theme.textTheme.labelMedium?.copyWith(
      color: AppTheme.mutedTextColor,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: MouseRegion(
            cursor: isBusy
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            onEnter: (_) {
              if (!isBusy) {
                setState(() {
                  _forgotPasswordHovered = true;
                });
              }
            },
            onExit: (_) {
              if (!isBusy) {
                setState(() {
                  _forgotPasswordHovered = false;
                });
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: isBusy ? null : _openForgotPasswordDialog,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Esqueceu a senha?',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isBusy ? AppTheme.mutedTextColor : _authPrimaryColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    decoration: _forgotPasswordHovered
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: _authPrimaryColor,
                    decorationThickness: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: _keepConnected,
                mouseCursor: isBusy
                    ? SystemMouseCursors.basic
                    : SystemMouseCursors.click,
                onChanged: isBusy
                    ? null
                    : (value) {
                        setState(() {
                          _keepConnected = value ?? false;
                        });
                      },
                activeColor: _authPrimaryColor,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: const BorderSide(
                  color: AppTheme.mutedTextColor,
                  width: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: MouseRegion(
                cursor: isBusy
                    ? SystemMouseCursors.basic
                    : SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isBusy
                      ? null
                      : () {
                          setState(() {
                            _keepConnected = !_keepConnected;
                          });
                        },
                  child: Text(
                    'Manter conectado',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: optionTextStyle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
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

    return null;
  }
}
