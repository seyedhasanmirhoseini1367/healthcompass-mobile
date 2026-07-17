import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcompass_mobile/core/error_handler.dart';

DioException _badResponse(int code, Map<String, dynamic> data) => DioException(
      requestOptions: RequestOptions(path: '/test'),
      response: Response(requestOptions: RequestOptions(path: '/test'), statusCode: code, data: data),
      type: DioExceptionType.badResponse,
    );

void main() {
  group('friendlyError', () {
    // Real body captured from POST /auth/login/ with a wrong password.
    test('401 overrides the body with a session-expired message', () {
      final msg = friendlyError(_badResponse(401, {'error': 'Invalid email or password.'}));
      expect(msg, 'Your session has expired. Please sign in again.');
    });

    // Real body captured from POST /records/<missing-id>/.
    test('404 maps to a not-found message', () {
      final msg = friendlyError(_badResponse(404, {'error': 'Not found.'}));
      expect(msg, 'The requested item could not be found.');
    });

    test('5xx maps to a generic server-error message', () {
      final msg = friendlyError(_badResponse(500, {'error': 'boom'}));
      expect(msg, contains('our end'));
    });

    // Real body captured from POST /auth/register/ with a duplicate email.
    test('DRF field-validation dict is surfaced field-by-field', () {
      final msg = friendlyError(_badResponse(400, {
        'email': ['user with this email address already exists.'],
      }));
      expect(msg, contains('email'));
      expect(msg, contains('already exists'));
    });

    // Real body captured from POST /appointments/ with blank title + bad datetime.
    test('multi-field DRF validation errors are all surfaced', () {
      final msg = friendlyError(_badResponse(400, {
        'title': ['This field may not be blank.'],
        'appointment_datetime': ['Datetime has wrong format.'],
      }));
      expect(msg, contains('title'));
      expect(msg, contains('not be blank'));
      expect(msg, contains('appointment_datetime'));
      expect(msg, contains('wrong format'));
    });

    test('{"error": ...} shape takes precedence over field-dict parsing', () {
      final msg = friendlyError(_badResponse(400, {'error': 'Custom message.'}));
      expect(msg, 'Custom message.');
    });

    test('connection error maps to a network message', () {
      final e = DioException(requestOptions: RequestOptions(path: '/x'), type: DioExceptionType.connectionError);
      expect(friendlyError(e), contains('No internet connection'));
    });

    test('timeout maps to a timeout message', () {
      final e = DioException(requestOptions: RequestOptions(path: '/x'), type: DioExceptionType.receiveTimeout);
      expect(friendlyError(e), contains('timed out'));
    });

    test('non-Dio errors get a generic fallback', () {
      expect(friendlyError(Exception('whatever')), 'Something went wrong. Please try again.');
    });
  });

  group('isConnectivityIssue', () {
    test('true for connection errors', () {
      final e = DioException(requestOptions: RequestOptions(path: '/x'), type: DioExceptionType.connectionError);
      expect(isConnectivityIssue(e), isTrue);
    });

    test('false for a bad (e.g. 401) response', () {
      expect(isConnectivityIssue(_badResponse(401, {'error': 'x'})), isFalse);
    });

    test('false for non-Dio errors', () {
      expect(isConnectivityIssue(Exception('x')), isFalse);
    });
  });
}
