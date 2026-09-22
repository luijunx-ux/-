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
    required this.onOpenAccount,
    super.key,
  });

  final LifeProfile profile;
  final VoidCallback? onOpenYunqi;
  final VoidCallback? onOpenStellar;
  final VoidCallback? onOpenAdvice;
  final VoidCallback onOpenAccount;

  @override
  State<VitalityHomeSections> createState() => _VitalityHomeSectionsState();
}

class _VitalityHomeSectionsState extends State<VitalityHomeSections> {
  String _energy = '一般';
  String _stress = '一般';
  String _body = '舒适';
  bool _recorded = false;
  String? _savedNote;
  final TextEditingController _noteController = TextEditingController();
  final GlobalKey _todayKey = GlobalKey();
  final GlobalKey _rhythmKey = GlobalKey();
  final GlobalKey _recordsKey = GlobalKey();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final BuildContext? target = key.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      alignment: .08,
    );
  }

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens tokens =
        Theme.of(context).extension<LifeThemeTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        KeyedSubtree(key: _todayKey, child: const _DailyHero()),
        const SizedBox(height: 14),
        const _LifeStatusPanel(),
        const SizedBox(height: 14),
        _AiAnalysisPanel(onTap: widget.onOpenAdvice),
        const SizedBox(height: 14),
        KeyedSubtree(
          key: _rhythmKey,
          child: LayoutBuilder(
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
        KeyedSubtree(
          key: _recordsKey,
          child: _FocusCheckIn(
            energy: _energy,
            stress: _stress,
            body: _body,
            recorded: _recorded,
            noteController: _noteController,
            savedNote: _savedNote,
            onEnergyChanged: (String value) => setState(() => _energy = value),
            onStressChanged: (String value) => setState(() => _stress = value),
            onBodyChanged: (String value) => setState(() => _body = value),
            onSave: () => setState(() {
              _recorded = true;
              final String note = _noteController.text.trim();
              _savedNote = note.isEmpty ? null : note;
            }),
            onDelete: () => setState(() {
              _recorded = false;
              _savedNote = null;
              _noteController.clear();
            }),
          ),
        ),
        const SizedBox(height: 14),
        _BottomNavigation(
          onToday: () => _scrollTo(_todayKey),
          onRhythm: () => _scrollTo(_rhythmKey),
          onRecords: () => _scrollTo(_recordsKey),
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

class _AdvicePanel extends StatefulWidget {
  const _AdvicePanel({required this.onTap});
  final VoidCallback? onTap;

  @override
  State<_AdvicePanel> createState() => _AdvicePanelState();
}

class _AdvicePanelState extends State<_AdvicePanel> {
  int? _selectedIndex;
  String? _feedback;

  static const List<_AdviceItem> items = <_AdviceItem>[
    _AdviceItem(
      icon: Icons.restaurant_outlined,
      title: '饮食',
      summary: '保持三餐稳定，按口渴感适量补水。',
      action: '先照常吃好下一餐，不因节律术语突然改变饮食。',
      steps: <String>['在熟悉的进餐时间准备容易执行的一餐。', '吃完后留意饥饿、口渴与舒适感，再决定下一次调整。'],
      basis: '依据：已审核的通用生活规律；当前没有饮食记录与健康平台数据。',
    ),
    _AdviceItem(
      icon: Icons.bedtime_outlined,
      title: '睡眠',
      summary: '今晚提前进入安静节奏。',
      action: '比平时稍早结束高刺激活动，为入睡留出稳定缓冲。',
      steps: <String>['睡前降低屏幕亮度，暂停连续信息输入。', '选择一项熟悉的放松活动，困倦时再上床。'],
      basis: '依据：已审核的通用睡眠卫生建议；当前没有睡眠时长与个人基线。',
    ),
    _AdviceItem(
      icon: Icons.directions_walk_outlined,
      title: '活动',
      summary: '安排一段轻松步行。',
      action: '在方便时进行一小段轻松活动，以体感舒适为准。',
      steps: <String>['选择安全、熟悉的路线，从短时间开始。', '过程中能自然交谈即可；不适时停止并休息。'],
      basis: '依据：已审核的通用活动建议；当前没有步数、Readiness 或运动负荷数据。',
    ),
    _AdviceItem(
      icon: Icons.favorite_border_rounded,
      title: '情绪',
      summary: '减少连续信息输入。',
      action: '给自己留一小段不被打扰的时间，先辨认此刻感受。',
      steps: <String>['暂停新的信息输入，做几次自然呼吸。', '用一句话记下当下感受和最需要被照顾的事情。'],
      basis: '依据：已审核的通用自我观察提示；不会据此判断心理或医疗状态。',
    ),
  ];

  @override
  Widget build(BuildContext context) => LifePanel(
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
              const Text('四类建议已合并重复内容。点击一项查看具体做法。',
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              _PriorityAction(onTap: widget.onTap),
              const SizedBox(height: 12),
              LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                final double width = (constraints.maxWidth - 8) / 2;
                return Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
                  for (int index = 0; index < items.length; index++)
                    _AdviceTile(
                        width: width,
                        icon: items[index].icon,
                        title: items[index].title,
                        copy: items[index].summary,
                        selected: _selectedIndex == index,
                        onTap: () => setState(() {
                              _selectedIndex =
                                  _selectedIndex == index ? null : index;
                              _feedback = null;
                            })),
                ]);
              }),
              if (_selectedIndex != null) ...<Widget>[
                const SizedBox(height: 12),
                _AdviceDetail(
                  item: items[_selectedIndex!],
                  feedback: _feedback,
                  onFeedback: (String value) =>
                      setState(() => _feedback = value),
                  onReset: () => setState(() => _feedback = null),
                ),
              ],
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

class _AdviceItem {
  const _AdviceItem({
    required this.icon,
    required this.title,
    required this.summary,
    required this.action,
    required this.steps,
    required this.basis,
  });
  final IconData icon;
  final String title;
  final String summary;
  final String action;
  final List<String> steps;
  final String basis;
}

class _PriorityAction extends StatelessWidget {
  const _PriorityAction({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return Material(
      color: t.accentSoft.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome_rounded, color: t.accent),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('AI 今日优先行动', style: TextStyle(fontSize: 10)),
                    SizedBox(height: 3),
                    Text('唯一主任务已在上方综合分析中',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Icon(Icons.arrow_upward_rounded, color: t.accent),
            ]),
          ),
        ),
      ),
    );
  }
}

