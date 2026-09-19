import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tianrenlu/core/life_theme.dart';
import 'package:tianrenlu/features/advice/presentation/daily_advice_page.dart';
import 'package:tianrenlu/features/advice/presentation/advice_history_page.dart';
import 'package:tianrenlu/features/profile/data/profile_api_client.dart';
import 'package:tianrenlu/features/profile/domain/profile_models.dart';
import 'package:tianrenlu/features/profile/presentation/profile_form_page.dart';
import 'package:tianrenlu/features/profile/presentation/profile_result_page.dart';
import 'package:tianrenlu/features/profile/presentation/saved_profiles_page.dart';
import 'package:tianrenlu/features/profile/presentation/vitality_home_sections.dart';

class TodayDashboardPage extends StatefulWidget {
  const TodayDashboardPage({
    required this.apiClient,
    required this.accountPageBuilder,
    required this.themeMode,
    required this.onThemeChanged,
    this.now,
    super.key,
  });

  final ProfileApiClient apiClient;
  final Widget Function() accountPageBuilder;
  final LifeThemeMode themeMode;
  final ValueChanged<LifeThemeMode> onThemeChanged;
  final DateTime? now;

  @override
  State<TodayDashboardPage> createState() => _TodayDashboardPageState();
}

class _TodayDashboardPageState extends State<TodayDashboardPage> {
  List<LifeProfile>? _profiles;
  String? _error;
  int _viewingStreak = 0;

  DateTime get _now => widget.now ?? DateTime.now();

