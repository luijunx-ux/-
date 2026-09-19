import 'package:flutter/material.dart';
import 'package:tianrenlu/core/life_theme.dart';
import 'package:tianrenlu/core/life_surface.dart';
import 'package:tianrenlu/features/profile/domain/profile_models.dart';

class VitalityHomeSections extends StatefulWidget {
  const VitalityHomeSections({
    required this.profile,
    required this.onOpenYunqi,
    required this.onOpenStellar,
    required this.onOpenAdvice,
    required this.onOpenHistory,
    required this.onOpenAccount,
    super.key,
  });

  final LifeProfile profile;
  final VoidCallback? onOpenYunqi;
  final VoidCallback? onOpenStellar;
  final VoidCallback? onOpenAdvice;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenAccount;

  @override
  State<VitalityHomeSections> createState() => _VitalityHomeSectionsState();
}

class _VitalityHomeSectionsState extends State<VitalityHomeSections> {
  String _energy = '一般';
  bool _recorded = false;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens tokens =
        Theme.of(context).extension<LifeThemeTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _DailyHero(),
        const SizedBox(height: 14),
        const _LifeStatusPanel(),
        const SizedBox(height: 14),
        _AiAnalysisPanel(onTap: widget.onOpenAdvice),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool stacked = constraints.maxWidth < 350;
            final Widget yunqi = _RhythmEntry(
              imageAsset: 'assets/images/vitality_breakfast_v1.jpg',
              eyebrow: '五运六气 · 专业节律入口',
              title: '天地节律',
              tag: '规则结果',
              summary:
                  '${widget.profile.wuyunLiuqi.middleMovement} · ${widget.profile.wuyunLiuqi.movementStrength}。结合日常规律进行温和观察。',
              hint: '查看专业术语 / 通俗解释',
              accent: tokens.accent,
              onTap: widget.onOpenYunqi,
            );
            final Widget stellar = _RhythmEntry(
              imageAsset: 'assets/images/vitality_evening_v1.jpg',
              eyebrow: '星辰节律 · 太阳星座入口',
              title: '自我观察',
              tag: '太阳星座',
              summary:
                  '${widget.profile.zodiac.sign} · ${widget.profile.zodiac.element}元素。关注专注、沟通与休息边界。',
              hint: '查看专业术语 / 通俗解释',
              accent: const Color(0xFF5D5794),
              onTap: widget.onOpenStellar,
            );
            if (stacked) {
              return Column(children: <Widget>[
                yunqi,
                const SizedBox(height: 12),
                stellar,
              ]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: yunqi),
                const SizedBox(width: 10),
                Expanded(child: stellar),
              ],
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            '两个入口同等级呈现 · 分别进入详细解读页',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11),
          ),
        ),
        const SizedBox(height: 14),
        _AdvicePanel(onTap: widget.onOpenAdvice),
        const SizedBox(height: 14),
        _FocusCheckIn(
          energy: _energy,
          recorded: _recorded,
          onEnergyChanged: (String value) => setState(() => _energy = value),
          onSave: () => setState(() => _recorded = true),
        ),
        const SizedBox(height: 14),
        _BottomNavigation(
          onHistory: widget.onOpenHistory,
          onAccount: widget.onOpenAccount,
        ),
      ],
    );
  }
}

class _DailyHero extends StatelessWidget {
  const _DailyHero();

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: '清晨阳光下沿湖散步的生活场景',
        child: Container(
          height: 146,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: const DecorationImage(
              image: AssetImage('assets/images/vitality_walk_v1.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: <Color>[Color(0xC9143729), Color(0x11143729)],
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text('今日生活主题 · 环境数据暂不可用',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  SizedBox(height: 4),
                  Text('从清晨开始，照顾今日的自己',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('图片按自然日保持稳定 · 使用内置审核素材',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      );
}

class _LifeStatusPanel extends StatelessWidget {
  const _LifeStatusPanel();

  @override
  Widget build(BuildContext context) => LifePanel(
        radius: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('今日生命状态 · 数据状态已核对', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            Text('等待更多真实数据',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            const _MetricGrid(),
          ],
        ),
      );
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = (constraints.maxWidth - 8) / 2;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _Metric(
                  width: width,
                  label: '生命参考状态',
                  value: '数据不足',
                  note: '未达到 V0.1 显示门槛'),
              _Metric(
                  width: width,
                  label: '今日步数',
                  value: '连接设备',
                  note: '尚未获得健康平台授权'),
              _Metric(
                  width: width, label: '睡眠时长', value: '暂无数据', note: '需要有效睡眠记录'),
              _Metric(
                  width: width,
                  label: 'Readiness',
                  value: '暂不可用',
                  note: '不使用推测值'),
            ],
          );
        },
      );
}

class _Metric extends StatelessWidget {
  const _Metric(
      {required this.width,
      required this.label,
      required this.value,
      required this.note});
  final double width;
  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: t.surfaceStrong, borderRadius: BorderRadius.circular(15)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: TextStyle(color: t.textSecondary, fontSize: 12)),
            const SizedBox(height: 9),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(note,
                style: TextStyle(
                    color: t.textSecondary, fontSize: 11, height: 1.35)),
          ]),
    );
  }
}

