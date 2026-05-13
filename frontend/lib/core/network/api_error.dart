import 'package:dio/dio.dart';

String describeError(Object error, {String? fallbackMessage}) {
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
        return _describeStatusCode(error.response?.statusCode);
      case DioExceptionType.unknown:
        return fallbackMessage ??
            error.message ??
            'Falha inesperada na comunicacao com o backend.';
    }
  }

  if (error is StateError) {
    return error.message;
  }

  if (error is String) {
    return error;
  }

  return fallbackMessage ?? 'Nao foi possivel concluir a acao.';
}

String? _extractMessage(Object? data) {
  if (data is Map<String, dynamic>) {
    final message = data['message'] ?? data['error'] ?? data['detail'];
    if (message is String) {
      return message;
    }

    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is String) return first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
  }

  return null;
}

String _describeStatusCode(int? statusCode) {
  if (statusCode == null) {
    return 'Nao foi possivel concluir a acao.';
  }

  return switch (statusCode) {
    400 => 'Confira os dados informados e tente novamente.',
    401 => 'Sua sessao expirou. Entre novamente para continuar.',
    403 => 'Voce nao tem permissao para realizar esta acao.',
    404 => 'Registro nao encontrado. Atualize a tela e tente novamente.',
    409 => 'Este registro conflitou com uma alteracao mais recente.',
    422 => 'Alguns campos precisam ser corrigidos antes de continuar.',
    >= 500 => 'O backend encontrou um problema. Tente novamente em instantes.',
    _ => 'Nao foi possivel concluir a acao.',
  };
}
