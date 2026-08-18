import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tianrenlu/core/life_theme.dart';
import 'package:tianrenlu/features/profile/data/profile_api_client.dart';
import 'package:tianrenlu/features/profile/domain/profile_models.dart';
import 'package:tianrenlu/features/profile/presentation/today_dashboard_page.dart';

class _ReviewProfileApiClient extends ProfileApiClient {
  _ReviewProfileApiClient() : super(baseUrl: 'http://visual-review.invalid');

  @override
  Future<List<LifeProfile>> listProfiles() async => <LifeProfile>[
        LifeProfile(
          id: 'forest-review-profile',
          name: 'Qinghe',
          isDefault: true,
          birthInput: BirthInput(
            occurredAt: DateTime(1992, 5, 18, 9, 30),
            placeName: 'Shanghai',
            latitude: 31.2304,
            longitude: 121.4737,
            timezone: 'Asia/Shanghai',
          ),
          zodiac: const ZodiacInfo(
            sign: '金牛座',
            element: '土',
            modality: '固定',
          ),
          wuyunLiuqi: const WuyunLiuqiInfo(
            heavenlyStem: '丙',
            earthlyBranch: '午',
            middleMovement: '木运',
            movementStrength: '太过',
            governingQi: '少阳相火',
            respondingQi: '厥阴风木',
            algorithmVersion: 'demo-v1',
          ),
          disclaimer: '文化与生活方式参考，不构成医疗建议。',
        ),
      ];

  @override
  Future<int> getViewingStreak(DateTime throughDate) async => 6;
}

void main() {
  Future<void> renderHome(
    WidgetTester tester, {
    required LifeThemeMode mode,
    required String goldenPath,
  }) async {
    final Uint8List fontBytes =
        File(r'C:\Windows\Fonts\simhei.ttf').readAsBytesSync();
    final FontLoader fontLoader = FontLoader('ReviewChinese')
      ..addFont(Future<ByteData>.value(ByteData.sublistView(fontBytes)));
    await fontLoader.load();

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ThemeData reviewTheme = buildLifeTheme(mode);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: reviewTheme.copyWith(
          textTheme: reviewTheme.textTheme.apply(fontFamily: 'ReviewChinese'),
          primaryTextTheme:
              reviewTheme.primaryTextTheme.apply(fontFamily: 'ReviewChinese'),
        ),
        home: RepaintBoundary(
          key: const Key('life-home-review'),
          child: TodayDashboardPage(
            apiClient: _ReviewProfileApiClient(),
            accountPageBuilder: () => const SizedBox.shrink(),
            themeMode: mode,
            onThemeChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('life-home-review')),
      matchesGoldenFile(goldenPath),
    );
  }

  testWidgets('Forest mobile home visual review', (WidgetTester tester) async {
    await renderHome(
      tester,
      mode: LifeThemeMode.forest,
      goldenPath: '../../docs/ui/review/forest-home-mobile-background-v3.png',
    );
  });

  testWidgets('Obsidian mobile home visual review',
      (WidgetTester tester) async {
    await renderHome(
      tester,
      mode: LifeThemeMode.obsidian,
      goldenPath: '../../docs/ui/review/obsidian-home-mobile-v3.png',
    );
  });
}
