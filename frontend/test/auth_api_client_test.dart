import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tianrenlu/features/auth/data/auth_api_client.dart';
import 'package:tianrenlu/features/auth/data/authenticated_http_client.dart';

void main() {
  test('registers and parses the authenticated user', () async {
    final MockClient transport = MockClient((http.Request request) async {
      expect(request.url.path, '/api/v1/auth/register');
      final Map<String, dynamic> payload =
          jsonDecode(request.body) as Map<String, dynamic>;
      expect(payload['email'], 'user@example.com');
      return http.Response(
        jsonEncode(<String, dynamic>{
          'access_token': 'token-value',
          'refresh_token': 'refresh-token-value-that-is-long-enough',
          'refresh_expires_in': 2592000,
          'token_type': 'bearer',
          'expires_in': 3600,
          'user': <String, String>{
            'id': '2e0c5c4d-05f1-4a38-8f72-02bd73655e08',
            'email': 'user@example.com',
          },
        }),
        201,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
    final AuthApiClient client = AuthApiClient(
      client: transport,
      baseUrl: 'https://example.test',
    );

    final session = await client.register(
      ' user@example.com ',
      'correct-horse-battery',
    );

    expect(session.accessToken, 'token-value');
    expect(session.refreshToken, 'refresh-token-value-that-is-long-enough');
    expect(session.user.email, 'user@example.com');
  });

  test('adds bearer token when reading current user', () async {
    final MockClient transport = MockClient((http.Request request) async {
      expect(request.url.path, '/api/v1/users/me');
      expect(request.headers['authorization'], 'Bearer secret-token');
      return http.Response(
        jsonEncode(<String, String>{
          'id': '2e0c5c4d-05f1-4a38-8f72-02bd73655e08',
          'email': 'user@example.com',
        }),
        200,
      );
    });
    final AuthApiClient client = AuthApiClient(
      client: transport,
      baseUrl: 'https://example.test',
    );

    final user = await client.currentUser('secret-token');

    expect(user.email, 'user@example.com');
  });

  test('surfaces backend authentication errors', () async {
    final AuthApiClient client = AuthApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode(<String, String>{'detail': '邮箱或密码错误'}),
          401,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        ),
      ),
      baseUrl: 'https://example.test',
    );

    expect(
      () => client.login('user@example.com', 'incorrect-password'),
      throwsA(
        isA<AuthApiException>().having(
          (AuthApiException error) => error.message,
          'message',
          '邮箱或密码错误',
        ),
      ),
    );
  });

  test('refreshes once after 401 and retries with the rotated token', () async {
    int calls = 0;
    int refreshes = 0;
    final MockClient transport = MockClient((http.Request request) async {
      calls++;
      if (calls == 1) {
        expect(request.headers['authorization'], 'Bearer expired-token');
        return http.Response('unauthorized', 401);
      }
      expect(request.headers['authorization'], 'Bearer rotated-token');
      return http.Response('ok', 200);
    });
    final AuthenticatedHttpClient client = AuthenticatedHttpClient(
      inner: transport,
      tokenProvider: () async => 'expired-token',
      tokenRefresher: () async {
        refreshes++;
        return 'rotated-token';
      },
    );

    final http.Response response =
        await client.get(Uri.parse('https://example.test/protected'));

    expect(response.statusCode, 200);
    expect(response.body, 'ok');
    expect(calls, 2);
    expect(refreshes, 1);
  });

  test('confirms email verification and password reset action tokens',
      () async {
    final List<Map<String, dynamic>> payloads = <Map<String, dynamic>>[];
    final AuthApiClient client = AuthApiClient(
      client: MockClient((http.Request request) async {
        payloads.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response('{}', 200);
      }),
      baseUrl: 'https://example.test',
    );

    await client.confirmEmailVerification('verification-token-value-123456');
    await client.resetPassword(
      'password-reset-token-value-123456',
      'new-secure-password',
    );

    expect(payloads.first['token'], 'verification-token-value-123456');
    expect(payloads.last['new_password'], 'new-secure-password');
  });
}
