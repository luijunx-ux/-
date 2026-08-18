import 'package:flutter/material.dart';
import 'package:tianrenlu/core/life_surface.dart';
import 'package:tianrenlu/core/life_theme.dart';
import 'package:tianrenlu/features/profile/data/profile_api_client.dart';
import 'package:tianrenlu/features/profile/domain/profile_models.dart';

class AdviceHistoryPage extends StatefulWidget {
  const AdviceHistoryPage({required this.apiClient, super.key});

  final ProfileApiClient apiClient;

  @override
  State<AdviceHistoryPage> createState() => _AdviceHistoryPageState();
}

class _AdviceHistoryPageState extends State<AdviceHistoryPage> {
  List<DailyAdvice>? _history;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final List<DailyAdvice> history =
          await widget.apiClient.listAdviceHistory();
      if (mounted) setState(() => _history = history);
    } on ProfileApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('每日建议历史')),
      body: LifeBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: <Widget>[
                if (_history == null && _error == null)
                  const LifePanel(
                      child: SizedBox(
                          height: 160,
                          child: Center(child: CircularProgressIndicator())))
                else if (_error != null) ...<Widget>[
                  LifeEmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: '暂时无法读取历史',
                      message: _error!,
                      action: FilledButton.tonal(
                          onPressed: _load, child: const Text('重新加载'))),
                ] else if (_history!.isEmpty)
                  const LifeEmptyState(
                      icon: Icons.history_rounded,
                      title: '还没有每日建议记录',
                      message: '查看一份今日建议后，记录会安全地出现在这里。')
                else
                  for (final DailyAdvice advice in _history!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: LifePanel(
                        padding: EdgeInsets.zero,
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            leading: const Icon(Icons.auto_awesome_outlined),
                            title: Text(_date(advice.targetDate)),
                            subtitle: Text(
                              advice.helpful == null
                                  ? '尚未反馈'
                                  : advice.helpful!
                                      ? '有帮助'
                                      : '没帮助',
                            ),
                            children: <Widget>[
                              for (final String item in advice.items)
                                _HistoryAdviceRow(text: item),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _date(DateTime value) => '${value.year}年${value.month}月${value.day}日';
}

class _HistoryAdviceRow extends StatelessWidget {
  const _HistoryAdviceRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
      child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Icon(Icons.circle, size: 7, color: t.accent)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(height: 1.45))),
      ]),
    );
  }
}
