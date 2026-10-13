import 'package:cysvet_app/pages/auth/change_password_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _error(int status, Object? data) {
  final options = RequestOptions(path: '/api/account/password');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: status,
      data: data,
    ),
  );
}

void main() {
  test('400 Troca de senha nao solicitada conta como troca ja feita', () {
    expect(
      isPasswordChangeAlreadyDone(
        _error(400, {'message': 'Troca de senha nao solicitada'}),
      ),
      isTrue,
    );
  });

  test('outros erros nao contam como troca ja feita', () {
    expect(
      isPasswordChangeAlreadyDone(
        _error(400, {'message': 'Senha muito curta'}),
      ),
      isFalse,
    );
    expect(
      isPasswordChangeAlreadyDone(
        _error(403, {'message': 'Troca de senha nao solicitada'}),
      ),
      isFalse,
    );
    expect(isPasswordChangeAlreadyDone(_error(400, null)), isFalse);
    expect(isPasswordChangeAlreadyDone(Exception('x')), isFalse);
  });
}
