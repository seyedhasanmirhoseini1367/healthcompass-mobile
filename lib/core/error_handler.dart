import 'package:dio/dio.dart';

/// Maps any caught error (typically a [DioException] from an ApiService
/// call) to a short, user-facing message.
String friendlyError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'The request timed out. Please check your connection and try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network and try again.';
      case DioExceptionType.badCertificate:
        return 'A secure connection could not be established.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        final data = error.response?.data;
        if (code == 401) return 'Your session has expired. Please sign in again.';
        if (code == 404) return 'The requested item could not be found.';
        if (code != null && code >= 500) return 'Something went wrong on our end. Please try again shortly.';
        final serverMsg = _extractServerMessage(data);
        return serverMsg ?? 'Something went wrong${code != null ? " ($code)" : ""}. Please try again.';
      case DioExceptionType.unknown:
        return 'Something went wrong. Please check your connection and try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}

/// True for network-level failures (timeout, no connection) as opposed to
/// a server-returned error response — useful when a screen wants to keep
/// its own specific message for bad-response cases (e.g. "Invalid email
/// or password") but still surface connectivity issues distinctly.
bool isConnectivityIssue(Object error) =>
    error is DioException &&
    error.type != DioExceptionType.badResponse &&
    error.type != DioExceptionType.cancel;

/// Extracts a readable message from a DRF error body — either the
/// `{"error": "..."}` / `{"detail": "..."}` shape used by hand-written
/// views, or a raw serializer-validation dict like
/// `{"title": ["This field is required."], "location": ["Too long."]}`.
String? _extractServerMessage(Object? data) {
  if (data is! Map) return null;
  final raw = data['error'] ?? data['detail'];
  if (raw != null) return raw.toString();

  final parts = <String>[];
  for (final entry in data.entries) {
    final value = entry.value;
    final messages = value is List ? value.map((v) => v.toString()).join(' ') : value.toString();
    if (messages.isNotEmpty) parts.add('${entry.key}: $messages');
  }
  return parts.isEmpty ? null : parts.join('\n');
}