class _AiAnalysisPanel extends StatelessWidget {
  const _AiAnalysisPanel({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return LifePanel(
      onTap: onTap,
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(children: <Widget>[
              Expanded(
                  child: Text('天人律 AI 分析',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800))),
              Icon(Icons.auto_awesome_rounded, color: t.accent),
            ]),
            const SizedBox(height: 8),
            const Text('当前缺少睡眠与活动授权，暂不生成个性化健康判断。可以先查看文化节律解释与通用生活建议。'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF2E8),
                  borderRadius: BorderRadius.circular(14)),
              child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('今日优先行动',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 3),
                    Text('保持规律作息，并按身体感受安排活动。'),
                  ]),
            ),
            const SizedBox(height: 9),
            Text('来源：生命档案 · 确定性节律结果 · 已审核通用模板',
                style: TextStyle(color: t.textSecondary, fontSize: 11)),
          ]),
    );
  }
}

class _RhythmEntry extends StatelessWidget {
  const _RhythmEntry(
      {required this.imageAsset,
      required this.eyebrow,
      required this.title,
      required this.tag,
      required this.summary,
      required this.hint,
      required this.accent,
      required this.onTap});
  final String imageAsset;
  final String eyebrow;
  final String title;
  final String tag;
  final String summary;
  final String hint;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return LifePanel(
      onTap: onTap,
      padding: EdgeInsets.zero,
      radius: 20,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 100,
              child: Stack(fit: StackFit.expand, children: <Widget>[
                Image.asset(imageAsset, fit: BoxFit.cover),
                DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: <Color>[
                  accent.withValues(alpha: .82),
                  accent.withValues(alpha: .08)
                ]))),
                Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(eyebrow,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 10)),
                        const SizedBox(height: 3),
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w700)),
                      ]),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                            color: accent.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(99)),
                        child: Text(tag,
                            style: TextStyle(color: accent, fontSize: 11))),
                    const SizedBox(height: 9),
                    Text(summary,
                        style: const TextStyle(fontSize: 12, height: 1.5)),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: t.outline),
                    const SizedBox(height: 9),
                    Text(hint,
                        style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ]),
            ),
          ]),
    );
  }
}

class _AdvicePanel extends StatelessWidget {
  const _AdvicePanel({required this.onTap});
  final VoidCallback? onTap;
  static const List<(IconData, String, String)> items =
      <(IconData, String, String)>[
    (Icons.restaurant_outlined, '饮食', '保持三餐稳定，按口渴感适量补水。'),
    (Icons.bedtime_outlined, '睡眠', '今晚提前进入安静节奏。'),
    (Icons.directions_walk_outlined, '活动', '安排一段轻松步行。'),
    (Icons.favorite_border_rounded, '情绪', '减少连续信息输入。'),
  ];

