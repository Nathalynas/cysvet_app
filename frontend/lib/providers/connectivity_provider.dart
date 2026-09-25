import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/core/platform/offline_platform.dart';

/// `true` quando o aparelho tem alguma interface de rede ativa.
///
/// Não garante que o backend esteja acessível (Wi-Fi sem internet, por
/// exemplo); por isso as chamadas ainda tratam `isNetworkError` e caem para o
/// banco local. Fora do mobile é sempre `true`, mantendo o fluxo online atual.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  if (!isOfflineFirstPlatform) {
    yield true;
    return;
  }

  final connectivity = Connectivity();
  yield _hasConnection(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(_hasConnection).distinct();
});

/// Leitura síncrona para UI: enquanto o stream não emite, assume online.
final isOfflineProvider = Provider<bool>((ref) {
  return ref.watch(isOnlineProvider).asData?.value == false;
});

bool _hasConnection(List<ConnectivityResult> results) {
  return results.any((result) => result != ConnectivityResult.none);
}
