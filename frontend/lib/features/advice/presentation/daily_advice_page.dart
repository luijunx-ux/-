import 'package:flutter/material.dart';
import 'package:tianrenlu/core/life_theme.dart';
import 'package:tianrenlu/features/profile/data/profile_api_client.dart';
import 'package:tianrenlu/features/profile/domain/profile_models.dart';

class DailyAdvicePage extends StatefulWidget {
  const DailyAdvicePage({
    required this.apiClient,
    required this.birthInput,
    this.profileId,
    super.key,
  });

  final ProfileApiClient apiClient;
  final BirthInput birthInput;
  final String? profileId;

  @override
  State<DailyAdvicePage> createState() => _DailyAdvicePageState();
}

class _DailyAdvicePageState extends State<DailyAdvicePage> {
  late DateTime _selectedDate;
  DailyAdvice? _advice;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _loadAdvice();
  }

  Future<void> _chooseDate() async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (selected == null) {
      return;
    }
    setState(() => _selectedDate = selected);
    await _loadAdvice();
  }

  Future<void> _loadAdvice() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final DailyAdvice advice = await widget.apiClient.getDailyAdvice(
        widget.birthInput,
        _selectedDate,
        profileId: widget.profileId,
      );
      if (mounted) {
        setState(() => _advice = advice);
      }
    } on ProfileApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String get _dateLabel =>
      '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日';

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('AI 生命建议'),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent),
      body: DecoratedBox(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[t.backgroundTop, t.backgroundBottom])),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadAdvice,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              children: <Widget>[
                _AdviceHero(
                    dateLabel: _dateLabel,
                    loading: _loading,
                    onChooseDate: _chooseDate),
                const SizedBox(height: 20),
                if (_loading)
                  const _LoadingAdvice()
                else if (_error != null)
                  _ErrorCard(message: _error!, onRetry: _loadAdvice)
                else if (_advice != null) ...<Widget>[
                  _GenerationCard(advice: _advice!),
                  const SizedBox(height: 18),
                  Text('今天可以这样照顾自己',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  for (int index = 0; index < _advice!.items.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ActionCard(
                          index: index, text: _advice!.items[index]),
                    ),
                  if (_advice!.id != null)
                    _FeedbackCard(
                        helpful: _advice!.helpful,
                        onHelpful: () => _sendFeedback(true),
                        onNotHelpful: () => _sendFeedback(false)),
                  const SizedBox(height: 12),
                  _SourceCard(advice: _advice!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendFeedback(bool helpful) async {
    final String? adviceId = _advice?.id;
    if (adviceId == null) return;
    try {
      final DailyAdvice updated = await widget.apiClient.submitAdviceFeedback(
        adviceId,
        helpful: helpful,
      );
      if (mounted) setState(() => _advice = updated);
    } on ProfileApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }
}

class _AdviceHero extends StatelessWidget {
  const _AdviceHero(
      {required this.dateLabel,
      required this.loading,
      required this.onChooseDate});

  final String dateLabel;
  final bool loading;
  final VoidCallback onChooseDate;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return _AdvicePanel(
        radius: 32,
        child: Column(children: <Widget>[
          Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: <Color>[
                    t.glow.withValues(alpha: .9),
                    t.accentSoft.withValues(alpha: .76),
                    t.surfaceStrong
                  ]),
                  border: Border.all(color: t.outline, width: 2),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                        color: t.accent.withValues(alpha: .28), blurRadius: 32)
                  ]),
              child: Icon(Icons.water_drop_outlined,
                  color: t.textPrimary, size: 46)),
          const SizedBox(height: 14),
          Text('你的今日生命陪伴',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('基于结构化节律结果，提供温和且可执行的生活参考。',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textSecondary, height: 1.45)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
              onPressed: loading ? null : onChooseDate,
              icon: const Icon(Icons.today_outlined),
              label: Text(dateLabel)),
        ]));
  }
}

