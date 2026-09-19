import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tianrenlu/core/life_theme.dart';
import 'package:tianrenlu/features/auth/application/auth_controller.dart';
import 'package:tianrenlu/features/auth/data/auth_api_client.dart';
import 'package:tianrenlu/features/auth/data/authenticated_http_client.dart';
import 'package:tianrenlu/features/auth/data/auth_session_store.dart';
import 'package:tianrenlu/features/auth/presentation/account_page.dart';
import 'package:tianrenlu/features/auth/presentation/account_action_page.dart';
import 'package:tianrenlu/features/auth/presentation/auth_page.dart';
import 'package:tianrenlu/features/profile/data/profile_api_client.dart';
import 'package:tianrenlu/features/profile/presentation/today_dashboard_page.dart';

void main() {
  runApp(const TianrenluApp());
}

class TianrenluApp extends StatefulWidget {
  const TianrenluApp({super.key});

  @override
  State<TianrenluApp> createState() => _TianrenluAppState();
}

class _TianrenluAppState extends State<TianrenluApp> {
  late final AuthController _authController;
  late final Future<void> _restoreFuture;
  bool _accountActionHandled = false;
  LifeThemeMode _themeMode =
      switch (const String.fromEnvironment('LIFE_THEME')) {
    'obsidian' => LifeThemeMode.obsidian,
    'vitality' => LifeThemeMode.vitality,
    _ => LifeThemeMode.forest,
  };

  @override
  void initState() {
    super.initState();
    _authController = AuthController(
      api: AuthApiClient(),
      store: SecureAuthSessionStore(),
    );
    _restoreFuture = _authController.restore();
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? purpose = Uri.base.queryParameters['purpose'];
    final String? actionToken = Uri.base.queryParameters['token'];
    return MaterialApp(
      title: '天人律',
      debugShowCheckedModeBanner: false,
      theme: buildLifeTheme(_themeMode),
      home: !_accountActionHandled && purpose != null && actionToken != null
          ? AccountActionPage(
              purpose: purpose,
              token: actionToken,
              onDone: () => setState(() => _accountActionHandled = true),
            )
          : FutureBuilder<void>(
              future: _restoreFuture,
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return ListenableBuilder(
                  listenable: _authController,
                  builder: (BuildContext context, Widget? child) {
                    if (!_authController.isAuthenticated) {
                      return AuthPage(controller: _authController);
                    }
                    return TodayDashboardPage(
                      themeMode: _themeMode,
                      onThemeChanged: (LifeThemeMode mode) {
                        setState(() => _themeMode = mode);
                      },
                      apiClient: ProfileApiClient(
                        client: AuthenticatedHttpClient(
                          inner: http.Client(),
                          tokenProvider: () async => _authController.token,
                          tokenRefresher: _authController.refreshAccessToken,
                        ),
                        tokenProvider: () async => _authController.token,
                      ),
                      accountPageBuilder: () => AccountPage(
                        controller: _authController,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
