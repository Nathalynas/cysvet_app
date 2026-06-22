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
    return items.map(_toVisitModel).toList(growable: false);
  }

  Future<VisitSummaryModel> create(VisitSummaryModel visit) async {
    final response = await _dio.post<Object?>(
      '/api/visits',
      data: _toRequest(visit),
    );

    return _toVisitModel(_asMap(response.data));
  }

  Future<VisitSummaryModel> update(VisitSummaryModel visit) async {
    final response = await _dio.put<Object?>(
      '/api/visits/${visit.id}',
      data: _toRequest(visit),
    );

    return _toVisitModel(_asMap(response.data));
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

  VisitSummaryModel _toVisitModel(Map<String, dynamic> map) {
    return VisitSummaryModelMapper.fromMap(_normalizeVisitUser(map));
  }

  Map<String, dynamic> _normalizeVisitUser(Map<String, dynamic> map) {
    // Frontend-only nesta etapa: VisitaResponse ainda nao expoe o usuario.
    // Quando o backend retornar o usuario criador, esses aliases ja alimentam
    // o card de propriedade e o dialog de detalhes.
    final rawUser = map['usuario'];
    final user = rawUser is Map
        ? rawUser.map((key, value) => MapEntry(key.toString(), value))
        : null;
    final idUsuario = _asNullableInt(
      map['idUsuario'] ?? map['usuarioId'] ?? map['id_usuario'] ?? user?['id'],
    );
    final nomeUsuario = _asNullableString(
      map['nomeUsuario'] ??
          map['usuarioNome'] ??
          map['nomeVeterinario'] ??
          map['veterinarioResponsavel'] ??
          user?['name'] ??
          user?['nome'],
    );

    return {...map, 'idUsuario': idUsuario, 'nomeUsuario': nomeUsuario};
  }

  int? _asNullableInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String? _asNullableString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
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
      'animais': visit.animais
          .map((item) => _toAnimalItemRequest(item))
          .toList(growable: false),
      'dataAtualizacaoCliente': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _toAnimalItemRequest(VisitAnimalEntryModel item) {
    // TODO Backend: os campos de base/calculo da planilha que ainda nao
    // existem em VisitaAnimalItemDto ficam somente no front-end por enquanto.
    // Eles devem ser incluidos aqui quando o payload/API de visitas persistir:
    // dataNascimento, dataPrimeiroParto, dataUltimoParto, dataPartoAnterior,
    // numeroPartos, historico dinamico de IAs, dataPrimeiraIa..dataQuintaIa,
    // dataSecagemEfetiva, entradaPreParto, controleLeiteiro e os indicadores
    // calculados derivados.
    // TODO Backend: persistir/sincronizar o historico de IA sem limite fixo.
    return {
      'animalId': item.animalId == 0 ? null : item.animalId,
      'animalIdExterno': item.animalIdExterno.isEmpty
          ? null
          : item.animalIdExterno,
      'animalCodigo': item.animalCodigo,
      'animalCategoria': item.animalCategoria,
      'idadeMeses': item.idadeMeses?.round(),
      'situacaoProdutiva': item.situacaoProdutiva,
      'situacaoReprodutiva': item.situacaoReprodutiva,
      'decisao': item.decisao,
      'dataUltimaIa': _toDate(item.dataUltimaIa),
      'numeroIaRecebida': item.numeroIaRecebida,
      'diasPrenhez': item.diasPrenhez,
      'diagnostico': item.diagnostico,
      'del': item.del,
      'diasParaSecar': item.diasParaSecar,
      'previsaoSecagem': _toDate(item.previsaoSecagem),
      'dataPreParto': _toDate(item.dataPreParto),
      'previsaoParto': _toDate(item.previsaoParto),
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
