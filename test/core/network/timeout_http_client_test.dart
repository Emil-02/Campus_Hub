import 'dart:async';
import 'dart:io';

import 'package:campusmate/core/network/timeout_http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthRetryableFetchException, PostgrestException;

void main() {
  const shortTimeout = Duration(milliseconds: 50);
  const longTimeout = Duration(milliseconds: 400);

  http.Client delayedClient(Duration delay) {
    return MockClient((request) async {
      await Future<void>.delayed(delay);
      return http.Response('ok', 200);
    });
  }

  test('returns the response when the server answers in time', () async {
    final client = TimeoutHttpClient(
      inner: delayedClient(Duration.zero),
      timeout: shortTimeout,
    );

    final response = await client.get(
      Uri.parse('https://example.supabase.co/rest/v1/tasks'),
    );

    expect(response.statusCode, 200);
    expect(response.body, 'ok');
  });

  test('throws TimeoutException when the server does not answer', () async {
    final client = TimeoutHttpClient(
      inner: delayedClient(const Duration(milliseconds: 200)),
      timeout: shortTimeout,
    );

    await expectLater(
      client.get(Uri.parse('https://example.supabase.co/rest/v1/tasks')),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('gives storage uploads the longer upload timeout', () async {
    final client = TimeoutHttpClient(
      inner: delayedClient(const Duration(milliseconds: 200)),
      timeout: shortTimeout,
      uploadTimeout: longTimeout,
    );

    final response = await client.post(
      Uri.parse('https://example.supabase.co/storage/v1/object/avatars/a.jpg'),
    );

    expect(response.statusCode, 200);
  });

  test('isNetworkError recognises unreachable-server errors only', () {
    expect(isNetworkError(const SocketException('Failed host lookup')), true);
    expect(isNetworkError(TimeoutException('slow')), true);
    expect(isNetworkError(http.ClientException('Connection refused')), true);
    expect(
      isNetworkError(AuthRetryableFetchException(message: 'offline')),
      true,
    );
    expect(isNetworkError(const PostgrestException(message: 'denied')), false);
    expect(isNetworkError(StateError('no session')), false);
  });
}
