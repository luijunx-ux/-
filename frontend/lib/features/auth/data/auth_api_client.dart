import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tianrenlu/core/api_config.dart';
import 'package:tianrenlu/features/auth/domain/auth_models.dart';

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthApiClient {
  AuthApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<AuthSession> register(String email, String password) =>
      _authenticate('/api/v1/auth/register', email, password);

  Future<AuthSession> login(String email, String password) =>
      _authenticate('/api/v1/auth/login', email, password);

  Future<AuthSession> refresh(String refreshToken) =>
      _tokenRequest('/api/v1/auth/refresh', refreshToken);

  Future<void> logout(String refreshToken) async {
    final http.Response response = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl/api/v1/auth/logout'),
        headers: const <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{'refresh_token': refreshToken}),
      ),
    );
    _ensureSuccess(response, _decode(response));
  }

  Future<void> requestPasswordReset(String email) =>
      _emailAction('/api/v1/auth/password-reset/request', email);

  Future<void> requestEmailVerification(String email) =>
      _emailAction('/api/v1/auth/email-verification/request', email);

  Future<void> confirmEmailVerification(String token) => _confirmAction(
        '/api/v1/auth/email-verification/confirm',
        <String, String>{'token': token},
      );

  Future<void> resetPassword(String token, String newPassword) =>
      _confirmAction(
        '/api/v1/auth/password-reset/confirm',
        <String, String>{'token': token, 'new_password': newPassword},
      );

  Future<void> _confirmAction(String path, Map<String, String> payload) async {
    final http.Response response = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl$path'),
        headers: const <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ),
    );
    _ensureSuccess(response, _decode(response));
  }

  Future<void> _emailAction(String path, String email) async {
    final http.Response response = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl$path'),
        headers: const <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{'email': email.trim()}),
      ),
    );
    _ensureSuccess(response, _decode(response));
  }

  Future<AuthUser> currentUser(String token) async {
    final http.Response response = await _send(
      () => _client.get(
        Uri.parse('$_baseUrl/api/v1/users/me'),
        headers: _authorizedHeaders(token),
      ),
    );
    final Object? body = _decode(response);
    _ensureSuccess(response, body);
    return AuthUser.fromJson(body as Map<String, dynamic>);
  }

  Future<void> deleteAccount(String token) async {
    final http.Response response = await _send(
      () => _client.delete(
        Uri.parse('$_baseUrl/api/v1/users/me'),
        headers: _authorizedHeaders(token),
      ),
    );
    final Object? body = _decode(response);
    _ensureSuccess(response, body);
  }

  Future<AuthSession> _authenticate(
    String path,
    String email,
    String password,
  ) async {
    final http.Response response = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl$path'),
        headers: const <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{
          'email': email.trim(),
          'password': password,
        }),
      ),
    );
    final Object? body = _decode(response);
    _ensureSuccess(response, body);
    return AuthSession.fromJson(body as Map<String, dynamic>);
  }

  Future<AuthSession> _tokenRequest(String path, String refreshToken) async {
    final http.Response response = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl$path'),
        headers: const <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{'refresh_token': refreshToken}),
      ),
    );
    final Object? body = _decode(response);
    _ensureSuccess(response, body);
    return AuthSession.fromJson(body as Map<String, dynamic>);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 15));
    } on Exception {
      throw const AuthApiException('无法连接账户服务，请检查网络后重试。');
    }
  }

  Object? _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }

  void _ensureSuccess(http.Response response, Object? body) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    if (body is Map<String, dynamic> && body['detail'] is String) {
      throw AuthApiException(body['detail'] as String);
    }
    throw const AuthApiException('账户请求失败，请稍后重试。');
  }

  Map<String, String> _authorizedHeaders(String token) => <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
}
