import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/visit_summary_model.dart';

final visitsRepositoryProvider = Provider<VisitsRepository>((ref) {
  return VisitsRepository(ref.watch(apiClientProvider));
});

class VisitsRepository {
  VisitsRepository(this._dio);

  final Dio _dio;

  Future<List<VisitSummaryModel>> list({int? propertyId}) async {
    final response = await _dio.get<Object?>(
      '/api/visits',
      queryParameters: {
        ...?propertyId != null ? {'idPropriedade': propertyId} : null,
      },
    );

    final items = _asList(response.data);
    return items.map(VisitSummaryModelMapper.fromMap).toList(growable: false);
  }

  Future<VisitSummaryModel> create(VisitSummaryModel visit) async {
    final response = await _dio.post<Object?>(
      '/api/visits',
      data: _toRequest(visit),
    );

    return VisitSummaryModelMapper.fromMap(_asMap(response.data));
  }

  Future<VisitSummaryModel> update(VisitSummaryModel visit) async {
    final response = await _dio.put<Object?>(
      '/api/visits/${visit.id}',
      data: _toRequest(visit),
    );

    return VisitSummaryModelMapper.fromMap(_asMap(response.data));
  }

  Future<Uint8List> downloadReportPdf(int visitId) async {
    final response = await _dio.get<List<int>>(
      '/api/reports/visit/$visitId/pdf',
      options: Options(
        responseType: ResponseType.bytes,
        headers: const {'Accept': 'application/pdf'},
      ),
    );

    return Uint8List.fromList(response.data ?? const []);
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

  Map<String, dynamic> _toRequest(VisitSummaryModel visit) {
    return {
      'idExterno': visit.idExterno,
      'idPropriedade': visit.idPropriedade == 0 ? null : visit.idPropriedade,
      'idExternoPropriedade': visit.idExternoPropriedade.isEmpty
          ? null
          : visit.idExternoPropriedade,
      'dataVisita': _toDate(visit.dataVisita),
      'observacoes': visit.observacoes,
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