  @override
  Widget build(BuildContext context) => LifePanel(
        onTap: onTap,
        radius: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('今天怎样照顾自己',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('以下为已审核的通用温和建议，不替代专业意见。',
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                final double width = (constraints.maxWidth - 8) / 2;
                return Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
                  for (final item in items)
                    _AdviceTile(
                        width: width,
                        icon: item.$1,
                        title: item.$2,
                        copy: item.$3),
                ]);
              }),
              const SizedBox(height: 10),
              _MeditationEntry(onTap: () => _showMeditationPreview(context)),
            ]),
      );

  void _showMeditationPreview(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '正念冥想',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                '未来将与“冥想室”应用打通，提供经过审核的呼吸、放松与正念练习。当前版本暂不跳转，也不会传输个人数据。',
                style: TextStyle(height: 1.55),
              ),
              const SizedBox(height: 12),
              const Text(
                '冥想内容仅作日常自我照顾参考，不替代医疗或心理专业服务。',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('我知道了'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeditationEntry extends StatelessWidget {
  const _MeditationEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return Material(
      color: t.accentSoft,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .76),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.self_improvement_rounded, color: t.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Text('正念冥想',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .72),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text('即将接入',
                                style:
                                    TextStyle(color: t.accent, fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text('呼吸与放松练习', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Icon(Icons.chevron_right_rounded, color: t.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdviceTile extends StatelessWidget {
  const _AdviceTile(
      {required this.width,
      required this.icon,
      required this.title,
      required this.copy});
  final double width;
  final IconData icon;
  final String title;
  final String copy;
  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 124),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          border: Border.all(color: t.outline),
          borderRadius: BorderRadius.circular(15)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: t.accent),
            const SizedBox(height: 9),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(copy,
                style: TextStyle(
                    color: t.textSecondary, fontSize: 12, height: 1.4)),
          ]),
    );
  }
}

class _FocusCheckIn extends StatelessWidget {
  const _FocusCheckIn(
      {required this.energy,
      required this.recorded,
      required this.onEnergyChanged,
      required this.onSave});
  final String energy;
  final bool recorded;
  final ValueChanged<String> onEnergyChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return LifePanel(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(children: <Widget>[
              Expanded(
                  child: Text('我的重点状态',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800))),
              Text(recorded ? '今日已记录 1 次' : '今日尚未记录',
                  style: TextStyle(color: t.accent, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            Row(children: <Widget>[
              Expanded(child: _Observed(label: '客观数据', value: '睡眠暂无数据')),
              const SizedBox(width: 8),
              Expanded(child: _Observed(label: '客观数据', value: '活动暂无数据')),
            ]),
            const SizedBox(height: 14),
            const Text('现在精力感觉怎么样？', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Row(children: <Widget>[
              for (final String value in const <String>[
                '偏低',
                '一般',
                '充足'
              ]) ...<Widget>[
                if (value != '偏低') const SizedBox(width: 7),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onEnergyChanged(value),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      backgroundColor: energy == value ? t.accentSoft : null,
                      side: BorderSide(
                          color: energy == value ? t.accent : t.outline),
                    ),
                    child: Text(value),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 10),
            SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: onSave,
                    child: Text(recorded ? '更新今日记录' : '记录此刻状态'))),
            const SizedBox(height: 12),
            Divider(height: 1, color: t.outline),
            const SizedBox(height: 10),
            const _TimelineRow(time: '09:12', text: '今日通用建议已生成'),
            if (recorded) const _TimelineRow(time: '刚刚', text: '完成一次主观状态记录'),
            const SizedBox(height: 7),
            Text('本次记录不会修改已经生成的生命参考分。',
                style: TextStyle(color: t.textSecondary, fontSize: 11)),
          ]),
    );
  }
}

class _Observed extends StatelessWidget {
  const _Observed({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
          color: t.surfaceStrong, borderRadius: BorderRadius.circular(14)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: TextStyle(color: t.textSecondary, fontSize: 10)),
            const SizedBox(height: 7),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ]),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.time, required this.text});
  final String time;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: <Widget>[
          SizedBox(
              width: 40,
              child: Text(time, style: const TextStyle(fontSize: 10))),
          const Icon(Icons.circle, size: 9, color: Color(0xFF8DBCA0)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 11))),
        ]),
      );
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({required this.onHistory, required this.onAccount});
  final VoidCallback onHistory;
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) => LifePanel(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(children: <Widget>[
          const Expanded(
              child: _NavItem(
                  icon: Icons.home_outlined, label: '今日', active: true)),
          const Expanded(
              child: _NavItem(icon: Icons.blur_circular, label: '节律')),
          Expanded(
              child: _NavItem(
                  icon: Icons.edit_note_outlined,
                  label: '记录',
                  onTap: onHistory)),
          Expanded(
              child: _NavItem(
                  icon: Icons.person_outline_rounded,
                  label: '我的',
                  onTap: onAccount)),
        ]),
      );
}

class _NavItem extends StatelessWidget {
  const _NavItem(
      {required this.icon,
      required this.label,
      this.active = false,
      this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, color: active ? t.accent : t.textSecondary, size: 21),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: active ? t.accent : t.textSecondary,
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
            ]),
      ),
    );
  }
}
