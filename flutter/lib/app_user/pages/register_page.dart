import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/core.dart';
import '../widgets/user_widgets.dart';

/// 用户注册页
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _email = '';
  String _password = '';
  bool _loading = false;
  String? _error;

  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    // 通过依赖注入获取认证服务
    _authService = ServiceLocatorConfig.get<AuthService>();
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
        context.go('/');
      } else {
        setState(() => _error = result.message ?? '注册失败，请重试');
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
      appBar: AppBar(
        title: const Text('用户注册'),
        actions: [
          TextButton(
            onPressed: () {
              context.go('/login');
            },
            child: const Text('已有账号？登录', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo区域
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_add,
                        size: 40,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '创建账号',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '加入我们，开始使用寻呼机',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 用户名输入
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: '用户名',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      keyboardType: TextInputType.text,
                      onSaved: (v) => _username = v ?? '',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? '请输入用户名' : null,
                    ),
                    const SizedBox(height: 16),

                    // 邮箱输入
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: '邮箱',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onSaved: (v) => _email = v ?? '',
                      validator: (v) {
                        if (v == null || v.isEmpty) return '请输入邮箱';
                        if (!EmailValidator.isValid(v)) return '请输入有效的邮箱地址';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 密码输入
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: '密码',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      obscureText: true,
                      onSaved: (v) => _password = v ?? '',
                      validator: (v) {
                        if (v == null || v.isEmpty) return '请输入密码';
                        if (v.length < 6) return '密码长度不能少于6位';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 确认密码输入
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: '确认密码',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return '请确认密码';
                        if (v != _password) return '两次输入的密码不一致';
                        return null;
                      },
                    ),

                    // 错误提示
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Theme.of(context).colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // 注册按钮
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: CoreButton.primary(
                        text: '注册',
                        onPressed: _loading ? null : _submit,
                        isLoading: _loading,
                        icon: Icons.person_add,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 登录链接
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '已有账号？',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            context.go('/login');
                          },
                          child: const Text('立即登录'),
                        ),
                      ],
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
}
