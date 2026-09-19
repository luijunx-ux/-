import 'package:flutter/material.dart';
import 'package:tianrenlu/core/life_theme.dart';
import 'package:tianrenlu/features/profile/data/profile_api_client.dart';
import 'package:tianrenlu/features/profile/domain/profile_models.dart';

class VitalityAiAnalysisPage extends StatefulWidget {
  const VitalityAiAnalysisPage({
    required this.apiClient,
    required this.birthInput,
    this.profileId,
    super.key,
  });

  final ProfileApiClient apiClient;
  final BirthInput birthInput;
  final String? profileId;

  @override
  State<VitalityAiAnalysisPage> createState() => _VitalityAiAnalysisPageState();
}

class _VitalityAiAnalysisPageState extends State<VitalityAiAnalysisPage> {
  DailyAdvice? _advice;
  String? _error;
  bool _loading = true;
  bool _explanationOpen = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final DateTime now = DateTime.now();
      final DailyAdvice advice = await widget.apiClient.getDailyAdvice(
        widget.birthInput,
        DateTime(now.year, now.month, now.day),
        profileId: widget.profileId,
      );
      if (mounted) setState(() => _advice = advice);
    } on ProfileApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendFeedback(bool helpful) async {
    final String? adviceId = _advice?.id;
    if (adviceId == null) {
      _notice('当前建议尚未生成可反馈记录。');
      return;
    }
    try {
      final DailyAdvice updated = await widget.apiClient.submitAdviceFeedback(
        adviceId,
        helpful: helpful,
      );
      if (mounted) setState(() => _advice = updated);
    } on ProfileApiException catch (error) {
      _notice(error.message);
    }
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showQuestionPreview([String? question]) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('问问天人律',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              if (question != null) ...<Widget>[
                Text(question,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
              ],
              const Text(
                '连续问答能力将在完成来源引用、隐私与安全审核后接入。当前页面不会上传新的健康信息，也不会把问题作为生命参考分输入。',
                style: TextStyle(height: 1.55),
              ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return Scaffold(
      backgroundColor: t.backgroundBottom,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(child: _AnalysisHeader(loading: _loading)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList.list(
                children: <Widget>[
                  Transform.translate(
                    offset: const Offset(0, -18),
                    child: _buildBody(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const _Panel(
        child: SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_error != null) {
      return _Panel(
        child: Column(
          children: <Widget>[
            const Icon(Icons.cloud_off_outlined, size: 34),
            const SizedBox(height: 10),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('重新加载')),
          ],
        ),
      );
    }
    final DailyAdvice advice = _advice!;
    final String priority =
        advice.items.isEmpty ? '今天先保持基础作息，并按自己的感受安排活动。' : advice.items.first;
    final List<String> supporting = advice.items.skip(1).take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SummaryCard(advice: advice, priority: priority),
        const SizedBox(height: 20),
        const _SectionHeading(title: '主要依据', note: '不使用未授权健康数据'),
        const SizedBox(height: 10),
        _EvidencePanel(advice: advice),
        const SizedBox(height: 20),
        const _SectionHeading(title: '今日优先行动', note: '只做一件最重要的事'),
        const SizedBox(height: 10),
        _PriorityAction(text: priority),
        const SizedBox(height: 10),
        _ExplanationPanel(
          open: _explanationOpen,
          supporting: supporting,
          onTap: () => setState(() => _explanationOpen = !_explanationOpen),
        ),
        const SizedBox(height: 20),
        const _SectionHeading(title: '问问天人律', note: '围绕今天继续了解'),
        const SizedBox(height: 10),
        for (final String question in const <String>[
          '今天为什么建议先稳定节奏？',
          '今天适合安排什么活动？',
          '怎样准备今晚的休息？',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _QuestionButton(
              label: question,
              onTap: () => _showQuestionPreview(question),
            ),
          ),
        FilledButton.icon(
          onPressed: _showQuestionPreview,
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: const Text('输入自己的问题'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        ),
        const SizedBox(height: 16),
        _Footer(
          advice: advice,
          onHelpful: () => _sendFeedback(true),
          onNotHelpful: () => _sendFeedback(false),
        ),
      ],
    );
  }
}

class _AnalysisHeader extends StatelessWidget {
  const _AnalysisHeader({required this.loading});
  final bool loading;

  @override
  Widget build(BuildContext context) => Container(
        height: 280,
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + 8,
          left: 12,
          right: 12,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF173F36),
              Color(0xFF2B6655),
              Color(0xFF78947E)
            ],
          ),
        ),
        child: Column(
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
                    '今日综合分析',
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
            const _LifeOrb(),
            const SizedBox(height: 12),
            Text(
              loading ? '正在整理结构化结果…' : '已生成 · 数据来源与边界可查看',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      );
}

class _LifeOrb extends StatelessWidget {
  const _LifeOrb();

  @override
  Widget build(BuildContext context) => Semantics(
        label: '天人律生命球',
        image: true,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-.38, -.48),
              colors: <Color>[
                Color(0xFFFFEAC0),
                Color(0xFFEF9B72),
                Color(0xFF8EA7CC),
                Color(0xFF3C6E69),
                Color(0xFF193F38),
              ],
              stops: <double>[0, .18, .43, .72, 1],
            ),
            border: Border.all(color: Colors.white54),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x66FBB881), blurRadius: 30),
            ],
          ),
        ),
      );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.advice, required this.priority});
  final DailyAdvice advice;
  final String priority;

  @override
  Widget build(BuildContext context) => _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('今日核心判断',
                style: TextStyle(color: Color(0xFF2B7257), fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              '先照顾好基础节律，\n再根据感受逐步行动',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Text(priority, style: const TextStyle(height: 1.55)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: <Widget>[
                const _StatusChip(label: '生命参考分：数据不足'),
                _StatusChip(label: _modeLabel(advice.generationMode)),
                const _StatusChip(label: '未接入健康平台'),
              ],
            ),
          ],
        ),
      );

  static String _modeLabel(String mode) => switch (mode) {
        'llm' => 'AI 解释已生成',
        'fallback' => '基础建议',
        'safety_fallback' => '安全基础建议',
        _ => '确定性节律建议',
      };
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF4EE),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label,
            style: const TextStyle(color: Color(0xFF38634F), fontSize: 10)),
      );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.note});
  final String title;
  final String note;
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
          Text(note,
              style: TextStyle(
                color: Theme.of(context)
                    .extension<LifeThemeTokens>()!
                    .textSecondary,
                fontSize: 10,
              )),
        ],
      );
}

