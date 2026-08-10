import 'package:flutter/material.dart';
import 'package:tianrenlu/features/auth/application/auth_controller.dart';
import 'package:tianrenlu/features/auth/data/auth_api_client.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({required this.controller, super.key});

  final AuthController controller;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  static const bool _demoMode = bool.fromEnvironment('DEMO_MODE');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _registering = false;
  bool _submitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      if (_registering) {
        await widget.controller.register(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        await widget.controller.login(
          _emailController.text,
          _passwordController.text,
        );
      }
    } on AuthApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Icon(
                      Icons.spa_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '天人律',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _registering ? '创建你的生命节律账户' : '登录并继续生命节律探索',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const <String>[AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: _demoMode ? '用户名或邮箱' : '邮箱',
                        border: OutlineInputBorder(),
                      ),
                      validator: (String? value) {
                        final String email = value?.trim() ?? '';
                        return email.contains('@') ||
                                (_demoMode && email == 'admin')
                            ? null
                            : '请输入有效邮箱地址';
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: <String>[
                        _registering
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      decoration: InputDecoration(
                        labelText: '密码',
                        helperText: '至少 12 个字符',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (String? value) =>
                          (value?.length ?? 0) >= 12 ? null : '密码至少需要 12 个字符',
                      onFieldSubmitted: (_) {
                        if (!_submitting) _submit();
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_registering ? '注册并登录' : '登录'),
                    ),
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () => setState(() => _registering = !_registering),
                      child: Text(
                        _registering ? '已有账户？返回登录' : '没有账户？立即注册',
                      ),
                    ),
                    if (!_registering)
                      TextButton(
                        onPressed: _submitting ? null : _requestPasswordReset,
                        child: const Text('忘记密码？发送重置邮件'),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '生命节律内容仅供个人观察参考，不构成医疗建议。',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestPasswordReset() async {
    final String email = _emailController.text.trim();
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入有效邮箱地址')),
      );
      return;
    }
    try {
      await widget.controller.requestPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('如果账户存在，重置邮件将很快发送')),
        );
      }
    } on AuthApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }
}
