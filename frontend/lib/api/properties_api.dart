import 'package:dio/dio.dart';

import 'package:cysvet_app/api/api_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/core/network/api_client.dart';
import 'package:cysvet_app/models/property_summary_model.dart';

final propertiesRepositoryProvider = Provider<PropertiesRepository>((ref) {
  return PropertiesRepository(ref.watch(apiClientProvider));
});

class PropertiesRepository {
  PropertiesRepository(this._dio);

  final Dio _dio;

  Future<List<PropertySummaryModel>> list() async {
    final response = await _dio.get<Object?>('/api/properties');
    final items = apiList(response.data);

    return items
        .map(PropertySummaryModelMapper.fromMap)
        .toList(growable: false);
  }

  Future<PropertySummaryModel> getById(int id) async {
    final response = await _dio.get<Object?>('/api/properties/$id');
    return PropertySummaryModelMapper.fromMap(apiMap(response.data));
  }

  Future<PropertySummaryModel> create(PropertySummaryModel property) async {
    final response = await _dio.post<Object?>(
      '/api/properties',
      data: _toRequest(property),
    );

    return PropertySummaryModelMapper.fromMap(apiMap(response.data));
  }

  Future<PropertySummaryModel> update(PropertySummaryModel property) async {
    final response = await _dio.put<Object?>(
      '/api/properties/${property.id}',
      data: _toRequest(property),
    );

    return PropertySummaryModelMapper.fromMap(apiMap(response.data));
  }

  Future<void> delete(int id) async {
    await _dio.delete<Object?>('/api/properties/$id');
  }

  Map<String, dynamic> _toRequest(PropertySummaryModel property) {
    return {
      'idExterno': property.idExterno,
      'nome': property.nome,
      'nomeProprietario': property.nomeProprietario,
      'contato': property.contato,
      'cidade': property.cidade,
      'estado': property.estado,
      'observacoes': property.observacoes,
      'status': property.status.apiValue,
      'dataAtualizacaoCliente': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
