import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/toast_service.dart';

import '../../core/utils/error_message_mapper.dart';

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
  String? _errorMessage;
  bool _showPassword = false;

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

    // 验证输入
    if (username.isEmpty) {
      _showError('enter_username'.tr());
      return;
    }
    if (password.isEmpty) {
      _showError('enter_password'.tr());
      return;
    }

    // 清除之前的错误消息
    _clearError();

    setState(() => _isLoading = true);
    try {
      await AuthService().login(username, password);
      if (mounted) {
        // 登录成功，跳转到首页
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = ErrorMessageMapper.getMessage(
          e,
          isUserFacing: true,
        );
        _showError(errorMessage);
        ErrorMessageMapper.logException(e, 'Login');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    // 同时显示 Snackbar
    ToastService.error(message);
  }

  void _clearError() {
    setState(() => _errorMessage = null);
  }

  void _togglePasswordVisibility() {
    setState(() => _showPassword = !_showPassword);
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

                    // 4. 错误消息显示
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _clearError,
                              child: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 5. 输入框组
                    _buildInputField(
                      controller: _usernameController,
                      label: 'username'.tr(),
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _passwordController,
                      label: 'password'.tr(),
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                    ),
                    const SizedBox(height: 32),

                    // 6. 登录按钮
                    _buildLoginButton(),

                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => context.push('/register'),
                      child: Text(
                        'no_account_register'.tr(),
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
    final bool isPasswordField = isPassword;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPasswordField && !_showPassword,
        enabled: !_isLoading,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: isPasswordField
              ? IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility : Icons.visibility_off,
                    size: 20,
                  ),
                  onPressed: _togglePasswordVisibility,
                )
              : null,
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
            : Text(
                'login_button'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
