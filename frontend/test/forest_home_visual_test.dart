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

class _EmptyProfileApiClient extends ProfileApiClient {
  _EmptyProfileApiClient() : super(baseUrl: 'http://visual-review.invalid');

  @override
  Future<List<LifeProfile>> listProfiles() async => <LifeProfile>[];

  @override
  Future<int> getViewingStreak(DateTime throughDate) async => 0;
}

class _ErrorProfileApiClient extends ProfileApiClient {
  _ErrorProfileApiClient() : super(baseUrl: 'http://visual-review.invalid');

  @override
  Future<List<LifeProfile>> listProfiles() async {
    throw const ProfileApiException('网络暂不可用，已保留你的本地设置。');
  }
}

void main() {
  Future<void> loadReviewFonts() async {
    Future<void> loadFont(String family, String path) async {
      final Uint8List bytes = File(path).readAsBytesSync();
      await (FontLoader(family)
            ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes))))
          .load();
    }

    final String? configuredFont =
        Platform.environment['TIANRENLV_REVIEW_FONT'];
    final List<String> reviewFontCandidates = <String>[
      if (configuredFont != null) configuredFont,
      if (Platform.isWindows) r'C:\Windows\Fonts\simhei.ttf',
      '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',
      '/System/Library/Fonts/PingFang.ttc',
    ];
    final String reviewFontPath = reviewFontCandidates.firstWhere(
      (String path) => File(path).existsSync(),
      orElse: () => throw StateError(
        'No review CJK font found. Set TIANRENLV_REVIEW_FONT.',
      ),
    );
    await loadFont('ReviewChinese', reviewFontPath);

    final String? flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot == null) {
      throw StateError('FLUTTER_ROOT is required for visual tests.');
    }
    await loadFont(
      'MaterialIcons',
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
  }

  Future<void> renderHome(
    WidgetTester tester, {
    required LifeThemeMode mode,
    String? goldenPath,
    Size size = const Size(390, 844),
    double textScale = 1,
    ProfileApiClient? apiClient,
  }) async {
    await loadReviewFonts();

    tester.view.physicalSize = size;
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
          filledButtonTheme: FilledButtonThemeData(
            style: reviewTheme.filledButtonTheme.style?.copyWith(
              textStyle: WidgetStatePropertyAll<TextStyle?>(
                reviewTheme.textTheme.labelLarge
                    ?.copyWith(fontFamily: 'ReviewChinese'),
              ),
            ),
          ),
        ),
        builder: (BuildContext context, Widget? child) {
          final MediaQueryData data = MediaQuery.of(context);
          return MediaQuery(
            data: data.copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          );
        },
        home: RepaintBoundary(
          key: const Key('life-home-review'),
          child: TodayDashboardPage(
            apiClient: apiClient ?? _ReviewProfileApiClient(),
            accountPageBuilder: () => const SizedBox.shrink(),
            themeMode: mode,
            onThemeChanged: (_) {},
            now: DateTime(2026, 8, 17, 15),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    if (goldenPath != null) {
      await expectLater(
        find.byKey(const Key('life-home-review')),
        matchesGoldenFile(goldenPath),
      );
    }
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

  testWidgets('Vitality mobile home visual review and check-in',
      (WidgetTester tester) async {
    await renderHome(
      tester,
      mode: LifeThemeMode.vitality,
      goldenPath: '../../docs/ui/review/vitality-home-mobile-v4.png',
    );

    expect(find.text('从清晨开始，照顾今日的自己'), findsOneWidget);
    expect(find.text('数据不足'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    final Finder meditationButton = find.text('正念冥想');
    await tester.ensureVisible(meditationButton);
    await tester.pumpAndSettle();
    expect(meditationButton, findsOneWidget);
    await tester.tap(meditationButton);
    await tester.pumpAndSettle();
    expect(find.textContaining('未来将与“冥想室”应用打通'), findsOneWidget);
    await tester.tap(find.text('我知道了'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1300));
    await tester.pumpAndSettle();
    final Finder saveButton = find.widgetWithText(FilledButton, '记录此刻状态');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(find.text('今日已记录 1 次'), findsOneWidget);
    expect(find.text('更新今日记录'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Vitality meditation entry visual review',
      (WidgetTester tester) async {
    await renderHome(tester, mode: LifeThemeMode.vitality);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('正念冥想'));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 260));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('life-home-review')),
      matchesGoldenFile(
        '../../docs/ui/review/vitality-home-meditation-entry-v1.png',
      ),
    );
    expect(find.text('正念冥想'), findsOneWidget);
    expect(find.text('即将接入'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Vitality daily advice expands one category',
      (WidgetTester tester) async {
    await renderHome(
      tester,
      mode: LifeThemeMode.vitality,
      size: const Size(390, 1100),
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1050));
    await tester.pumpAndSettle();
    final Finder sleepTile = find.text('睡眠');
    await tester.ensureVisible(sleepTile);
    await tester.tap(sleepTile);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('vitality-advice-detail')));
    await tester.pumpAndSettle();

    expect(find.text('睡眠 · 今日补充建议'), findsOneWidget);
    expect(find.text('唯一主任务已在上方综合分析中'), findsOneWidget);
    expect(find.text('完成'), findsOneWidget);
    expect(find.text('跳过'), findsOneWidget);
    expect(find.text('调整'), findsOneWidget);
    expect(find.text('换一个'), findsOneWidget);

    await expectLater(
      find.byKey(const Key('life-home-review')),
      matchesGoldenFile(
        '../../docs/ui/review/vitality-daily-advice-expanded-v1.png',
      ),
    );
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    expect(find.textContaining('仅保存在当前页面'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Vitality focus check-in records subjective state safely',
      (WidgetTester tester) async {
    await renderHome(
      tester,
      mode: LifeThemeMode.vitality,
      size: const Size(390, 1100),
    );
    final Finder scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('现在感觉怎么样？'),
      650,
      scrollable: scrollable,
    );
    await tester.ensureVisible(find.text('明显不适'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('明显不适'));
    await tester.pumpAndSettle();
    expect(find.textContaining('建议联系合格的专业人士'), findsOneWidget);

    final Finder noteField = find.byType(TextField);
    await tester.ensureVisible(noteField);
    await tester.enterText(noteField, '午后有些疲惫，休息后感觉好一些。');
    await tester.ensureVisible(find.text('记录此刻状态'));
    await tester.tap(find.text('记录此刻状态'));
    await tester.pumpAndSettle();

    expect(find.text('今日已记录 1 次'), findsOneWidget);
    expect(find.text('更新今日记录'), findsOneWidget);
    expect(find.text('删除这条主观记录'), findsOneWidget);
    expect(find.text('午后有些疲惫，休息后感觉好一些。'), findsNWidgets(2));
    expect(find.textContaining('不会修改已经生成的生命参考分'), findsOneWidget);

    await tester.ensureVisible(find.text('现在感觉怎么样？'));
    await tester.drag(scrollable, const Offset(0, 150));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const Key('life-home-review')),
      matchesGoldenFile(
        '../../docs/ui/review/vitality-focus-checkin-expanded-v1.png',
      ),
    );
    await tester.ensureVisible(find.text('删除这条主观记录'));
    await tester.tap(find.text('删除这条主观记录'));
    await tester.pumpAndSettle();
    expect(find.text('今日尚未记录'), findsOneWidget);
    expect(find.text('删除这条主观记录'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Vitality bottom navigation moves to real home sections',
      (WidgetTester tester) async {
    await renderHome(tester, mode: LifeThemeMode.vitality);
    await tester.ensureVisible(find.byKey(const Key('vitality-nav-records')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('vitality-nav-rhythm')));
    await tester.pumpAndSettle();
    expect(find.text('天地节律'), findsOneWidget);
    expect(tester.getTopLeft(find.text('天地节律')).dy, lessThan(844));

    await tester.ensureVisible(find.byKey(const Key('vitality-nav-records')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('vitality-nav-records')));
    await tester.pumpAndSettle();
    expect(find.text('我的重点状态'), findsOneWidget);
    expect(tester.getTopLeft(find.text('我的重点状态')).dy, lessThan(844));

    await tester.ensureVisible(find.byKey(const Key('vitality-nav-today')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('vitality-nav-today')));
    await tester.pumpAndSettle();
    expect(find.text('从清晨开始，照顾今日的自己'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('从清晨开始，照顾今日的自己')).dy,
      lessThan(844),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow Forest home remains usable with enlarged text',
      (WidgetTester tester) async {
    await renderHome(
      tester,
      mode: LifeThemeMode.forest,
      size: const Size(320, 700),
      textScale: 1.3,
      goldenPath: '../../docs/ui/review/forest-home-narrow-large-text-v3.png',
    );

    expect(find.text('五运六气'), findsOneWidget);
    expect(find.text('星辰节律'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('今日温和建议'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('今日温和建议'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty profile state preserves Forest visual hierarchy',
      (WidgetTester tester) async {
    await renderHome(
      tester,
      mode: LifeThemeMode.forest,
      apiClient: _EmptyProfileApiClient(),
    );

    expect(find.text('从一份生命档案开始'), findsOneWidget);
    expect(find.text('建立生命档案'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline state is explicit and recoverable in Obsidian',
      (WidgetTester tester) async {
    await renderHome(
      tester,
      mode: LifeThemeMode.obsidian,
      apiClient: _ErrorProfileApiClient(),
      goldenPath: '../../docs/ui/review/obsidian-home-offline-v3.png',
    );

    expect(find.text('暂时未能连接今日节律'), findsOneWidget);
    expect(find.text('网络暂不可用，已保留你的本地设置。'), findsOneWidget);
    expect(find.text('重新加载'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