class _AdviceDetail extends StatelessWidget {
  const _AdviceDetail({
    required this.item,
    required this.feedback,
    required this.onFeedback,
    required this.onReset,
  });
  final _AdviceItem item;
  final String? feedback;
  final ValueChanged<String> onFeedback;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return Container(
      key: const Key('vitality-advice-detail'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.outline),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              color: t.accentSoft.withValues(alpha: .42),
              padding: const EdgeInsets.all(13),
              child: Row(children: <Widget>[
                Icon(item.icon, color: t.accent),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('${item.title} · 今日补充建议',
                          style: const TextStyle(fontSize: 10)),
                      const SizedBox(height: 2),
                      Text(item.summary,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const Text('辅助建议', style: TextStyle(fontSize: 10)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('建议怎么做',
                        style: TextStyle(color: t.textSecondary, fontSize: 10)),
                    const SizedBox(height: 5),
                    Text(item.action,
                        style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    for (int index = 0; index < item.steps.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: 23,
                                height: 23,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: t.accentSoft,
                                  shape: BoxShape.circle,
                                ),
                                child: Text('${index + 1}',
                                    style: TextStyle(
                                        color: t.accent, fontSize: 10)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(item.steps[index],
                                      style: const TextStyle(
                                          fontSize: 11, height: 1.5))),
                            ]),
                      ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: t.backgroundBottom.withValues(alpha: .65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(item.basis,
                          style: TextStyle(
                              color: t.textSecondary,
                              fontSize: 10,
                              height: 1.5)),
                    ),
                    const SizedBox(height: 12),
                    if (feedback == null)
                      Wrap(spacing: 6, runSpacing: 6, children: <Widget>[
                        _FeedbackButton(
                            label: '完成', onTap: () => onFeedback('已标记完成')),
                        _FeedbackButton(
                            label: '跳过', onTap: () => onFeedback('今天已跳过')),
                        _FeedbackButton(
                            label: '调整', onTap: () => onFeedback('已记录调整需求')),
                        _FeedbackButton(
                            label: '换一个',
                            onTap: () => onFeedback('替换功能待服务端接入')),
                      ])
                    else
                      Row(children: <Widget>[
                        Icon(Icons.check_circle_outline_rounded,
                            color: t.accent, size: 18),
                        const SizedBox(width: 7),
                        Expanded(
                            child: Text('$feedback · 仅保存在当前页面，不影响生命参考分。',
                                style: const TextStyle(fontSize: 11))),
                        TextButton(
                            onPressed: onReset, child: const Text('重新选择')),
                      ]),
                  ]),
            ),
          ]),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(minimumSize: const Size(64, 44)),
        child: Text(label),
      );
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
      required this.copy,
      required this.selected,
      required this.onTap});
  final double width;
  final IconData icon;
  final String title;
  final String copy;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return Material(
      color:
          selected ? t.accentSoft.withValues(alpha: .42) : Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: selected ? t.accent : t.outline),
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: width,
          constraints: const BoxConstraints(minHeight: 124),
          padding: const EdgeInsets.all(12),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(children: <Widget>[
                  Icon(icon, color: t.accent),
                  const Spacer(),
                  Text(selected ? '收起' : '查看',
                      style: TextStyle(color: t.accent, fontSize: 10)),
                ]),
                const SizedBox(height: 9),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(copy,
                    style: TextStyle(
                        color: t.textSecondary, fontSize: 12, height: 1.4)),
              ]),
        ),
      ),
    );
  }
}

