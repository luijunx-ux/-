import 'package:flutter/material.dart';
import 'package:tianrenlu/features/profile/data/profile_api_client.dart';
import 'package:tianrenlu/features/profile/domain/profile_models.dart';

class DailyAdvicePage extends StatefulWidget {
  const DailyAdvicePage({
    required this.apiClient,
    required this.birthInput,
    super.key,
  });

  final ProfileApiClient apiClient;
  final BirthInput birthInput;

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
