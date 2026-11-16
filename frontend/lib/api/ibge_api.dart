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

  /// API oficial do IBGE, usada quando a BrasilAPI falha (a rota de
  /// municípios dela repassa a consulta ao IBGE e às vezes cai).
  static const ibgeOficialUrl =
      'https://servicodados.ibge.gov.br/api/v1/localidades/estados';

  Future<List<IbgeMunicipioModel>> fetchMunicipios(String uf) async {
    final sigla = uf.trim().toUpperCase();
    List<IbgeMunicipioModel> municipios;
    try {
      final response = await _dio.get<Object?>('/municipios/v1/$sigla');
      municipios = apiList(
        response.data,
      ).map(IbgeMunicipioModel.fromMap).toList(growable: false);
      if (municipios.isEmpty) throw StateError('Lista de cidades vazia.');
    } catch (_) {
      final response = await _dio.get<Object?>(
        '$ibgeOficialUrl/$sigla/municipios',
      );
      // Mesmo formato da BrasilAPI (nome em maiúsculas), para a cidade salva
      // não mudar conforme a fonte.
      municipios = apiList(response.data)
          .map(
            (item) => IbgeMunicipioModel(
              nome: item['nome']?.toString().toUpperCase() ?? '',
              codigoIbge: item['id']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    }

    return [...municipios]..sort((a, b) => a.nome.compareTo(b.nome));
  }
}
