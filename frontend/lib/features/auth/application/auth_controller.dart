import 'package:flutter/foundation.dart';
import 'package:tianrenlu/features/auth/data/auth_api_client.dart';
import 'package:tianrenlu/features/auth/data/auth_session_store.dart';
import 'package:tianrenlu/features/auth/domain/auth_models.dart';

class AuthController extends ChangeNotifier {
  AuthController({required AuthApiClient api, required AuthSessionStore store})
      : _api = api,
        _store = store;

  final AuthApiClient _api;
  final AuthSessionStore _store;
  String? _token;
  String? _refreshToken;
  AuthUser? _user;

  String? get token => _token;
  AuthUser? get user => _user;
  bool get isAuthenticated => _token != null && _user != null;

  Future<void> restore() async {
    final String? savedToken = await _store.readToken();
    final String? savedRefreshToken = await _store.readRefreshToken();
    if (savedToken == null || savedRefreshToken == null) return;
    try {
      _user = await _api.currentUser(savedToken);
      _token = savedToken;
      _refreshToken = savedRefreshToken;
    } on AuthApiException {
      try {
        await _accept(await _api.refresh(savedRefreshToken));
      } on AuthApiException {
        await _store.clear();
      }
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _accept(await _api.login(email, password));
  }

  Future<void> register(String email, String password) async {
    await _accept(await _api.register(email, password));
  }

  Future<void> requestPasswordReset(String email) =>
      _api.requestPasswordReset(email);

  Future<void> requestEmailVerification() async {
    final String? email = _user?.email;
    if (email != null) await _api.requestEmailVerification(email);
  }

  Future<void> logout() async {
    final String? refreshToken = _refreshToken;
    if (refreshToken != null) {
      try {
        await _api.logout(refreshToken);
      } on AuthApiException {
        // Local logout must still succeed if the server is unavailable.
      }
    }
    await _store.clear();
    _token = null;
    _refreshToken = null;
    _user = null;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final String? currentToken = _token;
    if (currentToken == null) return;
    await _api.deleteAccount(currentToken);
    await logout();
  }

  Future<void> _accept(AuthSession session) async {
    await _store.saveTokens(session.accessToken, session.refreshToken);
    _token = session.accessToken;
    _refreshToken = session.refreshToken;
    _user = session.user;
    notifyListeners();
  }
}
