import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('每日生命建议')),
      body: RefreshIndicator(
        onRefresh: _loadAdvice,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: _loading ? null : _chooseDate,
              icon: const Icon(Icons.today_outlined),
              label: Text(_dateLabel),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              _ErrorCard(message: _error!, onRetry: _loadAdvice)
            else if (_advice != null) ...<Widget>[
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: ListTile(
                  leading: Icon(
                    _advice!.generationMode == 'llm'
                        ? Icons.auto_awesome
                        : Icons.rule_outlined,
                  ),
                  title: Text(
                    _advice!.generationMode == 'llm'
                        ? 'AI 增强建议'
                        : _advice!.generationMode == 'fallback'
                            ? 'AI 暂不可用 · 已使用基础建议'
                            : _advice!.generationMode == 'safety_fallback'
                                ? 'AI 内容未通过安全检查 · 已使用基础建议'
                                : '基础节律建议',
                  ),
                  subtitle: _advice!.model == null
                      ? Text(_advice!.cached ? '已使用今日缓存' : '今日首次生成')
                      : Text(
                          '模型：${_advice!.model}${_advice!.cached ? ' · 已缓存' : ''}',
                        ),
                ),
              ),
              const SizedBox(height: 12),
              if (_advice!.id != null) ...<Widget>[
                Text('这份建议对你有帮助吗？'),
                Row(
                  children: <Widget>[
                    ChoiceChip(
                      label: const Text('有帮助'),
                      selected: _advice!.helpful == true,
                      onSelected: (_) => _sendFeedback(true),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('没帮助'),
                      selected: _advice!.helpful == false,
                      onSelected: (_) => _sendFeedback(false),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              for (int index = 0; index < _advice!.items.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(_advice!.items[index]),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              if (_advice!.knowledgeSources.isNotEmpty) ...<Widget>[
                Text(
                  '参考知识：${_advice!.knowledgeSources.join('、')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
              ],
              Text(
                _advice!.disclaimer,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
