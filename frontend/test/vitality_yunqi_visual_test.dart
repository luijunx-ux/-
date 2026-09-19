import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tianrenlu/core/life_theme.dart';
import 'package:tianrenlu/features/profile/domain/profile_models.dart';
import 'package:tianrenlu/features/profile/presentation/vitality_yunqi_detail_page.dart';

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
    final List<String> candidates = <String>[
      if (configuredFont != null) configuredFont,
      if (Platform.isWindows) r'C:\Windows\Fonts\simhei.ttf',
      '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',
      '/System/Library/Fonts/PingFang.ttc',
    ];
    final String fontPath = candidates.firstWhere(
      (String path) => File(path).existsSync(),
      orElse: () => throw StateError('No review CJK font found.'),
    );
    await loadFont('ReviewChinese', fontPath);

    final String flutterRoot = Platform.environment['FLUTTER_ROOT']!;
    await loadFont(
      'MaterialIcons',
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
  }

  Future<void> renderPage(WidgetTester tester) async {
    await loadReviewFonts();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const LifeProfile profile = LifeProfile(
      id: 'yunqi-review',
      name: '清和',
      isDefault: true,
      zodiac: ZodiacInfo(sign: '金牛座', element: '土', modality: '固定'),
      wuyunLiuqi: WuyunLiuqiInfo(
        heavenlyStem: '壬',
        earthlyBranch: '寅',
        middleMovement: '木运',
        movementStrength: '太过',
        governingQi: '少阳相火',
        respondingQi: '厥阴风木',
        algorithmVersion: 'calendar-year-v1',
      ),
      disclaimer: '传统文化与一般生活方式参考，不构成医疗诊断或治疗建议。',
    );
    final ThemeData base = buildLifeTheme(LifeThemeMode.vitality);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: base.copyWith(
          textTheme: base.textTheme.apply(fontFamily: 'ReviewChinese'),
          primaryTextTheme:
              base.primaryTextTheme.apply(fontFamily: 'ReviewChinese'),
        ),
        home: RepaintBoundary(
          key: const Key('vitality-yunqi-review'),
          child: VitalityYunqiDetailPage(
            profile: profile,
            birthInput: BirthInput(
              occurredAt: DateTime(1992, 5, 18, 9, 30),
              placeName: '上海（档案出生地）',
              latitude: 31.2304,
              longitude: 121.4737,
              timezone: 'Asia/Shanghai',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Vitality yunqi detail visual review',
      (WidgetTester tester) async {
    await renderPage(tester);

    expect(find.text('专业术语与通俗解释'), findsOneWidget);
    expect(find.text('普通人怎么理解与使用'), findsOneWidget);
    expect(find.text('木运 · 太过'), findsOneWidget);
    expect(find.text('少阳相火'), findsOneWidget);
    expect(find.text('厥阴风木'), findsOneWidget);
    expect(find.textContaining('不因“太过”等词自行进补或减量'), findsOneWidget);

    await expectLater(
      find.byKey(const Key('vitality-yunqi-review')),
      matchesGoldenFile(
        '../../docs/ui/review/vitality-yunqi-detail-mobile-v1.png',
      ),
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('当前接口尚未提供'), findsOneWidget);
    expect(find.text('仅作解释背景，不参与加减分'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Vitality yunqi basis states deterministic boundaries',
      (WidgetTester tester) async {
    await renderPage(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1800));
    await tester.pumpAndSettle();
    final Finder button = find.text('查看计算依据、来源与缺失数据');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.textContaining('确定性规则引擎'), findsOneWidget);
    expect(find.textContaining('LLM 不参与'), findsOneWidget);
    expect(find.textContaining('实时天气、空气质量、健康平台数据'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