class _GenerationCard extends StatelessWidget {
  const _GenerationCard({required this.advice});
  final DailyAdvice advice;

  @override
  Widget build(BuildContext context) {
    final String title = advice.generationMode == 'llm'
        ? 'AI 增强建议'
        : advice.generationMode == 'fallback'
            ? 'AI 暂不可用 · 已使用基础建议'
            : advice.generationMode == 'safety_fallback'
                ? 'AI 内容未通过安全检查 · 已使用基础建议'
                : '基础节律建议';
    return _AdvicePanel(
        padding: const EdgeInsets.all(15),
        radius: 22,
        child: Row(children: <Widget>[
          Icon(advice.generationMode == 'llm'
              ? Icons.auto_awesome
              : Icons.rule_outlined),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                    advice.model == null
                        ? (advice.cached ? '已使用今日缓存' : '今日首次生成')
                        : '模型：${advice.model}${advice.cached ? ' · 已缓存' : ''}',
                    style: Theme.of(context).textTheme.bodySmall),
              ]))
        ]));
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.index, required this.text});
  final int index;
  final String text;

  static const List<IconData> icons = <IconData>[
    Icons.restaurant_outlined,
    Icons.bedtime_outlined,
    Icons.directions_walk_outlined,
    Icons.favorite_border_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return _AdvicePanel(
        padding: const EdgeInsets.all(15),
        radius: 22,
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.surfaceStrong,
                      border: Border.all(color: t.outline)),
                  child: Icon(icons[index % icons.length], color: t.accent)),
              const SizedBox(width: 13),
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(text,
                          style: const TextStyle(fontSize: 16, height: 1.45)))),
            ]));
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard(
      {required this.helpful,
      required this.onHelpful,
      required this.onNotHelpful});
  final bool? helpful;
  final VoidCallback onHelpful;
  final VoidCallback onNotHelpful;

  @override
  Widget build(BuildContext context) => _AdvicePanel(
      padding: const EdgeInsets.all(15),
      radius: 22,
      child: Row(children: <Widget>[
        const Expanded(
            child: Text('这份建议对你有帮助吗？',
                style: TextStyle(fontWeight: FontWeight.w700))),
        IconButton.filledTonal(
            tooltip: '有帮助',
            onPressed: onHelpful,
            icon: Icon(
                helpful == true ? Icons.thumb_up : Icons.thumb_up_outlined)),
        const SizedBox(width: 6),
        IconButton.filledTonal(
            tooltip: '没帮助',
            onPressed: onNotHelpful,
            icon: Icon(helpful == false
                ? Icons.thumb_down
                : Icons.thumb_down_outlined)),
      ]));
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.advice});
  final DailyAdvice advice;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return _AdvicePanel(
        padding: const EdgeInsets.all(15),
        radius: 20,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(children: <Widget>[
                Icon(Icons.fact_check_outlined, size: 20),
                SizedBox(width: 8),
                Text('依据与边界', style: TextStyle(fontWeight: FontWeight.w800)),
              ]),
              if (advice.knowledgeSources.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text('参考知识：${advice.knowledgeSources.join('、')}',
                    style: TextStyle(color: t.textSecondary)),
              ],
              const SizedBox(height: 8),
              Text(advice.disclaimer,
                  style: TextStyle(color: t.textSecondary, height: 1.45)),
            ]));
  }
}

class _LoadingAdvice extends StatelessWidget {
  const _LoadingAdvice();
  @override
  Widget build(BuildContext context) => const _AdvicePanel(
      child: SizedBox(
          height: 150, child: Center(child: CircularProgressIndicator())));
}

class _AdvicePanel extends StatelessWidget {
  const _AdvicePanel(
      {required this.child,
      this.padding = const EdgeInsets.all(20),
      this.radius = 26});
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return Container(
        padding: padding,
        decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: t.outline)),
        child: child);
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _AdvicePanel(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          children: <Widget>[
            Text(message),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
