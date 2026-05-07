import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../application/auth_state.dart';

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

  Future<void> _openForgotPasswordDialog() async {
    final dialogFormKey = GlobalKey<FormState>();
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    try {
      await AppDialog.show<void>(
        context: context,
        title: 'Recuperar senha',
        subtitle: 'Informe o email cadastrado para iniciar a recuperação.',
        content: Form(
          key: dialogFormKey,
          child: AppTextField(
            controller: emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: _validateEmail,
          ),
        ),
        cancelText: 'Cancelar',
        confirmText: 'Enviar',
        onConfirm: () {
          if (!(dialogFormKey.currentState?.validate() ?? false)) {
            return;
          }

          final email = emailController.text.trim();
          Navigator.of(context).maybePop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Recuperação preparada para $email. Integração de envio pendente.',
              ),
            ),
          );
        },
      );
    } finally {
      emailController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = ref.watch(authBusyProvider);
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < MOBILE_WIDTH;
    final horizontalPadding = isMobile ? 24.0 : 48.0;
    final verticalPadding = isMobile ? 24.0 : 40.0;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceBright,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minHeight = constraints.maxHeight - (verticalPadding * 2);

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: minHeight > 0 ? minHeight : 0,
                ),
                child: Center(
                  child: isMobile
                      ? _buildMobileLogin(context, isBusy)
                      : _buildDesktopLogin(context, isBusy),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileLogin(BuildContext context, bool isBusy) {
  final theme = Theme.of(context);

  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: _buildLoginForm(context, isBusy, compact: true),
      ),
    ),
  );
}

  Widget _buildDesktopLogin(BuildContext context, bool isBusy) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.55),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 520,
            child: Row(
              children: [
                Expanded(
                  child: ColoredBox(
                    color: theme.colorScheme.surface,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: _buildLoginForm(context, isBusy),
                      ),
                    ),
                  ),
                ),
                const Expanded(child: _LoginInfoPanel()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(
    BuildContext context,
    bool isBusy, {
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: SizedBox(
                width: compact ? 220.0 : 200.0,
                height: compact ? 80.0 : 70.0,
                child: Transform.scale(
                  scale: 1.3,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Acesso ao Sistema',
            textAlign: TextAlign.left,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bem-vindo à gestão reprodutiva inteligente.',
            textAlign: TextAlign.left,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          AppTextField(
            controller: _emailController,
            enabled: !isBusy,
            required: true,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            fillColor: colorScheme.surfaceContainerHighest,
            borderColor: colorScheme.outline.withValues(alpha: 0.7),
            focusedBorderColor: colorScheme.primary,
            borderRadius: 8,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _passwordController,
            required: true,
            enabled: !isBusy,
            label: 'Senha',
            obscureText: !_showPassword,
            textInputAction: TextInputAction.done,
            fillColor: colorScheme.surfaceContainerHighest,
            borderColor: colorScheme.outline.withValues(alpha: 0.7),
            focusedBorderColor: colorScheme.primary,
            borderRadius: 8,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            suffixIconConstraints: const BoxConstraints.tightFor(
              width: 40,
              height: 40,
            ),
            suffixIcon: IconButton(
              tooltip: _showPassword ? 'Ocultar senha' : 'Mostrar senha',
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
                size: 18,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              onPressed: isBusy
                  ? null
                  : () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
            ),
            validator: _validatePassword,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),
          _buildFormOptions(context, isBusy),
          const SizedBox(height: 18),
          AppButton(
            text: 'Entrar',
            trailingIcon: const Icon(Icons.arrow_forward, size: 16),
            loading: isBusy,
            disabled: isBusy,
            expanded: true,
            height: 38,
            borderRadius: 8,
            onPressed: _submit,
          ),
          const SizedBox(height: 12),
          AppButton(
            text: 'Criar conta',
            outlined: true,
            disabled: isBusy,
            expanded: true,
            height: 38,
            borderRadius: 8,
            onPressed: () => context.go('/register'),
          ),
          const SizedBox(height: 28),
          const Align(alignment: Alignment.center, child: _OfflineFirstBadge()),
          const SizedBox(height: 20),
          Text(
            'CYSVET © 2026 • Tecnologia Veterinária Avançada',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormOptions(BuildContext context, bool isBusy) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final commonTextStyle = theme.textTheme.labelMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: isBusy ? null : _openForgotPasswordDialog,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              foregroundColor: colorScheme.primary,
              enabledMouseCursor: SystemMouseCursors.click,
              disabledMouseCursor: SystemMouseCursors.basic,
              textStyle: commonTextStyle?.copyWith(fontWeight: FontWeight.w700),
            ),
            child: const Text('Esqueceu a senha?'),
          ),
        ),
        const SizedBox(height: 8),
        MouseRegion(
          cursor: isBusy ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _keepConnected,
                  mouseCursor: WidgetStateMouseCursor.clickable,
                  onChanged: isBusy
                      ? null
                      : (value) {
                          setState(() {
                            _keepConnected = value ?? false;
                          });
                        },
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
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
                    style: commonTextStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o e-mail.';
    }
    if (!value.contains('@')) {
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

class _LoginInfoPanel extends StatelessWidget {
  const _LoginInfoPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 58),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _LoginInfoCard(
              icon: Icons.assignment_outlined,
              title: 'Histórico Digital Integrado:',
              description:
                  'Substitua as planilhas de papel pelo registro prático de atendimentos e protocolos hormonais.',
            ),
            SizedBox(height: 28),
            _LoginInfoCard(
              icon: Icons.sync,
              title: 'Arquitetura Offline-First:',
              description:
                  'Registre todas as informações sem internet. O aplicativo sincroniza tudo de forma automática.',
            ),
            SizedBox(height: 28),
            _LoginInfoCard(
              icon: Icons.description_outlined,
              title: 'Relatórios Automatizados:',
              description:
                  'Gere documentos técnicos e relatórios zootécnicos com apenas um clique após a visita técnica.',
            ),
            SizedBox(height: 28),
            _LoginInfoCard(
              icon: Icons.analytics_outlined,
              title: 'Precisão no Campo:',
              description:
                  'Acompanhe índices reprodutivos em tempo real com sincronização automática.',
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginInfoCard extends StatelessWidget {
  const _LoginInfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onPrimary = colorScheme.onPrimary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: onPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: onPrimary.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.secondary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onPrimary,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                  children: [
                    TextSpan(
                      text: '$title ',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: description),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineFirstBadge extends StatelessWidget {
  const _OfflineFirstBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sync, size: 12, color: colorScheme.primary),
            const SizedBox(width: 7),
            Text(
              'MODO OFFLINE-FIRST ATIVO',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

