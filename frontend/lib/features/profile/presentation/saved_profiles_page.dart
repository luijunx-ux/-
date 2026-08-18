import 'package:flutter/material.dart';
import 'package:tianrenlu/core/life_surface.dart';
import 'package:tianrenlu/core/life_theme.dart';
import 'package:tianrenlu/features/profile/data/profile_api_client.dart';
import 'package:tianrenlu/features/profile/domain/profile_models.dart';
import 'package:tianrenlu/features/profile/presentation/profile_result_page.dart';
import 'package:tianrenlu/features/profile/presentation/profile_form_page.dart';

class SavedProfilesPage extends StatefulWidget {
  const SavedProfilesPage({required this.apiClient, super.key});

  final ProfileApiClient apiClient;

  @override
  State<SavedProfilesPage> createState() => _SavedProfilesPageState();
}

class _SavedProfilesPageState extends State<SavedProfilesPage> {
  List<LifeProfile>? _profiles;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final List<LifeProfile> profiles = await widget.apiClient.listProfiles();
      if (mounted) setState(() => _profiles = profiles);
    } on ProfileApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _delete(LifeProfile profile) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('删除生命档案？'),
        content:
            Text('将删除“${profile.birthInput?.placeName ?? '未命名档案'}”，此操作无法恢复。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || profile.id == null) return;
    try {
      await widget.apiClient.deleteProfile(profile.id!);
      await _load();
    } on ProfileApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('我的生命档案')),
      body: LifeBackground(
        child: SafeArea(
          child: RefreshIndicator(onRefresh: _load, child: _body()),
        ),
      ),
    );
  }

  Widget _body() {
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          LifeEmptyState(
              icon: Icons.cloud_off_outlined,
              title: '暂时无法读取档案',
              message: _error!,
              action: FilledButton.tonal(
                  onPressed: _load, child: const Text('重新加载'))),
        ],
      );
    }
    if (_profiles == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_profiles!.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: const <Widget>[
          LifeEmptyState(
              icon: Icons.folder_open_outlined,
              title: '还没有保存的生命档案',
              message: '从首页新建一份档案后，可以在这里查看、编辑与管理。'),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: _profiles!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final LifeProfile profile = _profiles![index];
        final BirthInput? birth = profile.birthInput;
        final LifeThemeTokens t =
            Theme.of(context).extension<LifeThemeTokens>()!;
        return LifePanel(
          onTap: birth == null
              ? null
              : () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => ProfileResultPage(
                        profile: profile,
                        birthInput: birth,
                        apiClient: widget.apiClient,
                      ),
                    ),
                  ),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: t.surfaceStrong,
                        border: Border.all(color: t.outline)),
                    child: Icon(Icons.spa_outlined, color: t.accent)),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                              child: Text(profile.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800))),
                          if (profile.isDefault)
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: t.accent.withValues(alpha: .12),
                                    borderRadius: BorderRadius.circular(99)),
                                child: Text('默认',
                                    style: TextStyle(
                                        color: t.accent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700))),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                          '${_date(birth?.occurredAt)} · ${profile.zodiac.sign}',
                          style: TextStyle(color: t.textSecondary)),
                      const SizedBox(height: 5),
                      Text(birth?.placeName ?? '地点未记录',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(color: t.textSecondary, fontSize: 13)),
                    ])),
                PopupMenuButton<String>(
                  onSelected: (String action) async {
                    if (action == 'edit') {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => ProfileFormPage(
                            apiClient: widget.apiClient,
                            initialProfile: profile,
                          ),
                        ),
                      );
                      await _load();
                    } else {
                      await _delete(profile);
                    }
                  },
                  itemBuilder: (_) => const <PopupMenuEntry<String>>[
                    PopupMenuItem(value: 'edit', child: Text('编辑或设为默认')),
                    PopupMenuItem(value: 'delete', child: Text('删除')),
                  ],
                )
              ]),
        );
      },
    );
  }

  String _date(DateTime? value) => value == null
      ? '日期未知'
      : '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
