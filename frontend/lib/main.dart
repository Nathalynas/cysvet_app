import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/auth/application/auth_state.dart';
import 'features/auth/data/auth_session_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialSession = await const AuthSessionStorage().read();

  runApp(
    ProviderScope(
      overrides: [authInitialSessionProvider.overrideWithValue(initialSession)],
      child: const CysvetApp(),
    ),
  );
}