class _EvidencePanel extends StatelessWidget {
  const _EvidencePanel({required this.advice});
  final DailyAdvice advice;

  @override
  Widget build(BuildContext context) {
    final List<(IconData, String, String, String)> evidence =
        <(IconData, String, String, String)>[
      (Icons.account_circle_outlined, '个人生命档案', '已参与', '用于读取出生信息与确定性节律结果'),
      (Icons.rule_outlined, '节律规则结果', '已参与', '由规则引擎计算，LLM 不参与计算'),
      (
        Icons.health_and_safety_outlined,
        '健康与设备数据',
        '尚未授权',
        '睡眠、步数与 Readiness 未进入本次分析'
      ),
    ];
    return _Panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (int index = 0; index < evidence.length; index++) ...<Widget>[
            _EvidenceRow(item: evidence[index]),
            if (index != evidence.length - 1) const Divider(height: 1),
          ],
          if (advice.knowledgeSources.isNotEmpty) ...<Widget>[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '参考知识：${advice.knowledgeSources.join('、')}',
                  style: const TextStyle(fontSize: 11, height: 1.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({required this.item});
  final (IconData, String, String, String) item;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE2F1E8),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(item.$1, color: const Color(0xFF226D50)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(item.$2,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(item.$4,
                      style: const TextStyle(fontSize: 11, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(item.$3,
                style: const TextStyle(color: Color(0xFF527064), fontSize: 10)),
          ],
        ),
      );
}

class _PriorityAction extends StatelessWidget {
  const _PriorityAction({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFE2F1E8), Color(0xFFFFF1E6)],
          ),
          border: Border.all(color: const Color(0xFFD4E4D8)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFF256B50), size: 18),
                SizedBox(width: 7),
                Text('温和行动 · 可自行调整',
                    style: TextStyle(
                        color: Color(0xFF256B50), fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            Text(text,
                style: const TextStyle(
                    fontSize: 16, height: 1.55, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('以舒适感受为准，不必追求完成度；持续不适时请咨询合格专业人员。',
                style: TextStyle(fontSize: 10, height: 1.5)),
          ],
        ),
      );
}

class _ExplanationPanel extends StatelessWidget {
  const _ExplanationPanel({
    required this.open,
    required this.supporting,
    required this.onTap,
  });
  final bool open;
  final List<String> supporting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _Panel(
        padding: EdgeInsets.zero,
        child: Column(
          children: <Widget>[
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 54),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: <Widget>[
                      const Expanded(child: Text('为什么这样建议？')),
                      Icon(open
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded),
                    ],
                  ),
                ),
              ),
            ),
            if (open)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Text(
                  supporting.isEmpty
                      ? '当前建议来自结构化节律结果与已审核的通用生活建议。健康平台数据尚未授权，因此没有推测睡眠、活动或恢复情况。'
                      : supporting.join('\n'),
                  style: const TextStyle(fontSize: 11, height: 1.6),
                ),
              ),
          ],
        ),
      );
}

class _QuestionButton extends StatelessWidget {
  const _QuestionButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            const Icon(Icons.north_east_rounded, size: 17),
          ],
        ),
      );
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.advice,
    required this.onHelpful,
    required this.onNotHelpful,
  });
  final DailyAdvice advice;
  final VoidCallback onHelpful;
  final VoidCallback onNotHelpful;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(advice.disclaimer,
              style: const TextStyle(fontSize: 10, height: 1.5)),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Expanded(
                child: Text('生活方式参考 · 非医疗诊断', style: TextStyle(fontSize: 10)),
              ),
              TextButton.icon(
                onPressed: onHelpful,
                icon: Icon(advice.helpful == true
                    ? Icons.thumb_up_rounded
                    : Icons.thumb_up_outlined),
                label: const Text('有帮助'),
              ),
              TextButton.icon(
                onPressed: onNotHelpful,
                icon: Icon(advice.helpful == false
                    ? Icons.thumb_down_rounded
                    : Icons.thumb_down_outlined),
                label: const Text('不适合我'),
              ),
            ],
          ),
        ],
      );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(17)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: t.outline),
        boxShadow: <BoxShadow>[
          BoxShadow(color: t.accent.withValues(alpha: .07), blurRadius: 18),
        ],
      ),
      child: child,
    );
  }
}
