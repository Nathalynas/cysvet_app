import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_card.dart';

class AuthPageShell extends StatelessWidget {
  const AuthPageShell({super.key, required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < MOBILE_WIDTH;
    final cardContent = _AuthCardContent(form: form, isMobile: isMobile);

    return Scaffold(
      backgroundColor: isMobile
          ? AppTheme.primaryColor
          : AppTheme.backgroundColor,
      body: isMobile
          ? _MobileAuthLayout(form: cardContent)
          : _DesktopAuthLayout(form: cardContent),
    );
  }
}

class _AuthCardContent extends StatelessWidget {
  const _AuthCardContent({required this.form, required this.isMobile});

  final Widget form;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Image.asset(
            AppAssets.companyLogo,
            width: 260,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 30),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 140),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(
              key: ValueKey<Type>(form.runtimeType),
              child: form,
            ),
          ),
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
    );
  }
}

class _DesktopAuthLayout extends StatelessWidget {
  const _DesktopAuthLayout({required this.form});

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

class _MobileAuthLayout extends StatelessWidget {
  const _MobileAuthLayout({required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
            child: SizedBox(height: 130, child: _MobileHeaderImage()),
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
                  TextSpan(text: 'Gestão reprodutiva simples\n'),
                  TextSpan(text: 'e precisa, '),
                  TextSpan(
                    text: 'feita para o campo.',
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
              'Acompanhe rebanhos, registre visitas, protocolos e intercorrências, consulte indicadores e gere relatórios — mesmo sem internet',
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
