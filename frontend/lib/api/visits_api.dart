import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:cysvet_app/api/api_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cysvet_app/core/network/api_client.dart';
import 'package:cysvet_app/models/visit_summary_model.dart';

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

    final items = apiList(response.data);
    return items.map(_toVisitModel).toList(growable: false);
  }

  Future<VisitSummaryModel> getById(int id) async {
    final response = await _dio.get<Object?>('/api/visits/$id');
    return _toVisitModel(apiMap(response.data));
  }

  Future<VisitSummaryModel> create(VisitSummaryModel visit) async {
    final response = await _dio.post<Object?>(
      '/api/visits',
      data: _toRequest(visit),
    );

    return _toVisitModel(apiMap(response.data));
  }

  Future<VisitSummaryModel> update(VisitSummaryModel visit) async {
    final response = await _dio.put<Object?>(
      '/api/visits/${visit.id}',
      data: _toRequest(visit),
    );

    return _toVisitModel(apiMap(response.data));
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

  VisitSummaryModel _toVisitModel(Map<String, dynamic> map) {
    return VisitSummaryModelMapper.fromMap(_normalizeVisitUser(map));
  }

  Map<String, dynamic> _normalizeVisitUser(Map<String, dynamic> map) {
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
      'dataVisita': apiDate(visit.dataVisita),
      'observacoes': visit.observacoes,
      'animais': visit.animais
          .map((item) => _toAnimalItemRequest(item))
          .toList(growable: false),
      'dataAtualizacaoCliente': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _toAnimalItemRequest(VisitAnimalEntryModel item) {
    return {
      'animalId': item.animalId == 0 ? null : item.animalId,
      'animalIdExterno': item.animalIdExterno.isEmpty
          ? null
          : item.animalIdExterno,
      'animalCodigo': item.animalCodigo,
      'animalCategoria': item.animalCategoria,
      'idadeMeses': item.idadeMeses?.round(),
      'dataNascimento': apiDate(item.dataNascimento),
      'situacaoProdutiva': item.situacaoProdutiva,
      'situacaoReprodutiva': item.situacaoReprodutiva,
      'decisao': item.decisao,
      'dataPrimeiroParto': apiDate(item.dataPrimeiroParto),
      'dataUltimoParto': apiDate(item.dataUltimoParto),
      'dataPartoAnterior': apiDate(item.dataPartoAnterior),
      'numeroPartos': item.numeroPartos,
      'dataPrimeiraIa': apiDate(item.dataPrimeiraIa),
      'dataSegundaIa': apiDate(item.dataSegundaIa),
      'dataTerceiraIa': apiDate(item.dataTerceiraIa),
      'dataQuartaIa': apiDate(item.dataQuartaIa),
      'dataQuintaIa': apiDate(item.dataQuintaIa),
      'dataUltimaIa': apiDate(item.dataUltimaIa),
      'numeroIaRecebida': item.numeroIaRecebida,
      'dataSecagemEfetiva': apiDate(item.dataSecagemEfetiva),
      'entradaPreParto': apiDate(item.entradaPreParto),
      'controleLeiteiro': item.controleLeiteiro,
      'diasPrenhez': item.diasPrenhez,
      'diagnostico': item.diagnostico,
      'del': item.del,
      'idadePrimeiroPartoMeses': item.idadePrimeiroPartoMeses,
      'idadePrimeiraIa': item.idadePrimeiraIa,
      'mesParto': item.mesParto,
      'anoUltimoParto': item.anoUltimoParto,
      'iepAtual': item.iepAtual,
      'classificacaoPartos': item.classificacaoPartos,
      'vacaApta': item.vacaApta,
      'intervalo1e2Ia': item.intervalo1e2Ia,
      'intervalo2e3Ia': item.intervalo2e3Ia,
      'intervalo3e4Ia': item.intervalo3e4Ia,
      'intervalo4e5Ia': item.intervalo4e5Ia,
      'mediaIntervaloIa': item.mediaIntervaloIa,
      'previsaoRetornoCio': apiDate(item.previsaoRetornoCio),
      'delPrimeiraIa': item.delPrimeiraIa,
      'periodoServico': item.periodoServico,
      'diasParaSecar': item.diasParaSecar,
      'previsaoSecagem': apiDate(item.previsaoSecagem),
      'mesSecagem': item.mesSecagem,
      'diferencaSecagem': item.diferencaSecagem,
      'periodoLactacao': item.periodoLactacao,
      'dataPreParto': apiDate(item.dataPreParto),
      'mesPreParto': item.mesPreParto,
      'duracaoPreParto': item.duracaoPreParto,
      'previsaoParto': apiDate(item.previsaoParto),
      'mesPrevistoParto': item.mesPrevistoParto,
      'iepProjetado': item.iepProjetado,
      'controleLeiteiroComDesconto': item.controleLeiteiroComDesconto,
    };
  }
}