class _FocusCheckIn extends StatelessWidget {
  const _FocusCheckIn(
      {required this.energy,
      required this.stress,
      required this.body,
      required this.recorded,
      required this.noteController,
      required this.savedNote,
      required this.onEnergyChanged,
      required this.onStressChanged,
      required this.onBodyChanged,
      required this.onSave,
      required this.onDelete});
  final String energy;
  final String stress;
  final String body;
  final bool recorded;
  final TextEditingController noteController;
  final String? savedNote;
  final ValueChanged<String> onEnergyChanged;
  final ValueChanged<String> onStressChanged;
  final ValueChanged<String> onBodyChanged;
  final VoidCallback onSave;
  final VoidCallback onDelete;

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
            const SizedBox(height: 7),
            Text('来源：健康平台尚未授权 · 不使用示例数值',
                style: TextStyle(color: t.textSecondary, fontSize: 10)),
            const SizedBox(height: 14),
            const Text('现在感觉怎么样？',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('由你主动记录 · 不会自动生成诊断',
                style: TextStyle(color: t.textSecondary, fontSize: 10)),
            const SizedBox(height: 12),
            _StateChoiceGroup(
              label: '精力',
              value: energy,
              options: const <String>['偏低', '一般', '充足'],
              onChanged: onEnergyChanged,
            ),
            const SizedBox(height: 12),
            _StateChoiceGroup(
              label: '压力感受',
              value: stress,
              options: const <String>['轻松', '一般', '较高'],
              onChanged: onStressChanged,
            ),
            const SizedBox(height: 12),
            _StateChoiceGroup(
              label: '身体感受',
              value: body,
              options: const <String>['舒适', '有点疲惫', '明显不适'],
              onChanged: onBodyChanged,
            ),
            if (body == '明显不适') ...<Widget>[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1E8),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.info_outline_rounded,
                        color: Color(0xFF956046), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '如果不适明显、持续或影响日常生活，建议联系合格的专业人士。本应用不提供医疗诊断。',
                        style: TextStyle(fontSize: 11, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Text('今天有什么值得记下？（选填）',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            TextField(
              controller: noteController,
              maxLength: 120,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '例如：午后有些疲惫，散步后感觉轻松一些',
                border: OutlineInputBorder(),
              ),
            ),
            Row(children: <Widget>[
              Icon(Icons.lock_outline_rounded,
                  color: t.textSecondary, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text('当前仅保存在页面内，可编辑或删除',
                    style: TextStyle(color: t.textSecondary, fontSize: 10)),
              ),
            ]),
            const SizedBox(height: 10),
            SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: onSave,
                    child: Text(recorded ? '更新今日记录' : '记录此刻状态'))),
            if (recorded) ...<Widget>[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('删除这条主观记录'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Divider(height: 1, color: t.outline),
            const SizedBox(height: 10),
            Row(children: <Widget>[
              const Expanded(
                child: Text('今日记录',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              Text('时间线',
                  style: TextStyle(color: t.textSecondary, fontSize: 10)),
            ]),
            const SizedBox(height: 7),
            const _TimelineRow(
              time: '09:12',
              title: '今日通用建议已生成',
              detail: '系统事件 · 未使用健康平台数据',
            ),
            if (recorded)
              _TimelineRow(
                time: '刚刚',
                title: '完成状态记录',
                detail: savedNote ?? '精力$energy · 压力$stress · 身体$body',
                actionLabel: '编辑记录',
              ),
            const SizedBox(height: 7),
            Text('本次记录不会修改已经生成的生命参考分。',
                style: TextStyle(color: t.textSecondary, fontSize: 11)),
          ]),
    );
  }
}

