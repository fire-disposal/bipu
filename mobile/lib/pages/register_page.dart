import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/components/ui_components.dart';
import '../controllers/auth_controller.dart';
import '../services/auth_service.dart';

/// 现代化注册页面
/// 与登录页面风格一致，提供完整的注册功能
class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final authController = Get.find<AuthController>();
    final authService = Get.find<AuthService>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: const Text('注册'),
      ),
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

                  const SizedBox(height: 32),

                  // 注册表单
                  _buildRegisterForm(context, authController),

                  const SizedBox(height: 24),

                  // 注册按钮
                  _buildRegisterButton(context, authController, authService),

                  const SizedBox(height: 16),

                  // 登录链接
                  _buildLoginLink(context),

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
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Icon(
            Icons.person_add,
            color: theme.colorScheme.primaryForeground,
            size: 32,
          ),
        ),

        const SizedBox(height: 20),

        // 主标题
        Text(
          '创建账户',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.foreground,
          ),
        ),

        const SizedBox(height: 8),

        // 副标题
        Text(
          '加入BIPUPU，开始宇宙传讯之旅',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 构建注册表单
  Widget _buildRegisterForm(
    BuildContext context,
    AuthController authController,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // 用户名输入框
          UIInput(
            controller: _usernameController,
            labelText: '用户名',
            hintText: '请输入用户名（3-50个字符）',
            prefixIcon: Icon(
              Icons.person,
              color: ShadTheme.of(context).colorScheme.mutedForeground,
              size: 20,
            ),
            keyboardType: TextInputType.text,
            onChanged: (value) => authController.setUsername(value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入用户名';
              }
              if (value.length < 3) {
                return '用户名至少3个字符';
              }
              if (value.length > 50) {
                return '用户名最多50个字符';
              }
              // 检查用户名格式（字母、数字、下划线）
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                return '用户名只能包含字母、数字和下划线';
              }
              return null;
            },
            autoFocus: true,
          ),

          const SizedBox(height: 16),

          // 昵称输入框（可选）
          UIInput(
            controller: _nicknameController,
            labelText: '昵称（可选）',
            hintText: '请输入昵称',
            prefixIcon: Icon(
              Icons.badge,
              color: ShadTheme.of(context).colorScheme.mutedForeground,
              size: 20,
            ),
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value != null && value.length > 50) {
                return '昵称最多50个字符';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // 密码输入框
          Obx(() {
            return UIPasswordInput(
              controller: _passwordController,
              labelText: '密码',
              hintText: '请输入密码（至少6个字符）',
              onChanged: (value) => authController.setPassword(value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入密码';
                }
                if (value.length < 6) {
                  return '密码至少6个字符';
                }
                if (value.length > 128) {
                  return '密码最多128个字符';
                }
                return null;
              },
            );
          }),

          const SizedBox(height: 16),

          // 确认密码输入框
          Obx(() {
            return UIPasswordInput(
              controller: _confirmPasswordController,
              labelText: '确认密码',
              hintText: '请再次输入密码',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请确认密码';
                }
                if (value != _passwordController.text) {
                  return '两次输入的密码不一致';
                }
                return null;
              },
            );
          }),

          const SizedBox(height: 16),

          // 用户协议
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() {
                final agreed = false.obs;
                return Checkbox(
                  value: agreed.value,
                  onChanged: (value) => agreed.value = value ?? false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '我已阅读并同意',
                      style: TextStyle(
                        fontSize: 14,
                        color: ShadTheme.of(context).colorScheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Get.snackbar('用户协议', '用户协议页面开发中');
                          },
                          child: Text(
                            '《用户协议》',
                            style: TextStyle(
                              fontSize: 14,
                              color: ShadTheme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          '和',
                          style: TextStyle(
                            fontSize: 14,
                            color: ShadTheme.of(context).colorScheme.foreground,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Get.snackbar('隐私政策', '隐私政策页面开发中');
                          },
                          child: Text(
                            '《隐私政策》',
                            style: TextStyle(
                              fontSize: 14,
                              color: ShadTheme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建注册按钮
  Widget _buildRegisterButton(
    BuildContext context,
    AuthController authController,
    AuthService authService,
  ) {
    final theme = ShadTheme.of(context);

    return Obx(() {
      final isLoading = authService.isLoading.value;

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
                    // 检查是否同意协议
                    // 这里应该检查实际的同意状态，暂时跳过

                    // 更新控制器中的用户名和密码
                    authController.setUsername(_usernameController.text);
                    authController.setPassword(_passwordController.text);

                    // 执行注册
                    final response = await authService.register(
                      _usernameController.text,
                      _passwordController.text,
                      nickname: _nicknameController.text.isNotEmpty
                          ? _nicknameController.text
                          : null,
                    );

                    if (response.success) {
                      // 注册成功，清空表单
                      _usernameController.clear();
                      _passwordController.clear();
                      _confirmPasswordController.clear();
                      _nicknameController.clear();
                      authController.clearForm();

                      // 显示成功消息
                      Get.snackbar(
                        '注册成功',
                        '账户创建成功，请登录',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        borderRadius: 8,
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 3),
                      );

                      // 延迟返回登录页面
                      Future.delayed(const Duration(milliseconds: 1500), () {
                        Get.back();
                      });
                    } else if (response.error != null) {
                      // 使用UI组件库的Snackbar显示错误
                      Get.snackbar(
                        '注册失败',
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
                const Icon(Icons.person_add, size: 20),
              const SizedBox(width: 8),
              Text(isLoading ? '注册中...' : '注册账户'),
            ],
          ),
        ),
      );
    });
  }

  /// 构建登录链接
  Widget _buildLoginLink(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '已有账户？',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.mutedForeground,
          ),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () {
            Get.back();
          },
          child: Text(
            '立即登录',
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

  /// 清理资源
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
  }
}
