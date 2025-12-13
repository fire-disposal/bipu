import 'package:flutter/material.dart';
import '../../core/widgets/core_button.dart';
import '../widgets/admin_layout.dart';

/// 管理员登录页
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  bool _loading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    _formKey.currentState!.save();
    // TODO: 调用核心 API 进行登录
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _loading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('登录功能开发中...')));
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: '管理员登录',
      child: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '管理员登录',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: '用户名',
                      prefixIcon: Icon(Icons.person),
                    ),
                    onSaved: (v) => _username = v ?? '',
                    validator: (v) =>
                        (v == null || v.isEmpty) ? '请输入用户名' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: '密码',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    onSaved: (v) => _password = v ?? '',
                    validator: (v) => (v == null || v.isEmpty) ? '请输入密码' : null,
                  ),
                  const SizedBox(height: 32),
                  CoreButton(
                    label: '登录',
                    onPressed: _loading ? null : _submit,
                    loading: _loading,
                    icon: Icons.login,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
