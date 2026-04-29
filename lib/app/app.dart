
import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class CysvetApp extends StatelessWidget {
  const CysvetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CYSVET',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}