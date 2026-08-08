import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/property_summary_model.dart';

final propertiesRepositoryProvider = Provider<PropertiesRepository>((ref) {
  return PropertiesRepository(ref.watch(apiClientProvider));
});

class PropertiesRepository {
  PropertiesRepository(this._dio);

  final Dio _dio;

  Future<List<PropertySummaryModel>> list() async {
    final response = await _dio.get<Object?>('/api/properties');
    final items = _asList(response.data);

    return items
        .map(PropertySummaryModelMapper.fromMap)
        .toList(growable: false);
  }

  Future<PropertySummaryModel> getById(int id) async {
    final response = await _dio.get<Object?>('/api/properties/$id');
    return PropertySummaryModelMapper.fromMap(_asMap(response.data));
  }

  Future<PropertySummaryModel> create(PropertySummaryModel property) async {
    final response = await _dio.post<Object?>(
      '/api/properties',
      data: _toRequest(property),
    );

    return PropertySummaryModelMapper.fromMap(_asMap(response.data));
  }

  Future<PropertySummaryModel> update(PropertySummaryModel property) async {
    final response = await _dio.put<Object?>(
      '/api/properties/${property.id}',
      data: _toRequest(property),
    );

    return PropertySummaryModelMapper.fromMap(_asMap(response.data));
  }

  Future<void> delete(int id) async {
    await _dio.delete<Object?>('/api/properties/$id');
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

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    return const {};
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
