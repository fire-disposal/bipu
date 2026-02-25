import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/components/ui_components.dart';
import '../controllers/auth_controller.dart';
import '../services/auth_service.dart';

import 'register_page.dart';

/// 现代化登录页面
/// 使用全新的基础设施和状态刷新优化
class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  // Focus nodes are available but not currently used
  // final _usernameFocusNode = FocusNode();
  // final _passwordFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final authController = Get.find<AuthController>();
    final authService = Get.find<AuthService>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.background,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo和标题区域
                  _buildHeaderSection(context),

                  const SizedBox(height: 40),

                  // 登录表单
                  _buildLoginForm(context, authController),

                  const SizedBox(height: 24),

                  // 登录按钮
                  _buildLoginButton(context, authController, authService),

                  const SizedBox(height: 16),

                  // 注册链接
                  _buildRegisterLink(context),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建头部区域
  Widget _buildHeaderSection(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      children: [
        // Logo图标
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.rocket_launch,
            color: theme.colorScheme.primaryForeground,
            size: 40,
          ),
        ),

        const SizedBox(height: 24),

        // 主标题
        Text(
          'BIPUPU',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
            letterSpacing: 2.0,
          ),
        ),

        const SizedBox(height: 8),

        // 副标题
        Text(
          '宇宙传讯',
          style: TextStyle(
            fontSize: 16,
            color: theme.colorScheme.mutedForeground,
            letterSpacing: 1.5,
          ),
        ),

        const SizedBox(height: 8),

        // 欢迎语
        Text(
          '欢迎回来，请登录您的账户',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.mutedForeground,
          ),
        ),
      ],
    );
  }

  /// 构建登录表单
  Widget _buildLoginForm(BuildContext context, AuthController authController) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // 用户名输入框
          UIInput(
            controller: _usernameController,
            labelText: '用户名',
            hintText: '请输入用户名',
            prefixIcon: Icon(
              Icons.person,
              color: ShadTheme.of(context).colorScheme.mutedForeground,
              size: 20,
            ),
            keyboardType: TextInputType.text,
            // textInputAction: TextInputAction.next,
            onChanged: (value) => authController.setUsername(value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入用户名';
              }
              if (value.length < 3) {
                return '用户名至少3个字符';
              }
              return null;
            },
            autoFocus: true,
          ),

          const SizedBox(height: 20),

          // 密码输入框
          Obx(() {
            return UIPasswordInput(
              controller: _passwordController,
              labelText: '密码',
              hintText: '请输入密码',
              onChanged: (value) => authController.setPassword(value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入密码';
                }
                if (value.length < 6) {
                  return '密码至少6个字符';
                }
                return null;
              },
            );
          }),

          const SizedBox(height: 16),

          // 记住我选项
          Row(
            children: [
              Obx(() {
                final rememberMe = false.obs; // 暂时硬编码
                return Checkbox(
                  value: rememberMe.value,
                  onChanged: (value) => rememberMe.value = value ?? false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
              const SizedBox(width: 8),
              Text(
                '记住我',
                style: TextStyle(
                  fontSize: 14,
                  color: ShadTheme.of(context).colorScheme.foreground,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Get.snackbar('提示', '忘记密码功能开发中');
                },
                child: Text(
                  '忘记密码？',
                  style: TextStyle(
                    fontSize: 14,
                    color: ShadTheme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建登录按钮
  Widget _buildLoginButton(
    BuildContext context,
    AuthController authController,
    AuthService authService,
  ) {
    final theme = ShadTheme.of(context);

    return Obx(() {
      final isLoading = authService.isLoading.value;
      // final canLogin = authController.canLogin;

      return SizedBox(
        width: double.infinity,
        child: UIButton(
          onPressed: isLoading
              ? null
              : () async {
                  // 隐藏键盘
                  FocusScope.of(context).unfocus();

                  // 验证表单
                  if (_formKey.currentState?.validate() ?? false) {
                    // 更新控制器中的用户名和密码
                    authController.setUsername(_usernameController.text);
                    authController.setPassword(_passwordController.text);

                    // 执行登录
                    final response = await authService.login(
                      _usernameController.text,
                      _passwordController.text,
                    );

                    if (response.success) {
                      // 登录成功，清空表单
                      _usernameController.clear();
                      _passwordController.clear();
                      authController.clearForm();

                      // 导航到主页面
                      Get.offAllNamed('/');
                    } else if (response.error != null) {
                      // 使用UI组件库的Snackbar显示错误
                      Get.snackbar(
                        '登录失败',
                        response.error!.message,
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: theme.colorScheme.destructive,
                        colorText: theme.colorScheme.destructiveForeground,
                        borderRadius: 8,
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 3),
                      );
                    }
                  }
                },
          isLoading: isLoading,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primaryForeground,
                  ),
                )
              else
                const Icon(Icons.login, size: 20),
              const SizedBox(width: 8),
              Text(isLoading ? '登录中...' : '登录'),
            ],
          ),
        ),
      );
    });
  }

  /// 构建注册链接
  Widget _buildRegisterLink(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '还没有账户？',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.mutedForeground,
          ),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () {
            Get.to(() => RegisterPage());
          },
          child: Text(
            '立即注册',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