  LifeProfile? get _defaultProfile {
    final profiles = _profiles;
    if (profiles == null || profiles.isEmpty) return null;
    return profiles.firstWhere((p) => p.isDefault,
        orElse: () => profiles.first);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final profiles = await widget.apiClient.listProfiles();
      final streak = await widget.apiClient.getViewingStreak(_now);
      if (mounted) {
        setState(() {
          _profiles = profiles;
          _viewingStreak = streak;
        });
      }
    } on ProfileApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context)
        .push<void>(MaterialPageRoute(builder: (_) => page));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<LifeThemeTokens>()!;
    final bool forest = t.mode == LifeThemeMode.forest;
    final profile = _defaultProfile;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (forest)
            Image.asset(
              'assets/images/forest_life_hero_v1.png',
              fit: BoxFit.cover,
              alignment: const Alignment(.18, -.72),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: forest
                    ? <Color>[
                        const Color(0x99E2EEE2),
                        const Color(0xB8A9C5AE),
                        const Color(0xE636694C),
                      ]
                    : <Color>[t.backgroundTop, t.backgroundBottom],
                stops: forest ? const <double>[0, .48, 1] : null,
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: <Widget>[
                  _Header(
                    greeting: _greeting(),
                    date: _today(),
                    location: profile?.birthInput?.placeName,
                    themeMode: widget.themeMode,
                    onThemeChanged: widget.onThemeChanged,
                    onAccount: () => _open(widget.accountPageBuilder()),
                  ),
                  const SizedBox(height: 22),
                  if (_profiles == null && _error == null)
                    const _LoadingState()
                  else if (_error != null)
                    _ErrorState(message: _error!, onRetry: _load)
                  else if (profile == null)
                    _EmptyProfileCard(
                        onCreate: () =>
                            _open(ProfileFormPage(apiClient: widget.apiClient)))
                  else
                    ..._profileContent(profile, t),
                  const SizedBox(height: 18),
                  _QuickActions(
                    onCreate: () =>
                        _open(ProfileFormPage(apiClient: widget.apiClient)),
                    onProfiles: () =>
                        _open(SavedProfilesPage(apiClient: widget.apiClient)),
                    onHistory: () =>
                        _open(AdviceHistoryPage(apiClient: widget.apiClient)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _profileContent(LifeProfile profile, LifeThemeTokens t) {
    final canOpen = profile.birthInput != null;
    void openProfile(ProfileRhythmSection section) => _open(ProfileResultPage(
          profile: profile,
          birthInput: profile.birthInput!,
          apiClient: widget.apiClient,
          initialSection: section,
        ));
    if (t.mode == LifeThemeMode.vitality) {
      return <Widget>[
        VitalityHomeSections(
          profile: profile,
          onOpenYunqi: canOpen
              ? () => openProfile(ProfileRhythmSection.wuyunLiuqi)
              : null,
          onOpenStellar:
              canOpen ? () => openProfile(ProfileRhythmSection.zodiac) : null,
          onOpenAdvice: canOpen
              ? () => _open(DailyAdvicePage(
                  apiClient: widget.apiClient,
                  birthInput: profile.birthInput!,
                  profileId: profile.id))
              : null,
          onOpenHistory: () =>
              _open(AdviceHistoryPage(apiClient: widget.apiClient)),
          onOpenAccount: () => _open(widget.accountPageBuilder()),
        ),
      ];
    }
    return <Widget>[
      _LifeHero(
          profile: profile,
          streak: _viewingStreak,
          onAdvice: canOpen
              ? () => _open(DailyAdvicePage(
                  apiClient: widget.apiClient,
                  birthInput: profile.birthInput!,
                  profileId: profile.id))
              : null),
      const SizedBox(height: 18),
      Text('两种节律，同看今日',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text('确定性规则计算结果，AI 仅负责温和解释。', style: TextStyle(color: t.textSecondary)),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final List<Widget> cards = <Widget>[
            _CoreCard(
                icon: Icons.eco_outlined,
                eyebrow: '天地节律',
                title: '五运六气',
                summary:
                    '${profile.wuyunLiuqi.middleMovement} · ${profile.wuyunLiuqi.movementStrength}',
                onTap: canOpen
                    ? () => openProfile(ProfileRhythmSection.wuyunLiuqi)
                    : null),
            _CoreCard(
                icon: Icons.nightlight_round,
                eyebrow: '个体节律',
                title: '星辰节律',
                summary: '${profile.zodiac.sign} · ${profile.zodiac.element}',
                onTap: canOpen
                    ? () => openProfile(ProfileRhythmSection.zodiac)
                    : null),
          ];
          if (constraints.maxWidth < 370) {
            return Column(children: <Widget>[
              SizedBox(width: double.infinity, child: cards.first),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: cards.last),
            ]);
          }
          return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: cards.first),
                const SizedBox(width: 12),
                Expanded(child: cards.last),
              ]);
        },
      ),
      const SizedBox(height: 22),
      Row(children: <Widget>[
        Expanded(
            child: Text('今日温和建议',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700))),
        TextButton(
            onPressed: canOpen
                ? () => _open(DailyAdvicePage(
                    apiClient: widget.apiClient,
                    birthInput: profile.birthInput!,
                    profileId: profile.id))
                : null,
            child: const Text('查看完整建议')),
      ]),
      const SizedBox(height: 8),
      const _AdviceRibbon(),
      const SizedBox(height: 22),
      _CompanionCard(
          profileName: profile.name,
          onTap: canOpen
              ? () => _open(DailyAdvicePage(
                  apiClient: widget.apiClient,
                  birthInput: profile.birthInput!,
                  profileId: profile.id))
              : null),
      const SizedBox(height: 14),
      _DataStatusCard(
          algorithmVersion: profile.wuyunLiuqi.algorithmVersion,
          timezone: profile.birthInput?.timezone ?? '时区未记录'),
    ];
  }

  String _greeting() {
    final hour = _now.hour;
    if (hour < 11) return '早上好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  String _today() {
    final now = _now;
    return '${now.year}年${now.month}月${now.day}日';
  }
}

