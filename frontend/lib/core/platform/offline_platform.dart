import 'package:flutter/foundation.dart';

/// Offline-first (banco local + fila de sincronização) roda apenas no app
/// mobile nativo. Web e desktop continuam no fluxo online direto.
///
/// Observação: não confundir com `MOBILE_WIDTH`, que é só breakpoint de layout.
bool get isOfflineFirstPlatform {
  if (kIsWeb) return false;

  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}
