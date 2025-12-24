import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/core.dart';
import '../widgets/user_widgets.dart';

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
    _authService = ServiceLocatorConfig.get<AuthService>();

    // 检查是否已经登录，如果已登录则直接跳转到首页
    _checkAlreadyLoggedIn();
  }

  /// 检查是否已经登录
  void _checkAlreadyLoggedIn() {
    if (_authService.isAuthenticated()) {
      // 延迟执行，确保页面构建完成
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/');
        }
      });
    }
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
        context.go('/');
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
      appBar: AppBar(
        title: const Text('用户登录'),
        actions: [
          TextButton(
            onPressed: () {
              context.go('/login'); // 使用GoRouter导航到管理员登录
            },
            child: const Text('管理员登录', style: TextStyle(color: Colors.white)),
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
                        Icons.radio,
                        size: 40,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bipupu 寻呼机',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '欢迎回来',
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
                        labelText: '用户名或邮箱',
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
                          (v == null || v.isEmpty) ? '请输入用户名或邮箱' : null,
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
                      validator: (v) =>
                          (v == null || v.isEmpty) ? '请输入密码' : null,
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

                    // 登录按钮
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: CoreButton.primary(
                        text: '登录',
                        onPressed: _loading ? null : _submit,
                        isLoading: _loading,
                        icon: Icons.login,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 注册链接
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '还没有账号？',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            context.go('/register'); // 使用GoRouter导航到注册页面
                          },
                          child: const Text('立即注册'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 快速登录提示
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '测试账号',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '用户名: testuser 或 test@example.com',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '密码: 123456',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
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
