import 'package:dio/dio.dart';

String describeError(Object error) {
  if (error is DioException) {
    final responseMessage = _extractMessage(error.response?.data);
    if (responseMessage != null && responseMessage.isNotEmpty) {
      return responseMessage;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tempo de conexao com o backend esgotado.';
      case DioExceptionType.connectionError:
        return 'Nao foi possivel conectar ao backend em ${error.requestOptions.baseUrl}.';
      case DioExceptionType.badCertificate:
        return 'O certificado HTTPS do backend foi rejeitado.';
      case DioExceptionType.cancel:
        return 'A requisicao foi cancelada.';
      case DioExceptionType.badResponse:
        return 'O backend respondeu com erro ${error.response?.statusCode ?? ''}.';
      case DioExceptionType.unknown:
        return error.message ??
            'Falha inesperada na comunicacao com o backend.';
    }
  }

  return error.toString();
}

String? _extractMessage(Object? data) {
  if (data is Map<String, dynamic>) {
    final message = data['message'];
    if (message is String) {
      return message;
    }
  }

  return null;
}
