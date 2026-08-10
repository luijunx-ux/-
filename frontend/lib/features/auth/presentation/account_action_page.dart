import 'package:flutter/material.dart';
import 'package:tianrenlu/features/auth/data/auth_api_client.dart';

class AccountActionPage extends StatefulWidget {
  const AccountActionPage({
    required this.purpose,
    required this.token,
    required this.onDone,
    super.key,
  });

  final String purpose;
  final String token;
  final VoidCallback onDone;

  @override
  State<AccountActionPage> createState() => _AccountActionPageState();
}

class _AccountActionPageState extends State<AccountActionPage> {
  final TextEditingController _password = TextEditingController();
  final AuthApiClient _api = AuthApiClient();
  bool _loading = false;
  bool _success = false;
  String? _error;

  bool get _isVerification => widget.purpose == 'email_verification';

  @override
  void initState() {
    super.initState();
    if (_isVerification) _submit();
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_isVerification && _password.text.length < 12) {
      setState(() => _error = '新密码至少需要 12 个字符');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isVerification) {
        await _api.confirmEmailVerification(widget.token);
      } else {
        await _api.resetPassword(widget.token, _password.text);
      }
      if (mounted) setState(() => _success = true);
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Icon(
                        _success
                            ? Icons.check_circle_outline
                            : Icons.shield_outlined,
                        size: 52,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _success
                            ? (_isVerification ? '邮箱验证成功' : '密码重置成功')
                            : (_isVerification ? '正在验证邮箱' : '设置新密码'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (!_isVerification && !_success) ...<Widget>[
                        const SizedBox(height: 24),
                        TextField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: '新密码',
                            helperText: '至少 12 个字符',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      if (_error != null) ...<Widget>[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (_success)
                        FilledButton(
                          onPressed: widget.onDone,
                          child: const Text('返回登录'),
                        )
                      else if (!_isVerification)
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('确认重置密码'),
                        )
                      else if (_loading)
                        const Center(child: CircularProgressIndicator())
                      else
                        OutlinedButton(
                          onPressed: _submit,
                          child: const Text('重新验证'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
