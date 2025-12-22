/// 认证守卫
/// 处理登录状态检查和自动跳转
library;

import 'package:flutter/material.dart';
import '../core.dart';

/// 认证状态检查器
class AuthChecker {
  final AuthService _authService;

  AuthChecker() : _authService = getIt<AuthService>();

  /// 检查认证状态
  Future<AuthCheckResult> checkAuthStatus() async {
    try {
      final isAuthenticated = _authService.isAuthenticated();
      final isAdmin = await _authService.isAdmin();

      return AuthCheckResult(
        isAuthenticated: isAuthenticated,
        isAdmin: isAdmin,
        error: null,
      );
    } catch (e) {
      Logger.error('检查认证状态失败', e);
      return AuthCheckResult(
        isAuthenticated: false,
        isAdmin: false,
        error: e.toString(),
      );
    }
  }

  /// 检查管理员权限
  Future<AuthCheckResult> checkAdminAccess() async {
    try {
      final result = await _authService.validateAdminAccess();
      return AuthCheckResult(
        isAuthenticated: result.success,
        isAdmin: result.success,
        error: result.success ? null : result.message,
      );
    } catch (e) {
      Logger.error('检查管理员权限失败', e);
      return AuthCheckResult(
        isAuthenticated: false,
        isAdmin: false,
        error: e.toString(),
      );
    }
  }
}

/// 认证检查结果
class AuthCheckResult {
  final bool isAuthenticated;
  final bool isAdmin;
  final String? error;

  const AuthCheckResult({
    required this.isAuthenticated,
    required this.isAdmin,
    this.error,
  });

  bool get hasError => error != null;
  bool get canAccessAdmin => isAuthenticated && isAdmin;
}

/// 认证守卫Widget
class AuthGuardWidget extends StatefulWidget {
  final Widget Function(BuildContext context, AuthCheckResult result) builder;
  final bool requireAdmin;
  final VoidCallback? onAuthRequired;
  final VoidCallback? onAdminRequired;

  const AuthGuardWidget({
    super.key,
    required this.builder,
    this.requireAdmin = false,
    this.onAuthRequired,
    this.onAdminRequired,
  });

  @override
  State<AuthGuardWidget> createState() => _AuthGuardWidgetState();
}

class _AuthGuardWidgetState extends State<AuthGuardWidget> {
  late final AuthChecker _authChecker;
  AuthCheckResult? _result;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authChecker = AuthChecker();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final result = widget.requireAdmin
          ? await _authChecker.checkAdminAccess()
          : await _authChecker.checkAuthStatus();

      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });

        // 处理认证失败的情况
        if (!result.isAuthenticated && widget.onAuthRequired != null) {
          widget.onAuthRequired!();
        } else if (widget.requireAdmin &&
            !result.isAdmin &&
            widget.onAdminRequired != null) {
          widget.onAdminRequired!();
        }
      }
    } catch (e) {
      Logger.error('认证检查失败', e);
      if (mounted) {
        setState(() {
          _result = AuthCheckResult(
            isAuthenticated: false,
            isAdmin: false,
            error: e.toString(),
          );
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_result == null) {
      return const Scaffold(body: Center(child: Text('认证检查失败')));
    }

    return widget.builder(context, _result!);
  }
}