class _StateChoiceGroup extends StatelessWidget {
  const _StateChoiceGroup({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 7),
        Row(
          children: <Widget>[
            for (int index = 0; index < options.length; index++) ...<Widget>[
              if (index > 0) const SizedBox(width: 7),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onChanged(options[index]),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    backgroundColor:
                        value == options[index] ? t.accentSoft : null,
                    side: BorderSide(
                        color: value == options[index] ? t.accent : t.outline),
                  ),
                  child: Text(options[index],
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ],
        ),
      ],
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
  const _TimelineRow({
    required this.time,
    required this.title,
    required this.detail,
    this.actionLabel,
  });
  final String time;
  final String title;
  final String detail;
  final String? actionLabel;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                  width: 40,
                  child: Text(time, style: const TextStyle(fontSize: 10))),
              const Icon(Icons.circle, size: 9, color: Color(0xFF8DBCA0)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(detail,
                        style: const TextStyle(fontSize: 10, height: 1.4)),
                    if (actionLabel != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(actionLabel!,
                          style: const TextStyle(
                              color: Color(0xFF2E7252), fontSize: 10)),
                    ],
                  ],
                ),
              ),
            ]),
      );
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.onToday,
    required this.onRhythm,
    required this.onRecords,
    required this.onAccount,
  });
  final VoidCallback onToday;
  final VoidCallback onRhythm;
  final VoidCallback onRecords;
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) => LifePanel(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(children: <Widget>[
          Expanded(
              child: _NavItem(
                  key: const Key('vitality-nav-today'),
                  icon: Icons.home_outlined,
                  label: '今日',
                  active: true,
                  onTap: onToday)),
          Expanded(
              child: _NavItem(
                  key: const Key('vitality-nav-rhythm'),
                  icon: Icons.blur_circular,
                  label: '节律',
                  onTap: onRhythm)),
          Expanded(
              child: _NavItem(
                  key: const Key('vitality-nav-records'),
                  icon: Icons.edit_note_outlined,
                  label: '记录',
                  onTap: onRecords)),
          Expanded(
              child: _NavItem(
                  key: const Key('vitality-nav-account'),
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
      this.onTap,
      super.key});
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
