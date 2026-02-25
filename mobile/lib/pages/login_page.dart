import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/components/ui_components.dart';
import '../controllers/auth_controller.dart';
import '../services/auth_service.dart';

/// 现代化登录页面 - 已移除调试信息并优化逻辑
class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

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
        Text(
          '宇宙传讯',
          style: TextStyle(
            fontSize: 16,
            color: theme.colorScheme.mutedForeground,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  /// 构建登录表单
  Widget _buildLoginForm(BuildContext context, AuthController authController) {
    final theme = ShadTheme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        children: [
          UIInput(
            controller: _usernameController,
            labelText: '用户名',
            hintText: '请输入用户名',
            prefixIcon: Icon(
              Icons.person,
              color: theme.colorScheme.mutedForeground,
              size: 20,
            ),
            onChanged: (value) => authController.setUsername(value),
            validator: (value) =>
                (value == null || value.isEmpty) ? '请输入用户名' : null,
            autoFocus: true,
          ),
          const SizedBox(height: 20),
          UIPasswordInput(
            controller: _passwordController,
            labelText: '密码',
            hintText: '请输入密码',
            onChanged: (value) => authController.setPassword(value),
            validator: (value) =>
                (value == null || value.isEmpty || value.length < 6)
                ? '密码至少6个字符'
                : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // 记住我
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(value: false, onChanged: (v) {}),
              ),
              const SizedBox(width: 8),
              const Text('记住我', style: TextStyle(fontSize: 14)),
              const Spacer(),
              TextButton(
                onPressed: () => Get.snackbar('提示', '忘记密码功能开发中'),
                child: Text(
                  '忘记密码？',
                  style: TextStyle(color: theme.colorScheme.primary),
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
    return Obx(() {
      final isLoading = authService.isLoading.value;
      return SizedBox(
        width: double.infinity,
        child: UIButton(
          onPressed: isLoading
              ? null
              : () {
                  print('🖱️ 登录按钮被点击');
                  authController.login();
                },
          isLoading: isLoading,
          child: Text(isLoading ? '登录中...' : '立即登录'),
        ),
      );
    });
  }

  Widget _buildRegisterLink(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '还没有账户？',
          style: TextStyle(color: theme.colorScheme.mutedForeground),
        ),
        TextButton(
          onPressed: () => Get.snackbar('提示', '注册功能开发中'),
          child: Text(
            '立即注册',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
