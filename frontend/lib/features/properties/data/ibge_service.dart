import 'package:dio/dio.dart';

import '../domain/ibge_municipio_model.dart';
import '../domain/ibge_uf_model.dart';

class IbgeService {
  IbgeService(this._dio);

  static const baseUrl = 'https://brasilapi.com.br/api/ibge';

  final Dio _dio;

  Future<List<IbgeUfModel>> fetchUfs() async {
    final response = await _dio.get<Object?>('/uf/v1');
    final ufs = _asList(
      response.data,
    ).map(IbgeUfModel.fromMap).toList(growable: false);

    return [...ufs]..sort((a, b) => a.nome.compareTo(b.nome));
  }

  Future<List<IbgeMunicipioModel>> fetchMunicipios(String uf) async {
    final response = await _dio.get<Object?>(
      '/municipios/v1/${uf.trim().toUpperCase()}',
    );
    final municipios = _asList(
      response.data,
    ).map(IbgeMunicipioModel.fromMap).toList(growable: false);

    return [...municipios]..sort((a, b) => a.nome.compareTo(b.nome));
  }

  List<Map<String, dynamic>> _asList(Object? data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (item) => item.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList(growable: false);
    }

    return const [];
  }
}
