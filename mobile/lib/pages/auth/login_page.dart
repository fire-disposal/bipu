import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/snackbar_manager.dart';
import '../../core/network/network.dart';
import '../../core/network/api_exception.dart';

class UserLoginPage extends StatefulWidget {
  const UserLoginPage({super.key});

  @override
  State<UserLoginPage> createState() => _UserLoginPageState();
}

class _UserLoginPageState extends State<UserLoginPage>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // 10秒一个周期的呼吸感动画
    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- 真实接口逻辑保持不变 ---
  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      SnackBarManager.showInputWarning('Please enter username and password');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService().login(username, password);
      if (mounted) context.go('/');
    } on AuthException catch (e) {
      if (mounted)
        SnackBarManager.showError('Authentication failed: ${e.message}');
    } on ValidationException catch (e) {
      String errorMessage =
          e.errors?.entries.map((entry) => entry.value.toString()).join(', ') ??
          e.message;
      if (mounted) SnackBarManager.showError(errorMessage);
    } on NetworkException catch (e) {
      if (mounted) SnackBarManager.showNetworkError(e.message);
    } on ServerException catch (e) {
      if (mounted) SnackBarManager.showServerError(e.message);
    } on ParseException catch (e) {
      if (mounted)
        SnackBarManager.showError('Data parsing error: ${e.message}');
    } on ApiException catch (e) {
      if (mounted) SnackBarManager.showError('API error: ${e.message}');
    } catch (e) {
      if (mounted) SnackBarManager.showError('Login failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // 1. 动态弥散背景
          _buildDynamicBackground(isDark),

          // 2. 内容层
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 3. 优化的蓝色渐变 Logo
                    _buildAnimatedLogo(),
                    const SizedBox(height: 8),
                    Text(
                      'welcome_back'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // 4. 输入框组
                    _buildInputField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                    ),
                    const SizedBox(height: 32),

                    // 5. 登录按钮
                    _buildLoginButton(),

                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: Text(
                        'Don\'t have an account? Register',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建动态背景
  Widget _buildDynamicBackground(bool isDark) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.lerp(
                Alignment.topLeft,
                Alignment.bottomLeft,
                _animationController.value,
              )!,
              end: Alignment.lerp(
                Alignment.bottomRight,
                Alignment.topRight,
                _animationController.value,
              )!,
              colors: isDark
                  ? const [
                      Color(0xFF0A192F),
                      Color(0xFF112240),
                      Color(0xFF0A192F),
                    ]
                  : const [
                      Color(0xFFF0F7FF),
                      Color(0xFFE6F0FF),
                      Color(0xFFF0F7FF),
                    ],
            ),
          ),
        );
      },
    );
  }

  // 构建渐变文字 Logo
  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final lerp = Curves.easeInOutSine.transform(_animationController.value);
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [lerp - 0.3, lerp, lerp + 0.3],
            colors: const [
              Color(0xFF0072FF), // 深蓝
              Color(0xFF00C6FF), // 亮蓝
              Color(0xFF0072FF),
            ],
          ).createShader(bounds),
          child: const Text(
            'Bipupu',
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.0,
            ),
          ),
        );
      },
    );
  }

  // 封装输入框 (适配深浅模式)
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  // 封装登录按钮
  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0072FF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Login',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
