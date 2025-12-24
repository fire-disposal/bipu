import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/core.dart';
import '../widgets/admin_widgets.dart';

/// 管理端登录页
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

      if (result.success) {
        // 检查管理员权限
        final adminValidation = await _authService.validateAdminAccess();

        setState(() => _loading = false);

        if (adminValidation.success) {
          if (!mounted) return;
          // 管理员权限验证通过，跳转到管理仪表板
          GoRouter.of(context).go('/');
        } else {
          // 不是管理员，注销并显示错误
          await _authService.logout();
          setState(() => _error = adminValidation.message ?? '需要管理员权限才能访问管理端');
        }
      } else {
        setState(() {
          _loading = false;
          _error = result.message ?? '登录失败，请检查用户名和密码';
        });
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
        title: const Text('管理员登录'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('用户登录', style: TextStyle(color: Colors.white)),
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
                        Icons.admin_panel_settings,
                        size: 40,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '管理控制台',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '管理员身份验证',
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
                        labelText: '管理员用户名',
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
                          (v == null || v.isEmpty) ? '请输入管理员用户名' : null,
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
                        text: '管理员登录',
                        onPressed: _loading ? null : _submit,
                        isLoading: _loading,
                        icon: Icons.login,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 权限提示
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.security,
                                color: Theme.of(context).colorScheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '需要管理员权限',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '此区域仅对系统管理员开放',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 测试账号提示
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '测试管理员账号',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '用户名: admin',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '密码: admin123',
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
