import 'package:flutter/material.dart';
import 'package:tianrenlu/core/life_theme.dart';
import 'package:tianrenlu/features/profile/domain/profile_models.dart';

class VitalityStellarDetailPage extends StatelessWidget {
  const VitalityStellarDetailPage({
    required this.profile,
    required this.birthInput,
    super.key,
  });

  final LifeProfile profile;
  final BirthInput birthInput;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return Scaffold(
      backgroundColor: t.backgroundBottom,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(child: _StellarHeader(zodiac: profile.zodiac)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList.list(
              children: <Widget>[
                const _ReviewNotice(),
                const SizedBox(height: 20),
                const _SectionTitle('专业术语与通俗解释'),
                const SizedBox(height: 10),
                _TranslationTable(zodiac: profile.zodiac),
                const SizedBox(height: 20),
                const _SectionTitle('今天可以观察什么'),
                const SizedBox(height: 10),
                const _ReflectionPanel(),
                const SizedBox(height: 20),
                const _SectionTitle('今天的生活提示'),
                const SizedBox(height: 4),
                Text(
                  '以下是开放式自我观察，不是由星座推导出的健康判断或事件预测。',
                  style: TextStyle(color: t.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 10),
                const _ObservationList(),
                const SizedBox(height: 12),
                _BasisButton(zodiac: profile.zodiac, birthInput: birthInput),
                const SizedBox(height: 14),
                Text(
                  '文化与自我观察参考 · 非命运预测 · 非医疗诊断 · 不参与生命参考分',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: t.textSecondary,
                    fontSize: 10,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StellarHeader extends StatelessWidget {
  const _StellarHeader({required this.zodiac});
  final ZodiacInfo zodiac;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(
          12,
          MediaQuery.paddingOf(context).top + 8,
          16,
          24,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF303458),
              Color(0xFF615D8F),
              Color(0xFF9A89A9),
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: IgnorePointer(child: _StarField())),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton.filledTonal(
                      tooltip: '返回',
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        '星辰节律',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  '今日自我观察提示',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  '了解太阳星座的文化含义，把它转化为温和、开放的日常反思。',
                  style: TextStyle(color: Colors.white70, height: 1.55),
                ),
                const SizedBox(height: 13),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: <Widget>[
                    _HeaderChip(label: '太阳星座 · ${zodiac.sign}'),
                    _HeaderChip(label: '元素 · ${zodiac.element}'),
                    _HeaderChip(label: '模式 · ${zodiac.modality}'),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
}

class _StarField extends StatelessWidget {
  const _StarField();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _StarPainter());
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint glow = Paint()
      ..shader = const RadialGradient(
        colors: <Color>[Color(0xFFFFAF73), Color(0x00FFAF73)],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * .84, size.height * .18),
        radius: 76,
      ));
    canvas.drawCircle(Offset(size.width * .84, size.height * .18), 76, glow);
    final Paint orbit = Paint()
      ..color = const Color(0x55FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .78, size.height * .58),
        width: 180,
        height: 86,
      ),
      orbit,
    );
    final Paint star = Paint()..color = const Color(0xAAFFFFFF);
    for (final Offset point in const <Offset>[
      Offset(.12, .34),
      Offset(.34, .16),
      Offset(.52, .43),
      Offset(.70, .25),
      Offset(.88, .48),
    ]) {
      canvas.drawCircle(
          Offset(size.width * point.dx, size.height * point.dy), 1.4, star);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          border: Border.all(color: Colors.white30),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 10)),
      );
}

class _ReviewNotice extends StatelessWidget {
  const _ReviewNotice();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1E8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.info_outline_rounded,
                color: Color(0xFF956046), size: 18),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'MVP 仅展示太阳星座；月亮与上升星座暂不推测。这里不提供桃花、财富、吉凶或具体事件预测。',
                style: TextStyle(fontSize: 11, height: 1.55),
              ),
            ),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w800),
      );
}

class _TranslationTable extends StatelessWidget {
  const _TranslationTable({required this.zodiac});
  final ZodiacInfo zodiac;

