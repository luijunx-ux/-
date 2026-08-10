import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tianrenlu/features/auth/data/auth_api_client.dart';

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
}
