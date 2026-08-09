import 'package:flutter/material.dart';
import 'package:tianrenlu/features/profile/data/profile_api_client.dart';
import 'package:tianrenlu/features/profile/presentation/profile_form_page.dart';

void main() {
  runApp(const TianrenluApp());
}

class TianrenluApp extends StatelessWidget {
  const TianrenluApp({super.key});

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
      home: ProfileFormPage(apiClient: ProfileApiClient()),
    );
  }
}
