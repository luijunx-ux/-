import 'package:flutter/material.dart';
import 'package:tianrenlu/core/life_theme.dart';
import 'package:tianrenlu/features/profile/domain/profile_models.dart';

class VitalityYunqiDetailPage extends StatelessWidget {
  const VitalityYunqiDetailPage({
    required this.profile,
    required this.birthInput,
    super.key,
  });

  final LifeProfile profile;
  final BirthInput birthInput;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    final WuyunLiuqiInfo rhythm = profile.wuyunLiuqi;
    return Scaffold(
      backgroundColor: t.backgroundBottom,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(child: _YunqiHeader(rhythm: rhythm)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList.list(
              children: <Widget>[
                const _ReviewNotice(),
                const SizedBox(height: 20),
                const _SectionTitle('专业术语与通俗解释'),
                const SizedBox(height: 10),
                _TranslationTable(rhythm: rhythm),
                if (rhythm.boundaryWarning != null) ...<Widget>[
                  const SizedBox(height: 10),
                  _BoundaryNotice(text: rhythm.boundaryWarning!),
                ],
                const SizedBox(height: 20),
                const _SectionTitle('节气与环境背景'),
                const SizedBox(height: 10),
                _ContextPanel(birthInput: birthInput),
                const SizedBox(height: 20),
                const _SectionTitle('今天的生活建议'),
                const SizedBox(height: 4),
                Text(
                  '以下为已审核的通用生活方式提示，不由五运六气术语直接推导。',
                  style: TextStyle(color: t.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 10),
                const _AdviceList(),
                const SizedBox(height: 12),
                _BasisButton(rhythm: rhythm),
                const SizedBox(height: 14),
                Text(
                  profile.disclaimer,
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

class _YunqiHeader extends StatelessWidget {
  const _YunqiHeader({required this.rhythm});
  final WuyunLiuqiInfo rhythm;

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
              Color(0xFF19493C),
              Color(0xFF3C7860),
              Color(0xFF8DA681),
            ],
          ),
        ),
        child: Column(
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
                    '五运六气',
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
              '今日天地节律解读',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              '先看真实规则结果，再按需要了解专业术语、环境背景与生活建议。',
              style: TextStyle(color: Colors.white70, height: 1.55),
            ),
            const SizedBox(height: 13),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: <Widget>[
                const _HeaderChip(label: '确定性引擎结果'),
                _HeaderChip(
                    label: '${rhythm.heavenlyStem}${rhythm.earthlyBranch}年'),
                _HeaderChip(label: rhythm.algorithmVersion),
              ],
            ),
          ],
        ),
      );
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
          color: const Color(0xFFFFF4E8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.info_outline_rounded,
                color: Color(0xFF9A6848), size: 18),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                '当前仅展示规则引擎已经返回的结构化结果。术语解释属于文化背景说明，后续仍需专家与黄金测试集持续审核。',
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
  const _TranslationTable({required this.rhythm});
  final WuyunLiuqiInfo rhythm;