class _Header extends StatelessWidget {
  const _Header(
      {required this.greeting,
      required this.date,
      required this.location,
      required this.themeMode,
      required this.onThemeChanged,
      required this.onAccount});
  final String greeting;
  final String date;
  final String? location;
  final LifeThemeMode themeMode;
  final ValueChanged<LifeThemeMode> onThemeChanged;
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<LifeThemeTokens>()!;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
            Text('$greeting，慢慢感受今天',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: -.5)),
            const SizedBox(height: 5),
            Text(
                '$date${location == null || location!.isEmpty ? '' : '  ·  $location'}',
                style: TextStyle(color: t.textSecondary)),
          ])),
      PopupMenuButton<LifeThemeMode>(
        tooltip: '切换生命主题',
        onSelected: onThemeChanged,
        itemBuilder: (_) => const <PopupMenuEntry<LifeThemeMode>>[
          PopupMenuItem(
              value: LifeThemeMode.forest, child: Text('Forest Life 森林生命')),
          PopupMenuItem(
              value: LifeThemeMode.obsidian, child: Text('Obsidian Life 黑曜生命')),
          PopupMenuItem(
              value: LifeThemeMode.vitality, child: Text('Vitality Life 悦活生命')),
        ],
        icon: Icon(switch (themeMode) {
          LifeThemeMode.forest => Icons.park_outlined,
          LifeThemeMode.obsidian => Icons.auto_awesome_outlined,
          LifeThemeMode.vitality => Icons.wb_sunny_outlined,
        }),
      ),
      IconButton(
          tooltip: '账户与隐私',
          onPressed: onAccount,
          icon: const Icon(Icons.person_outline_rounded)),
    ]);
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard(
      {required this.child,
      this.padding = const EdgeInsets.all(18),
      this.onTap,
      this.radius = 28});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<LifeThemeTokens>()!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: t.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
              side: BorderSide(color: t.outline)),
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: Padding(padding: padding, child: child)),
        ),
      ),
    );
  }
}

class _LifeHero extends StatelessWidget {
  const _LifeHero(
      {required this.profile, required this.streak, required this.onAdvice});
  final LifeProfile profile;
  final int streak;
  final VoidCallback? onAdvice;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<LifeThemeTokens>()!;
    final bool forest = t.mode == LifeThemeMode.forest;
    return Container(
        height: 350,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border:
                Border.all(color: Colors.white.withValues(alpha: .9), width: 3),
            boxShadow: <BoxShadow>[
              BoxShadow(
                  color: t.accent.withValues(alpha: .28),
                  blurRadius: 36,
                  offset: const Offset(0, 18))
            ]),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: Stack(fit: StackFit.expand, children: <Widget>[
              if (forest)
                Image.asset('assets/images/forest_life_hero_v1.png',
                    fit: BoxFit.cover, alignment: const Alignment(.25, -.65))
              else
                const _ObsidianScene(),
              DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                    Colors.transparent,
                    Colors.transparent,
                    (forest ? const Color(0xFF153D2A) : const Color(0xFF080B12))
                        .withValues(alpha: .96)
                  ],
                          stops: const <double>[
                    0,
                    .42,
                    1
                  ]))),
              Positioned(
                  left: 18,
                  right: 18,
                  top: 18,
                  child: Row(children: <Widget>[
                    _HeroCircle(
                        icon:
                            forest ? Icons.spa_outlined : Icons.blur_circular),
                    const Spacer(),
                    const _HeroCircle(icon: Icons.more_horiz_rounded)
                  ])),
              Positioned(
                  left: 22,
                  right: 22,
                  bottom: 20,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('今日生命状态',
                            style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 5),
                        const Text('顺势舒展',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 31,
                                height: 1.1,
                                letterSpacing: -.8,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Row(children: <Widget>[
                          Expanded(
                              child: Text(
                                  '${profile.name} · ${profile.wuyunLiuqi.middleMovement}之日',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16))),
                          const SizedBox(width: 8),
                          IconButton.filled(
                              onPressed: onAdvice,
                              tooltip: '查看今日建议',
                              icon: const Icon(Icons.arrow_outward_rounded),
                              style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF163C2A),
                                  minimumSize: const Size(48, 48)))
                        ])
                      ]))
            ])));
  }
}

