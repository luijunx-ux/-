import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tianrenlu/core/life_theme.dart';
import 'package:tianrenlu/features/advice/presentation/daily_advice_page.dart';
import 'package:tianrenlu/features/profile/data/profile_api_client.dart';
import 'package:tianrenlu/features/profile/domain/profile_models.dart';

enum ProfileRhythmSection { overview, wuyunLiuqi, zodiac }

class ProfileResultPage extends StatelessWidget {
  const ProfileResultPage({
    required this.profile,
    required this.birthInput,
    required this.apiClient,
    this.initialSection = ProfileRhythmSection.overview,
    super.key,
  });

  final LifeProfile profile;
  final BirthInput birthInput;
  final ProfileApiClient apiClient;
  final ProfileRhythmSection initialSection;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    final WuyunLiuqiInfo rhythm = profile.wuyunLiuqi;
    final bool showWuyun = initialSection != ProfileRhythmSection.zodiac;
    final bool showZodiac = initialSection != ProfileRhythmSection.wuyunLiuqi;
    final String pageTitle = switch (initialSection) {
      ProfileRhythmSection.overview => '生命档案',
      ProfileRhythmSection.wuyunLiuqi => '五运六气',
      ProfileRhythmSection.zodiac => '星辰节律',
    };
    final String sectionTitle = switch (initialSection) {
      ProfileRhythmSection.overview => '两种节律，构成你的参考底图',
      ProfileRhythmSection.wuyunLiuqi => '读懂今日天地节律的结构',
      ProfileRhythmSection.zodiac => '太阳星座的温和倾向参考',
    };
    final String sectionDescription = switch (initialSection) {
      ProfileRhythmSection.overview => '结果来自确定性规则计算，不由 AI 猜测。',
      ProfileRhythmSection.wuyunLiuqi => '五运六气由规则引擎计算，环境数据缺失时会明确标注。',
      ProfileRhythmSection.zodiac => 'MVP 仅展示太阳星座，不推测月亮、上升或人生事件。',
    };
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(pageTitle),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[t.backgroundTop, t.backgroundBottom],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: <Widget>[
              _ProfileHero(profile: profile),
              const SizedBox(height: 22),
              Text(sectionTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(sectionDescription,
                  style: TextStyle(color: t.textSecondary)),
              const SizedBox(height: 14),
              if (showWuyun) ...<Widget>[
                _RhythmSection(
                  icon: Icons.eco_outlined,
                  eyebrow: '五运六气 · ${rhythm.algorithmVersion}',
                  title: '${rhythm.heavenlyStem}${rhythm.earthlyBranch}年',
                  rows: <(String, String)>[
                    (
                      '中运',
                      '${rhythm.middleMovement} · ${rhythm.movementStrength}'
                    ),
                    ('司天', rhythm.governingQi),
                    ('在泉', rhythm.respondingQi),
                  ],
                ),
                if (initialSection ==
                    ProfileRhythmSection.wuyunLiuqi) ...<Widget>[
                  const SizedBox(height: 14),
                  _RhythmSection(
                    icon: Icons.public_rounded,
                    eyebrow: '时间与环境上下文',
                    title: birthInput.timezone,
                    rows: <(String, String)>[
                      ('出生地点', birthInput.placeName),
                      ('时间基准', birthInput.timezone),
                      ('环境数据', '暂不可用 · 未参与本次结果'),
                    ],
                  ),
                ],
              ],
              if (showWuyun && showZodiac) const SizedBox(height: 14),
              if (showZodiac)
                _RhythmSection(
                  icon: Icons.nightlight_round,
                  eyebrow: '星辰节律 · MVP 太阳星座',
                  title: profile.zodiac.sign,
                  rows: <(String, String)>[
                    ('元素', profile.zodiac.element),
                    ('模式', profile.zodiac.modality),
                    ('月亮与上升', '未来能力 · 当前不推测'),
                  ],
                ),
              if (rhythm.boundaryWarning != null) ...<Widget>[
                const SizedBox(height: 14),
                _NoticeCard(
                    icon: Icons.info_outline_rounded,
                    text: rhythm.boundaryWarning!),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => DailyAdvicePage(
                      apiClient: apiClient,
                      birthInput: birthInput,
                      profileId: profile.id,
                    ),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('进入 AI 生命建议'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54)),
              ),
              const SizedBox(height: 18),
              _NoticeCard(
                  icon: Icons.shield_outlined, text: profile.disclaimer),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile});
  final LifeProfile profile;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return _GlassPanel(
      radius: 32,
      child: Row(children: <Widget>[
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: <Color>[
              t.glow.withValues(alpha: .88),
              t.accentSoft.withValues(alpha: .7),
              t.surfaceStrong,
            ]),
            border: Border.all(color: t.outline, width: 2),
          ),
          child: Icon(Icons.spa_outlined, color: t.accent, size: 36),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('个人生命档案', style: TextStyle(color: t.textSecondary)),
              const SizedBox(height: 5),
              Text(profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              Text(profile.birthInput?.placeName ?? '地点未记录',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.textSecondary)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _RhythmSection extends StatelessWidget {
  const _RhythmSection({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.rows,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return _GlassPanel(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(children: <Widget>[
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.surfaceStrong,
                      border: Border.all(color: t.outline)),
                  child: Icon(icon, color: t.accent)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                    Text(eyebrow,
                        style: TextStyle(color: t.textSecondary, fontSize: 13)),
                    const SizedBox(height: 3),
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ])),
            ]),
            const SizedBox(height: 16),
            for (int index = 0; index < rows.length; index++) ...<Widget>[
              if (index > 0) Divider(height: 20, color: t.outline),
              Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                        width: 88,
                        child: Text(rows[index].$1,
                            style: TextStyle(color: t.textSecondary))),
                    Expanded(
                        child: Text(rows[index].$2,
                            textAlign: TextAlign.right,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700))),
                  ]),
            ],
          ]),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return _GlassPanel(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Icon(icon, color: t.accent, size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: TextStyle(color: t.textSecondary, height: 1.45))),
      ]),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 26,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: t.outline),
          ),
          child: child,
        ),
      ),
    );
  }
}
