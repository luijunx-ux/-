import 'package:flutter/material.dart';
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
      appBar: AppBar(title: const Text('我的生命档案')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text(_error!, textAlign: TextAlign.center),
          TextButton(onPressed: _load, child: const Text('重试')),
        ],
      );
    }
    if (_profiles == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_profiles!.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: const <Widget>[
          Icon(Icons.folder_open_outlined, size: 56),
          SizedBox(height: 16),
          Text('还没有保存的生命档案', textAlign: TextAlign.center),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _profiles!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final LifeProfile profile = _profiles![index];
        final BirthInput? birth = profile.birthInput;
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.auto_awesome)),
            title: Row(
              children: <Widget>[
                Expanded(child: Text(profile.name)),
                if (profile.isDefault) const Chip(label: Text('默认')),
              ],
            ),
            subtitle: Text(
              '${_date(birth?.occurredAt)} · ${profile.zodiac.sign}',
            ),
            trailing: PopupMenuButton<String>(
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
            ),
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
          ),
        );
      },
    );
  }

  String _date(DateTime? value) => value == null
      ? '日期未知'
      : '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
