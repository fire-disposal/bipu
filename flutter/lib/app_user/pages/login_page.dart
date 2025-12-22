import 'package:flutter/material.dart';
import '../../core/core.dart';
import '../../core/widgets/core_button.dart';

/// 用户登录页
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
      final result = await _authService.login(
        username: _username,
        password: _password,
      );

      setState(() => _loading = false);

      if (result.success) {
        if (!mounted) return;
        // 登录成功，跳转到主页
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        setState(() => _error = result.message ?? '登录失败，请检查用户名和密码');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '登录异常: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('用户登录')),
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
                    '用户登录',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: '用户名',
                      prefixIcon: Icon(Icons.person),
                    ),
                    keyboardType: TextInputType.text,
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
                    label: '登录',
                    onPressed: _loading ? null : _submit,
                    loading: _loading,
                    icon: Icons.login,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/register');
                    },
                    child: const Text('没有账号？注册'),
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