  @override
  Widget build(BuildContext context) {
    final List<(String, String, String)> rows = <(String, String, String)>[
      ('太阳星座', zodiac.sign, '根据出生日期得到的文化分类，可作为自我提问的入口；它不是完整人格、健康状况或命运结论。'),
      ('元素分类', zodiac.element, '一种传统象征语言。可以观察自己通常怎样表达精力与注意力，但不用于判断能力高低或身体状态。'),
      ('模式分类', zodiac.modality, '可用来反思自己面对事情时更常启动、维持还是调整；它不是固定标签，也不能替代真实行为。'),
      ('月亮星座', '未来能力 · 当前不推测', '通常需要更完整的出生信息和可靠计算；当前接口没有结果，所以页面不补造解释。'),
      ('上升星座', '未来能力 · 当前不推测', '通常依赖准确出生时间、地点与天文计算；在规则引擎接入并验证前不显示结论。'),
    ];
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.outline),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: <Widget>[
          Container(
            color: const Color(0xFFEEEAF6),
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: const Row(
              children: <Widget>[
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 11),
                    child: Text('专业术语与结果',
                        style: TextStyle(
                            color: Color(0xFF5B5481),
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 11),
                    child: Text('普通人怎么理解与使用',
                        style: TextStyle(
                            color: Color(0xFF5B5481),
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          for (int index = 0; index < rows.length; index++) ...<Widget>[
            if (index > 0) Divider(height: 1, color: t.outline),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(11),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(rows[index].$1,
                              style: const TextStyle(
                                  color: Color(0xFF5B5481),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 5),
                          Text(rows[index].$2,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  VerticalDivider(width: 1, color: t.outline),
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(11),
                      child: Text(rows[index].$3,
                          style: const TextStyle(fontSize: 11, height: 1.55)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReflectionPanel extends StatelessWidget {
  const _ReflectionPanel();
  @override
  Widget build(BuildContext context) => const _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('节奏与边界',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            SizedBox(height: 7),
            Text(
              '当事情变多时，你能否分清“真正重要”和“只是急迫”？可以先留出一小段不被打扰的时间，再决定下一步。',
              style: TextStyle(fontSize: 11, height: 1.6),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: <Widget>[
                _Tag('专注'),
                _Tag('沟通'),
                _Tag('恢复'),
                _Tag('非预测'),
              ],
            ),
          ],
        ),
      );
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
            color: const Color(0xFFF0EDF7),
            borderRadius: BorderRadius.circular(99)),
        child: Text(label,
            style: const TextStyle(color: Color(0xFF625A88), fontSize: 10)),
      );
}

class _ObservationList extends StatelessWidget {
  const _ObservationList();
  static const List<(IconData, String, String)> items =
      <(IconData, String, String)>[
    (Icons.checklist_rounded, '专注', '先选一件最重要的小事完成，再决定是否增加任务，减少被大量信息牵引。'),
    (Icons.forum_outlined, '沟通', '表达需求时尽量具体，也给对方回应空间；用实际交流修正自己的预设。'),
    (Icons.favorite_border_rounded, '情绪', '把星座提示当作问题而不是结论，真实感受仍以你当下的反馈为准。'),
    (Icons.bedtime_outlined, '休息', '晚间减少持续的信息输入，为睡前放松预留一段稳定的过渡时间。'),
  ];

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          for (int index = 0; index < items.length; index++)
            Padding(
              padding:
                  EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 8),
              child: _ObservationRow(item: items[index]),
            ),
        ],
      );
}

class _ObservationRow extends StatelessWidget {
  const _ObservationRow({required this.item});
  final (IconData, String, String) item;
  @override
  Widget build(BuildContext context) => _Panel(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: const Color(0xFFEEEAF6),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(item.$1, color: const Color(0xFF61598B), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(item.$2,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(item.$3,
                      style: const TextStyle(fontSize: 11, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _BasisButton extends StatelessWidget {
  const _BasisButton({required this.zodiac, required this.birthInput});
  final ZodiacInfo zodiac;
  final BirthInput birthInput;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (BuildContext context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('计算依据与资料边界',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Text('当前结果：太阳星座 ${zodiac.sign}'),
                  const SizedBox(height: 7),
                  Text('输入依据：档案出生日期 · ${birthInput.timezone}'),
                  const SizedBox(height: 7),
                  const Text('计算方式：确定性规则；LLM 不参与星座结果计算'),
                  const SizedBox(height: 7),
                  const Text('当前缺失：月亮星座、上升星座与完整星盘结果'),
                  const SizedBox(height: 7),
                  const Text('生命参考分：星辰节律仅作解释背景，不参与加减分'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('我知道了')),
                  ),
                ],
              ),
            ),
          ),
        ),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        child: const Text('查看计算依据、资料边界与缺失数据'),
      );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(14)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.outline),
        borderRadius: BorderRadius.circular(17),
      ),
      child: child,
    );
  }
}
