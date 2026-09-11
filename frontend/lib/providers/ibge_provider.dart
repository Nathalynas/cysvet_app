import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/api/ibge_api.dart';
import 'package:cysvet_app/models/ibge_municipio_model.dart';
import 'package:cysvet_app/models/ibge_uf_model.dart';

final ibgeDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: IbgeService.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {'Accept': 'application/json'},
    ),
  );

  ref.onDispose(dio.close);
  return dio;
});

final ibgeServiceProvider = Provider<IbgeService>((ref) {
  return IbgeService(ref.watch(ibgeDioProvider));
});

final ibgeUfsProvider = FutureProvider<List<IbgeUfModel>>((ref) {
  return ref.watch(ibgeServiceProvider).fetchUfs();
});

final ibgeMunicipiosProvider =
    FutureProvider.family<List<IbgeMunicipioModel>, String>((ref, uf) {
      final normalizedUf = uf.trim().toUpperCase();
      if (normalizedUf.isEmpty) return const [];

      return ref.watch(ibgeServiceProvider).fetchMunicipios(normalizedUf);
    });
