import 'package:flutter/material.dart';
import 'toast_service.dart';

/// SnackBar 管理器 - 统一管理应用内所有 SnackBar 显示
/// 提供便捷的静态方法调用，避免重复代码
class SnackBarManager {
  static final SnackBarManager _instance = SnackBarManager._internal();

  factory SnackBarManager() {
    return _instance;
  }

  SnackBarManager._internal();

  final ToastService _toastService = ToastService();

  // ============ 成功提示 ============

  /// 显示成功提示
  static void showSuccess(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _instance._toastService.showSuccess(message, duration: duration);
  }

  /// 显示操作成功提示
  static void showOperationSuccess(String operationName) {
    showSuccess('$operationName 成功');
  }

  /// 显示保存成功提示
  static void showSaveSuccess() {
    showSuccess('保存成功');
  }

  /// 显示删除成功提示
  static void showDeleteSuccess() {
    showSuccess('删除成功');
  }

  /// 显示更新成功提示
  static void showUpdateSuccess() {
    showSuccess('更新成功');
  }

  // ============ 错误提示 ============

  /// 显示错误提示
  static void showError(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _instance._toastService.showError(message, duration: duration);
  }

  /// 显示操作失败提示
  static void showOperationFailed(String operationName, [String? reason]) {
    final message = reason != null
        ? '$operationName 失败: $reason'
        : '$operationName 失败';
    showError(message);
  }

  /// 显示网络错误提示
  static void showNetworkError([String? message]) {
    showError(message ?? '网络连接失败，请检查网络设置');
  }

  /// 显示服务器错误提示
  static void showServerError([String? message]) {
    showError(message ?? '服务器错误，请稍后重试');
  }

  /// 显示验证错误提示
  static void showValidationError(String fieldName) {
    showError('$fieldName 不能为空');
  }

  // ============ 信息提示 ============

  /// 显示信息提示
  static void showInfo(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _instance._toastService.showInfo(message, duration: duration);
  }

  /// 显示加载中提示
  static void showLoading(String message) {
    showInfo(message);
  }

  /// 显示处理中提示
  static void showProcessing(String message) {
    showInfo('$message 中...');
  }

  // ============ 警告提示 ============

  /// 显示警告提示
  static void showWarning(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _instance._toastService.showWarning(message, duration: duration);
  }

  /// 显示权限警告提示
  static void showPermissionWarning(String permissionName) {
    showWarning('需要 $permissionName 权限');
  }

  /// 显示输入警告提示
  static void showInputWarning(String message) {
    showWarning(message);
  }

  // ============ 消息提示 ============

  /// 显示新消息提示
  static void showNewMessage(
    String message, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    _instance._toastService.showMessage(
      message,
      duration: duration,
      onTap: onTap,
    );
  }

  /// 显示消息接收提示
  static void showMessageReceived(String senderName, String preview) {
    showNewMessage('$senderName: $preview');
  }

  /// 显示多条消息提示
  static void showMultipleMessages(int count) {
    showNewMessage('收到 $count 条新消息');
  }

  // ============ 通用方法 ============

  /// 清除当前 SnackBar
  static void dismiss() {
    _instance._toastService.dismiss();
  }

  /// 获取 ToastService 实例（用于高级用法）
  static ToastService get toastService => _instance._toastService;
}
