import 'package:flutter/material.dart';
import 'package:tianrenlu/features/advice/presentation/daily_advice_page.dart';
import 'package:tianrenlu/features/advice/presentation/advice_history_page.dart';
import 'package:tianrenlu/features/profile/data/profile_api_client.dart';
import 'package:tianrenlu/features/profile/domain/profile_models.dart';
import 'package:tianrenlu/features/profile/presentation/profile_form_page.dart';
import 'package:tianrenlu/features/profile/presentation/profile_result_page.dart';
import 'package:tianrenlu/features/profile/presentation/saved_profiles_page.dart';

class TodayDashboardPage extends StatefulWidget {
  const TodayDashboardPage({
    required this.apiClient,
    required this.accountPageBuilder,
    super.key,
  });

  final ProfileApiClient apiClient;
  final Widget Function() accountPageBuilder;

  @override
  State<TodayDashboardPage> createState() => _TodayDashboardPageState();
}

class _TodayDashboardPageState extends State<TodayDashboardPage> {
  List<LifeProfile>? _profiles;
  String? _error;
  int _viewingStreak = 0;

  LifeProfile? get _defaultProfile {
    final List<LifeProfile>? profiles = _profiles;
    if (profiles == null || profiles.isEmpty) return null;
    return profiles.firstWhere(
      (LifeProfile profile) => profile.isDefault,
      orElse: () => profiles.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final List<LifeProfile> profiles = await widget.apiClient.listProfiles();
      final int streak =
          await widget.apiClient.getViewingStreak(DateTime.now());
      if (mounted) {
        setState(() {
          _profiles = profiles;
          _viewingStreak = streak;
        });
      }
    } on ProfileApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => page),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final LifeProfile? profile = _defaultProfile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('今日节律'),
        actions: <Widget>[
          IconButton(
            tooltip: '账户与隐私',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _open(widget.accountPageBuilder()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Text(_greeting(),
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(_today()),
            if (_viewingStreak > 0) ...<Widget>[
              const SizedBox(height: 8),
              Chip(
                avatar: const Icon(Icons.local_fire_department_outlined),
                label: Text('已连续查看 $_viewingStreak 天'),
              ),
            ],
            const SizedBox(height: 24),
            if (_profiles == null && _error == null)
              const Center(child: CircularProgressIndicator())
            else if (_error != null) ...<Widget>[
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!),
                ),
              ),
              TextButton(onPressed: _load, child: const Text('重新加载')),
            ] else if (profile == null)
              _EmptyProfileCard(
                onCreate: () => _open(
                  ProfileFormPage(apiClient: widget.apiClient),
                ),
              )
            else ...<Widget>[
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(Icons.bookmark_added_outlined),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              profile.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const Chip(label: Text('默认')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${profile.zodiac.sign} · ${profile.wuyunLiuqi.middleMovement} ${profile.wuyunLiuqi.movementStrength}',
                      ),
                      Text(profile.birthInput?.placeName ?? ''),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: profile.birthInput == null
                    ? null
                    : () => _open(
                          DailyAdvicePage(
                            apiClient: widget.apiClient,
                            birthInput: profile.birthInput!,
                            profileId: profile.id,
                          ),
                        ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('查看今日 AI 生命建议'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: profile.birthInput == null
                    ? null
                    : () => _open(
                          ProfileResultPage(
                            profile: profile,
                            birthInput: profile.birthInput!,
                            apiClient: widget.apiClient,
                          ),
                        ),
                icon: const Icon(Icons.insights_outlined),
                label: const Text('查看默认档案详情'),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _open(
                      ProfileFormPage(apiClient: widget.apiClient),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('新建档案'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _open(
                      SavedProfilesPage(apiClient: widget.apiClient),
                    ),
                    icon: const Icon(Icons.folder_copy_outlined),
                    label: const Text('全部档案'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _open(
                AdviceHistoryPage(apiClient: widget.apiClient),
              ),
              icon: const Icon(Icons.history),
              label: const Text('每日建议历史'),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final int hour = DateTime.now().hour;
    if (hour < 11) return '早上好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  String _today() {
    final DateTime now = DateTime.now();
    return '${now.year}年${now.month}月${now.day}日';
  }
}

class _EmptyProfileCard extends StatelessWidget {
  const _EmptyProfileCard({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            const Icon(Icons.spa_outlined, size: 48),
            const SizedBox(height: 12),
            const Text('建立第一个生命档案后，即可在这里查看今日节律。'),
            const SizedBox(height: 16),
            FilledButton(onPressed: onCreate, child: const Text('建立生命档案')),
          ],
        ),
      ),
    );
  }
}