  @override
  Widget build(BuildContext context) {
    final List<(String, String, String)> rows = <(String, String, String)>[
      (
        '年度干支',
        '${rhythm.heavenlyStem}${rhythm.earthlyBranch}',
        '先把它当作年度节律的“坐标”。查看其他术语时用它确认所处年份，不用它判断个人命运或健康好坏。'
      ),
      (
        '中运',
        '${rhythm.middleMovement} · ${rhythm.movementStrength}',
        '可理解为这一年的时令观察主线。日常仍以真实季节、天气和身体感受安排作息，不因“太过”等词自行进补或减量。'
      ),
      (
        '司天',
        rhythm.governingQi,
        '主要帮助理解上半年在传统体系中的气候背景。使用时要结合当前日期和真实天气，不能单凭这一项安排饮食或运动。'
      ),
      (
        '在泉',
        rhythm.respondingQi,
        '主要帮助理解下半年在传统体系中的气候背景。它是观察线索，不是身体状况、疾病风险或未来事件的结论。'
      ),
      (
        '算法版本',
        rhythm.algorithmVersion,
        '这是结果的“计算说明书编号”。结果出现变化时，可用它核对是否因为规则升级，便于追溯而不是用于生活判断。'
      ),
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
            color: const Color(0xFFE8F3ED),
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: const Row(
              children: <Widget>[
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 11),
                    child: Text('专业术语与结果',
                        style: TextStyle(
                            color: Color(0xFF33604D),
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
                            color: Color(0xFF33604D),
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
                                  color: Color(0xFF2D5F49),
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

class _BoundaryNotice extends StatelessWidget {
  const _BoundaryNotice({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => _Panel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.schedule_outlined, size: 20),
            const SizedBox(width: 9),
            Expanded(child: Text(text, style: const TextStyle(height: 1.5))),
          ],
        ),
      );
}

class _ContextPanel extends StatelessWidget {
  const _ContextPanel({required this.birthInput});
  final BirthInput birthInput;

  @override
  Widget build(BuildContext context) => _Panel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          children: <Widget>[
            const _ContextRow(label: '当前节气', value: '当前接口尚未提供'),
            _ContextRow(
              label: '档案出生地',
              value: birthInput.placeName,
            ),
            _ContextRow(label: '档案时区', value: birthInput.timezone),
            const _ContextRow(label: '当前地点', value: '尚未获得定位授权'),
            const _ContextRow(label: '天气 / 空气', value: '数据暂不可用'),
            const _ContextRow(
              label: '与生命参考分关系',
              value: '仅作解释背景，不参与加减分',
              last: true,
            ),
          ],
        ),
      );
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({
    required this.label,
    required this.value,
    this.last = false,
  });
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFE6ECE8))),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 4,
              child: Text(label,
                  style:
                      const TextStyle(color: Color(0xFF6B7D74), fontSize: 11)),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: Text(value,
                  textAlign: TextAlign.right,
                  style:
                      const TextStyle(color: Color(0xFF284D3E), fontSize: 11)),
            ),
          ],
        ),
      );
}

class _AdviceList extends StatelessWidget {
  const _AdviceList();
  static const List<(IconData, String, String)> items =
      <(IconData, String, String)>[
    (Icons.restaurant_outlined, '饮食', '保持日常进餐节奏，按真实天气与个人感受选择容易执行的搭配。'),
    (Icons.bedtime_outlined, '睡眠', '晚间预留安静过渡时间；没有睡眠数据时不做个性化判断。'),
    (Icons.directions_walk_outlined, '活动', '以轻松、循序的活动为主，不把传统术语当作运动处方。'),
    (Icons.favorite_border_rounded, '情绪', '给自己留出短暂整理与呼吸的空间，避免绝对化预测影响感受。'),
  ];

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          for (int index = 0; index < items.length; index++)
            Padding(
              padding:
                  EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 8),
              child: _AdviceRow(item: items[index]),
            ),
        ],
      );
}

class _AdviceRow extends StatelessWidget {
  const _AdviceRow({required this.item});
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
                color: const Color(0xFFE5F1E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.$1, color: const Color(0xFF21674D), size: 20),
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
  const _BasisButton({required this.rhythm});
  final WuyunLiuqiInfo rhythm;

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
                  Text('计算依据与来源',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Text('规则版本：${rhythm.algorithmVersion}'),
                  const SizedBox(height: 7),
                  const Text('输入类别：档案出生时间、出生地点与时区'),
                  const SizedBox(height: 7),
                  const Text('计算方式：确定性规则引擎；LLM 不参与历法与五运六气计算'),
                  const SizedBox(height: 7),
                  const Text('当前未使用：实时天气、空气质量、健康平台数据'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('我知道了'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        child: const Text('查看计算依据、来源与缺失数据'),
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