class _HeroCircle extends StatelessWidget {
  const _HeroCircle({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: .2),
          border: Border.all(color: Colors.white.withValues(alpha: .72))),
      child: Icon(icon, color: Colors.white, size: 28));
}

class _ObsidianScene extends StatelessWidget {
  const _ObsidianScene();
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: const BoxDecoration(
          gradient: RadialGradient(
              center: Alignment(.25, -.45),
              radius: 1.15,
              colors: <Color>[
            Color(0xFF46558F),
            Color(0xFF171D35),
            Color(0xFF080B12)
          ])),
      child: CustomPaint(painter: _StarPainter()));
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint orbit = Paint()
      ..color = const Color(0x5578A9FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * .66, size.height * .35),
            width: size.width * .72,
            height: size.height * .38),
        orbit);
    final Paint star = Paint()..color = const Color(0x99F3C77A);
    for (final Offset point in const <Offset>[
      Offset(.14, .22),
      Offset(.32, .4),
      Offset(.56, .18),
      Offset(.72, .28),
      Offset(.85, .5),
      Offset(.46, .58)
    ]) {
      canvas.drawCircle(
          Offset(size.width * point.dx, size.height * point.dy), 2.2, star);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CoreCard extends StatelessWidget {
  const _CoreCard(
      {required this.icon,
      required this.eyebrow,
      required this.title,
      required this.summary,
      required this.onTap});
  final IconData icon;
  final String eyebrow;
  final String title;
  final String summary;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<LifeThemeTokens>()!;
    return _GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        radius: 24,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.surfaceStrong,
                      border: Border.all(color: t.outline)),
                  child: Icon(icon, color: t.accent)),
              const SizedBox(height: 18),
              Text(eyebrow,
                  style: TextStyle(color: t.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.textSecondary, height: 1.35)),
              const SizedBox(height: 12),
              Align(
                  alignment: Alignment.centerRight,
                  child: Icon(Icons.arrow_outward_rounded, color: t.accent)),
            ]));
  }
}

class _AdviceRibbon extends StatelessWidget {
  const _AdviceRibbon();
  static const items = <(IconData, String, String)>[
    (Icons.restaurant_outlined, '饮食', '温热清淡，留意身体感受'),
    (Icons.bedtime_outlined, '睡眠', '今晚稍早收束思绪'),
    (Icons.directions_walk_outlined, '运动', '舒缓伸展，循序渐进'),
    (Icons.favorite_border_rounded, '情绪', '给自己一段安静留白'),
  ];
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        return _GlassCard(
            radius: 28,
            padding: const EdgeInsets.all(8),
            child: Wrap(spacing: 4, runSpacing: 4, children: <Widget>[
              for (final item in items)
                SizedBox(
                    width: (constraints.maxWidth - 20) / 2,
                    child: _AdviceCard(
                        icon: item.$1, title: item.$2, copy: item.$3)),
            ]));
      });
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard(
      {required this.icon, required this.title, required this.copy});
  final IconData icon;
  final String title;
  final String copy;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<LifeThemeTokens>()!;
    return Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: t.accent),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(copy,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: t.textSecondary, height: 1.35, fontSize: 13)),
            ]));
  }
}

class _CompanionCard extends StatelessWidget {
  const _CompanionCard({required this.profileName, required this.onTap});

  final String profileName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    final bool forest = t.mode == LifeThemeMode.forest;
    return _GlassCard(
        onTap: onTap,
        radius: 30,
        padding: const EdgeInsets.all(18),
        child: Row(children: <Widget>[
          _LifeOrb(tokens: t),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                Row(children: <Widget>[
                  Text('AI 生命陪伴',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: t.glow.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(99)),
                      child: Text('今日',
                          style: TextStyle(
                              color: forest ? t.accent : t.glow,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)))
                ]),
                const SizedBox(height: 7),
                Text('$profileName，今天可以从一次缓慢呼吸开始。',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: t.textSecondary, height: 1.45)),
                const SizedBox(height: 9),
                Row(children: <Widget>[
                  Icon(Icons.auto_awesome_rounded,
                      color: forest ? t.accent : t.glow, size: 17),
                  const SizedBox(width: 6),
                  Text('查看解释与可执行建议',
                      style: TextStyle(
                          color: forest ? t.accent : t.accentSoft,
                          fontWeight: FontWeight.w700))
                ])
              ])),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded, color: t.accent)
        ]));
  }
}

