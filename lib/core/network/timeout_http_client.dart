import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthRetryableFetchException;

/// HTTP client that fails requests which receive no response in time, so an
/// unreachable server shows an error instead of an endless loading indicator.
final class TimeoutHttpClient extends http.BaseClient {
  TimeoutHttpClient({
    http.Client? inner,
    this.timeout = const Duration(seconds: 15),
    this.uploadTimeout = const Duration(seconds: 90),
  }) : _inner = inner ?? http.Client();

  final http.Client _inner;
  final Duration timeout;

  /// Longer limit for Storage requests, which may upload photos.
  final Duration uploadTimeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final limit = request.url.path.contains('/storage/v1/')
        ? uploadTimeout
        : timeout;
    return _inner
        .send(request)
        .timeout(
          limit,
          onTimeout: () => throw TimeoutException(
            'Request to ${request.url.host} timed out',
            limit,
          ),
        );
  }

  @override
  void close() => _inner.close();
}

/// Whether [error] means the server could not be reached at all.
bool isNetworkError(Object error) {
  return error is SocketException ||
      error is TimeoutException ||
      error is HandshakeException ||
      error is http.ClientException ||
      error is AuthRetryableFetchException;
}
