import 'package:cysvet_app/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/presentation/app_scaffold_messenger.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
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

  bool get isMobile => MediaQuery.sizeOf(context).width < MOBILE_WIDTH;

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

          showAppSnackBar(
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
    final form = _buildLoginForm(context, isBusy);

    return Scaffold(
      backgroundColor: isMobile ? AppTheme.primaryColor : AppTheme.neutralColor,
      body: isMobile
          ? _MobileLoginLayout(form: form)
          : _DesktopLoginLayout(form: form),
    );
  }

  Widget _buildLoginForm(BuildContext context, bool isBusy) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 260,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Acesso ao Sistema',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryColor,
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
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            fillColor: Colors.white,
            borderColor: AppTheme.borderColor.withValues(alpha: 0.7),
            focusedBorderColor: AppTheme.primaryColor,
            borderRadius: 7,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            suffixIconConstraints: const BoxConstraints.tightFor(
              width: 38,
              height: 38,
            ),
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
            focusedBorderColor: AppTheme.primaryColor,
            borderRadius: 7,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            suffixIconConstraints: const BoxConstraints.tightFor(
              width: 38,
              height: 38,
            ),
            suffixIcon: IconButton(
              tooltip: _showPassword ? 'Ocultar senha' : 'Mostrar senha',
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
                size: 17,
                color: AppTheme.mutedTextColor,
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
          const SizedBox(height: 28),
          const Align(alignment: Alignment.center, child: _OfflineFirstBadge()),
          const SizedBox(height: 22),
          if (isMobile)
            Text(
              'CYSVET © 2026 • Tecnologia Veterinária Avançada',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.mutedTextColor,
                fontSize: 9,
                height: 1.25,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormOptions(BuildContext context, bool isBusy) {
    final theme = Theme.of(context);

    final optionTextStyle = theme.textTheme.labelMedium?.copyWith(
      color: AppTheme.mutedTextColor,
      fontSize: 10.5,
      fontWeight: FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(
            text: 'Esqueceu a senha?',
            outlined: true,
            padding: EdgeInsets.zero,
            color: Colors.transparent,
            textColor: AppTheme.primaryColor,
            borderColor: Colors.transparent,
            fontWeight: FontWeight.w700,
            height: 24,
            borderRadius: 0,
            onPressed: isBusy ? null : _openForgotPasswordDialog,
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
                activeColor: AppTheme.primaryColor,
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

class _DesktopLoginLayout extends StatelessWidget {
  const _DesktopLoginLayout({required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(flex: 4, child: _HeroPanel()),
          Expanded(
            flex: 5,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 34,
                      vertical: 30,
                    ),
                    borderRadius: 24,
                    backgroundColor: AppTheme.cardColor,
                    borderColor: Colors.transparent,
                    shadow: true,
                    child: SizedBox(width: 350, child: form),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileLoginLayout extends StatelessWidget {
  const _MobileLoginLayout({required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
            child: SizedBox(height: 160, child: _MobileHeaderImage()),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
              decoration: const BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: form,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(42),
          bottomRight: Radius.circular(42),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(8, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(42),
          bottomRight: Radius.circular(42),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/cow.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
            ),
            Container(color: AppTheme.primaryColor.withValues(alpha: 0.35)),
            const _HeroGradientOverlay(),
            const _HeroContent(),
          ],
        ),
      ),
    );
  }
}

class _HeroGradientOverlay extends StatelessWidget {
  const _HeroGradientOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.18),
                AppTheme.primaryColor.withValues(alpha: 0.78),
                AppTheme.primaryColor,
              ],
              stops: const [0.0, 0.72, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.10),
                Colors.transparent,
                AppTheme.primaryColor.withValues(alpha: 0.78),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(52, 58, 42, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/logo_branco.png',
            width: 150,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  height: 1.18,
                ),
                children: const [
                  TextSpan(text: 'Gestão reprodutiva\n'),
                  TextSpan(text: 'inteligente para\n'),
                  TextSpan(text: 'a '),
                  TextSpan(
                    text: 'assessoria veterinária em campo.',
                    style: TextStyle(color: AppTheme.tertiary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 72,
            height: 3,
            decoration: BoxDecoration(
              color: AppTheme.tertiary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Text(
              'Acompanhe rebanhos, visitas técnicas, protocolos hormonais '
              'e indicadores zootécnicos em um só lugar — mesmo sem '
              'internet, com sincronização automática e relatórios prontos '
              'em poucos cliques.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'CYSVET © 2026 • Tecnologia Veterinária Avançada',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileHeaderImage extends StatelessWidget {
  const _MobileHeaderImage();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/cow.png',
          fit: BoxFit.cover,
          alignment: const Alignment(0, 0.35),
        ),
        Container(color: AppTheme.primaryColor.withValues(alpha: 0.35)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.05),
                AppTheme.primaryColor.withValues(alpha: 0.25),
                AppTheme.primaryColor.withValues(alpha: 0.55),
              ],
              stops: const [0.0, 0.58, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _OfflineFirstBadge extends StatelessWidget {
  const _OfflineFirstBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.tertiary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sync,
              size: 12,
              color: AppTheme.primaryColor.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 7),
            Text(
              'MODO OFFLINE-FIRST ATIVO',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.primaryColor,
                fontSize: 8.8,
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
