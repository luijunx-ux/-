import 'package:flutter/material.dart';
import 'package:tianrenlu/features/advice/presentation/daily_advice_page.dart';
import 'package:tianrenlu/features/profile/data/profile_api_client.dart';
import 'package:tianrenlu/features/profile/domain/profile_models.dart';

class ProfileResultPage extends StatelessWidget {
  const ProfileResultPage({
    required this.profile,
    required this.birthInput,
    required this.apiClient,
    super.key,
  });

  final LifeProfile profile;
  final BirthInput birthInput;
  final ProfileApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    final WuyunLiuqiInfo rhythm = profile.wuyunLiuqi;
    return Scaffold(
      appBar: AppBar(title: const Text('个人生命档案')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          _SectionCard(
            title: profile.zodiac.sign,
            subtitle: '太阳星座',
            rows: <String>[
              '元素：${profile.zodiac.element}',
              '模式：${profile.zodiac.modality}',
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: '${rhythm.heavenlyStem}${rhythm.earthlyBranch}年',
            subtitle: '五运六气 · ${rhythm.algorithmVersion}',
            rows: <String>[
              '中运：${rhythm.middleMovement} · ${rhythm.movementStrength}',
              '司天：${rhythm.governingQi}',
              '在泉：${rhythm.respondingQi}',
            ],
          ),
          if (rhythm.boundaryWarning != null) ...<Widget>[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(rhythm.boundaryWarning!),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => DailyAdvicePage(
                  apiClient: apiClient,
                  birthInput: birthInput,
                ),
              ),
            ),
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('查看每日生命建议'),
          ),
          const SizedBox(height: 24),
          Text(
            profile.disclaimer,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.rows,
  });

  final String title;
  final String subtitle;
  final List<String> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(subtitle, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const Divider(height: 24),
            for (final String row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(row),
              ),
          ],
        ),
      ),
    );
  }
}
