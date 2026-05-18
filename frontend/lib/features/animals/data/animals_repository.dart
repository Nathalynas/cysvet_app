import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/animal_status.dart';
import '../../../core/network/api_client.dart';
import '../domain/animal_summary_model.dart';

final animalsRepositoryProvider = Provider<AnimalsRepository>((ref) {
  return AnimalsRepository(ref.watch(apiClientProvider));
});

class AnimalsRepository {
  AnimalsRepository(this._dio);

  final Dio _dio;

  Future<List<AnimalSummaryModel>> list({int? propertyId}) async {
    final response = await _dio.get<Object?>(
      '/api/animals',
      queryParameters: {
        ...?propertyId != null ? {'idPropriedade': propertyId} : null,
      },
    );

    final items = _asList(response.data);
    return items.map(AnimalSummaryModelMapper.fromMap).toList(growable: false);
  }

  Future<AnimalSummaryModel> create(AnimalSummaryModel animal) async {
    final response = await _dio.post<Object?>(
      '/api/animals',
      data: _toRequest(animal),
    );

    return AnimalSummaryModelMapper.fromMap(_asMap(response.data));
  }

  Future<AnimalSummaryModel> update(AnimalSummaryModel animal) async {
    final response = await _dio.put<Object?>(
      '/api/animals/${animal.id}',
      data: _toRequest(animal),
    );

    return AnimalSummaryModelMapper.fromMap(_asMap(response.data));
  }

  Future<AnimalSummaryModel> updateStatus({
    required int id,
    required AnimalStatus status,
  }) async {
    final response = await _dio.patch<Object?>(
      '/api/animals/$id/status',
      data: {'status': status.apiValue},
    );

    return AnimalSummaryModelMapper.fromMap(_asMap(response.data));
  }

  Future<void> delete(int id) async {
    await _dio.delete<Object?>('/api/animals/$id');
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

  Map<String, dynamic> _toRequest(AnimalSummaryModel animal) {
    return {
      'idExterno': animal.idExterno,
      'idPropriedade': animal.idPropriedade == 0 ? null : animal.idPropriedade,
      'idExternoPropriedade': animal.idExternoPropriedade.isEmpty
          ? null
          : animal.idExternoPropriedade,
      'codigo': animal.codigo,
      'categoria': animal.categoria,
      'sexo': animal.sexo,
      'dataNascimento': _toDate(animal.dataNascimento),
      'numeroLactacao': animal.numeroLactacao,
      'dataUltimoParto': _toDate(animal.dataUltimoParto),
      'historicoReprodutivo': animal.historicoReprodutivo,
      'status': animal.status.apiValue,
      'dataAtualizacaoCliente': DateTime.now().toUtc().toIso8601String(),
    };
  }

  String? _toDate(DateTime? date) {
    if (date == null) return null;
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