class _LifeOrb extends StatelessWidget {
  const _LifeOrb({required this.tokens});

  final LifeThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final bool forest = tokens.mode == LifeThemeMode.forest;
    return Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: <Color>[
              tokens.glow.withValues(alpha: .9),
              (forest ? tokens.accentSoft : tokens.accent)
                  .withValues(alpha: .75),
              tokens.surfaceStrong
            ]),
            border: Border.all(color: tokens.outline, width: 2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                  color: (forest ? tokens.accent : tokens.glow)
                      .withValues(alpha: .28),
                  blurRadius: 26)
            ]),
        child: Center(
            child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.surface.withValues(alpha: .55),
                    border: Border.all(color: tokens.outline)),
                child: Icon(
                    forest ? Icons.water_drop_outlined : Icons.blur_circular,
                    color: tokens.textPrimary,
                    size: 23))));
  }
}

class _DataStatusCard extends StatelessWidget {
  const _DataStatusCard(
      {required this.algorithmVersion, required this.timezone});

  final String algorithmVersion;
  final String timezone;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return _GlassCard(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(children: <Widget>[
          _StatusRow(
              icon: Icons.verified_outlined,
              title: '节律计算',
              value: '规则引擎 · $algorithmVersion'),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: t.outline)),
          _StatusRow(
              icon: Icons.public_rounded, title: '时间基准', value: timezone),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: t.outline)),
          const _StatusRow(
              icon: Icons.cloud_off_outlined,
              title: '环境数据',
              value: '暂不可用 · 未参与今日建议'),
        ]));
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow(
      {required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return Row(children: <Widget>[
      Icon(icon, color: t.accent, size: 20),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(width: 12),
      Expanded(
          child: Text(value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: t.textSecondary, fontSize: 13)))
    ]);
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions(
      {required this.onCreate,
      required this.onProfiles,
      required this.onHistory});
  final VoidCallback onCreate;
  final VoidCallback onProfiles;
  final VoidCallback onHistory;
  @override
  Widget build(BuildContext context) => _GlassCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(children: <Widget>[
        Expanded(
            child: _QuickAction(
                onTap: onCreate,
                icon: Icons.person_add_alt_1_outlined,
                label: '新建档案')),
        Expanded(
            child: _QuickAction(
                onTap: onProfiles,
                icon: Icons.folder_copy_outlined,
                label: '档案管理')),
        Expanded(
            child: _QuickAction(
                onTap: onHistory, icon: Icons.history_rounded, label: '建议历史')),
      ]));
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.onTap, required this.icon, required this.label});

  final VoidCallback onTap;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Icon(icon, size: 22),
                const SizedBox(height: 6),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700))
              ]))));
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => const _GlassCard(
      child: SizedBox(
          height: 180, child: Center(child: CircularProgressIndicator())));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => _GlassCard(
          child: Column(children: <Widget>[
        const Icon(Icons.cloud_off_outlined, size: 42),
        const SizedBox(height: 12),
        const Text('暂时未能连接今日节律', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 14),
        FilledButton.tonal(onPressed: onRetry, child: const Text('重新加载')),
      ]));
}

class _EmptyProfileCard extends StatelessWidget {
  const _EmptyProfileCard({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) => _GlassCard(
          child: Column(children: <Widget>[
        const Icon(Icons.spa_outlined, size: 52),
        const SizedBox(height: 14),
        Text('从一份生命档案开始',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('记录出生日期、时间与地点，查看属于你的今日节律。', textAlign: TextAlign.center),
        const SizedBox(height: 18),
        FilledButton(onPressed: onCreate, child: const Text('建立生命档案')),
      ]));
}
