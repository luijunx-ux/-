import 'package:flutter/material.dart';
import 'package:tianrenlu/features/auth/application/auth_controller.dart';
import 'package:tianrenlu/features/auth/data/auth_api_client.dart';
import 'package:tianrenlu/features/auth/data/auth_session_store.dart';
import 'package:tianrenlu/features/auth/presentation/account_page.dart';
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
    return MaterialApp(
      title: '天人律',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF315C4C),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F4EC),
        useMaterial3: true,
      ),
      home: FutureBuilder<void>(
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
                apiClient: ProfileApiClient(
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
