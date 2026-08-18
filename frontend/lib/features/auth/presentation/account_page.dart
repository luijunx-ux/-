import 'package:flutter/material.dart';
import 'package:tianrenlu/core/life_surface.dart';
import 'package:tianrenlu/core/life_theme.dart';
import 'package:tianrenlu/features/auth/application/auth_controller.dart';
import 'package:tianrenlu/features/auth/data/auth_api_client.dart';
import 'package:tianrenlu/features/auth/domain/auth_models.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({required this.controller, super.key});

  final AuthController controller;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _deleting = false;
  bool _loadingSessions = true;
  bool _revokingOthers = false;
  List<AccountSession> _sessions = const <AccountSession>[];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final List<AccountSession> sessions = await widget.controller.sessions();
      if (mounted) setState(() => _sessions = sessions);
    } on AuthApiException {
      // The rest of the account page remains usable if session loading fails.
    } finally {
      if (mounted) setState(() => _loadingSessions = false);
    }
  }

  String _dateTime(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

  Future<void> _revokeOtherSessions() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('退出其他设备？'),
        content: const Text('其他设备将在访问令牌到期后无法继续续期，当前设备不受影响。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认退出'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _revokingOthers = true);
    try {
      await widget.controller.revokeOtherSessions();
      await _loadSessions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('其他设备已退出')),
        );
      }
    } on AuthApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _revokingOthers = false);
    }
  }

  Future<void> _deleteAccount() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('永久注销账户？'),
        content: const Text('此操作会删除账户及其已保存生命档案，且无法恢复。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('确认注销'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await widget.controller.deleteAccount();
      if (mounted) Navigator.of(context).pop();
    } on AuthApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LifeThemeTokens t = Theme.of(context).extension<LifeThemeTokens>()!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('账户与隐私')),
      body: LifeBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: <Widget>[
              LifePanel(
                radius: 30,
                child: Row(children: <Widget>[
                  Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: <Color>[
                            t.glow.withValues(alpha: .85),
                            t.accentSoft,
                            t.surfaceStrong
                          ]),
                          border: Border.all(color: t.outline)),
                      child: Icon(Icons.person_outline,
                          color: t.accent, size: 30)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                        const Text('当前账户',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(widget.controller.user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: t.textSecondary)),
                      ]))
                ]),
              ),
              const SizedBox(height: 16),
              Text('登录设备', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_loadingSessions)
                const Center(child: CircularProgressIndicator())
              else if (_sessions.isEmpty)
                const LifePanel(
                  child: Row(children: <Widget>[
                    Icon(Icons.devices_outlined),
                    SizedBox(width: 12),
                    Text('暂时无法读取会话'),
                  ]),
                )
              else
                ..._sessions.map(
                  (AccountSession session) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LifePanel(
                      padding: const EdgeInsets.all(15),
                      child: Row(children: <Widget>[
                        Icon(session.isCurrent
                            ? Icons.smartphone
                            : Icons.devices_other),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                              Text(session.isCurrent ? '当前设备' : '其他设备',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 5),
                              Text(
                                  '登录：${_dateTime(session.createdAt)}\n到期：${_dateTime(session.expiresAt)}',
                                  style: TextStyle(
                                      color: t.textSecondary,
                                      height: 1.4,
                                      fontSize: 13)),
                            ])),
                        if (session.isCurrent)
                          Icon(Icons.verified_rounded,
                              color: t.accent, size: 20)
                      ]),
                    ),
                  ),
                ),
              if (_sessions.any((AccountSession session) => !session.isCurrent))
                OutlinedButton.icon(
                  onPressed: _revokingOthers ? null : _revokeOtherSessions,
                  icon: _revokingOthers
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.phonelink_erase_outlined),
                  label: const Text('退出其他设备'),
                ),
              const SizedBox(height: 16),
              if (widget.controller.user?.emailVerified == false)
                FilledButton.tonalIcon(
                  onPressed: _deleting
                      ? null
                      : () async {
                          await widget.controller.requestEmailVerification();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('验证邮件已请求，请检查邮箱')),
                            );
                          }
                        },
                  icon: const Icon(Icons.mark_email_unread_outlined),
                  label: const Text('发送邮箱验证邮件'),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _deleting
                    ? null
                    : () async {
                        await widget.controller.logout();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                icon: const Icon(Icons.logout),
                label: const Text('退出登录'),
              ),
              const SizedBox(height: 32),
              LifePanel(
                radius: 20,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('危险操作',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text('永久注销会删除账户及已保存的生命档案。',
                          style: TextStyle(color: t.textSecondary)),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: _deleting ? null : _deleteAccount,
                        icon: _deleting
                            ? const SizedBox.square(
                                dimension: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_forever_outlined),
                        label: const Text('永久注销账户及档案'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
