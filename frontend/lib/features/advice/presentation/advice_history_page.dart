import 'package:flutter/material.dart';
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
      appBar: AppBar(title: const Text('每日建议历史')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (_history == null && _error == null)
              const Center(child: CircularProgressIndicator())
            else if (_error != null) ...<Widget>[
              Text(_error!, textAlign: TextAlign.center),
              TextButton(onPressed: _load, child: const Text('重试')),
            ] else if (_history!.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('还没有每日建议记录', textAlign: TextAlign.center),
              )
            else
              for (final DailyAdvice advice in _history!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
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
                          ListTile(
                            leading: const Icon(Icons.circle, size: 8),
                            title: Text(item),
                          ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String _date(DateTime value) => '${value.year}年${value.month}月${value.day}日';
}
