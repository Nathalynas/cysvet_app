import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/presentation/app_scaffold_messenger.dart';
import '../core/update/app_update.dart';
import 'router.dart';
import 'theme.dart';

class CysvetApp extends ConsumerWidget {
  const CysvetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp.router(
      title: 'CYSVET',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // Calendário e textos padrão do Material em português.
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
      builder: (context, child) => AppUpdateGate(child: child!),
    );
  }
}
