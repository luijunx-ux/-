import 'package:flutter/material.dart';
import 'package:tianrenlu/features/auth/application/auth_controller.dart';
import 'package:tianrenlu/features/auth/data/auth_api_client.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({required this.controller, super.key});

  final AuthController controller;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _deleting = false;

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
    return Scaffold(
      appBar: AppBar(title: const Text('账户与隐私')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(widget.controller.user?.email ?? ''),
              subtitle: const Text('当前账户'),
            ),
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
          Text('危险操作', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _deleting ? null : _deleteAccount,
            icon: _deleting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_forever_outlined),
            label: const Text('永久注销账户及档案'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
