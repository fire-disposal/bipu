import 'package:flutter/material.dart';
import '../../core/core.dart';
import '../../core/widgets/core_button.dart';

/// 用户注册页
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _username = '';
  bool _loading = false;
  String? _error;

  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    // 通过依赖注入获取认证服务
    _authService = getIt<AuthService>();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    _formKey.currentState!.save();

    try {
      final result = await _authService.register(
        username: _username,
        email: _email,
        password: _password,
      );

      setState(() => _loading = false);

      if (result.success) {
        if (!mounted) return;
        // 注册成功，跳转到主页
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        setState(() => _error = result.message ?? '注册失败，请检查信息');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '注册异常: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('用户注册')),
      body: Center(
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
                    '用户注册',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: '邮箱',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (v) => _email = v ?? '',
                    validator: (v) => (v == null || v.isEmpty) ? '请输入邮箱' : null,
                  ),
                  const SizedBox(height: 16),
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
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 32),
                  CoreButton(
                    label: '注册',
                    onPressed: _loading ? null : _submit,
                    loading: _loading,
                    icon: Icons.app_registration,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: const Text('已有账号？登录'),
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
