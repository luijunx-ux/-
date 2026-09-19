import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tianrenlu/core/life_theme.dart';
import 'package:tianrenlu/features/advice/presentation/vitality_ai_analysis_page.dart';
import 'package:tianrenlu/features/profile/data/profile_api_client.dart';
import 'package:tianrenlu/features/profile/domain/profile_models.dart';

class _AdviceReviewClient extends ProfileApiClient {
  _AdviceReviewClient() : super(baseUrl: 'http://visual-review.invalid');

  @override
  Future<DailyAdvice> getDailyAdvice(
    BirthInput input,
    DateTime targetDate, {
    String? profileId,
  }) async =>
      DailyAdvice(
        id: 'review-advice',
        profileId: profileId,
        targetDate: targetDate,
        items: const <String>[
          '保持规律作息，并按身体感受安排一段轻松活动。',
          '今天的建议基于确定性节律结果与已审核的通用生活模板。',
          '睡眠、步数与恢复准备度尚未授权，因此没有参与本次分析。',
        ],
        disclaimer: '内容用于日常自我照顾参考，不构成医疗诊断或治疗建议。',
        generationMode: 'llm',
        model: 'review-model',
        knowledgeSources: const <String>['日常节律指南', '安全表达规范'],
      );

  @override
  Future<DailyAdvice> submitAdviceFeedback(
    String adviceId, {
    required bool helpful,
  }) async =>
      DailyAdvice(
        id: adviceId,
        targetDate: DateTime(2026, 9, 19),
        items: const <String>['保持规律作息，并按身体感受安排一段轻松活动。'],
        disclaimer: '内容用于日常自我照顾参考，不构成医疗诊断或治疗建议。',
        generationMode: 'llm',
        knowledgeSources: const <String>['日常节律指南'],
        helpful: helpful,
      );
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
          key: const Key('vitality-ai-review'),
          child: VitalityAiAnalysisPage(
            apiClient: _AdviceReviewClient(),
            profileId: 'review-profile',
            birthInput: BirthInput(
              occurredAt: DateTime(1992, 5, 18, 9, 30),
              placeName: '上海',
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

  testWidgets('Vitality AI analysis visual review',
      (WidgetTester tester) async {
    await renderPage(tester);

    expect(find.text('今日综合分析'), findsOneWidget);
    expect(find.text('生命参考分：数据不足'), findsOneWidget);
    expect(find.text('健康与设备数据'), findsOneWidget);
    expect(find.text('尚未授权'), findsOneWidget);
    expect(find.text('4,286步'), findsNothing);
    expect(find.text('6小时42分'), findsNothing);

    await expectLater(
      find.byKey(const Key('vitality-ai-review')),
      matchesGoldenFile(
        '../../docs/ui/review/vitality-ai-analysis-mobile-v1.png',
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Vitality AI analysis explanation and question are safe',
      (WidgetTester tester) async {
    await renderPage(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.text('为什么这样建议？'));
    await tester.pumpAndSettle();
    expect(find.textContaining('睡眠、步数与恢复准备度尚未授权'), findsOneWidget);

    await tester.ensureVisible(find.text('今天适合安排什么活动？'));
    await tester.tap(find.text('今天适合安排什么活动？'));
    await tester.pumpAndSettle();
    expect(find.textContaining('不会上传新的健康信息'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
