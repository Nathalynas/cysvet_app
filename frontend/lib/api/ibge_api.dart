import 'package:dio/dio.dart';

import 'package:cysvet_app/api/api_response.dart';

import 'package:cysvet_app/models/ibge_municipio_model.dart';
import 'package:cysvet_app/models/ibge_uf_model.dart';

class IbgeService {
  IbgeService(this._dio);

  static const baseUrl = 'https://brasilapi.com.br/api/ibge';

  final Dio _dio;

  Future<List<IbgeUfModel>> fetchUfs() async {
    final response = await _dio.get<Object?>('/uf/v1');
    final ufs = apiList(
      response.data,
    ).map(IbgeUfModel.fromMap).toList(growable: false);

    return [...ufs]..sort((a, b) => a.nome.compareTo(b.nome));
  }

  Future<List<IbgeMunicipioModel>> fetchMunicipios(String uf) async {
    final response = await _dio.get<Object?>(
      '/municipios/v1/${uf.trim().toUpperCase()}',
    );
    final municipios = apiList(
      response.data,
    ).map(IbgeMunicipioModel.fromMap).toList(growable: false);

    return [...municipios]..sort((a, b) => a.nome.compareTo(b.nome));
  }
}
