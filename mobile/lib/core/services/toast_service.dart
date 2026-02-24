import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../config/app_config.dart';

/// Toast消息类型
enum ToastType { success, error, warning, info }

/// Toast消息数据
class ToastMessage {
  final String message;
  final ToastType type;
  final Duration duration;
  final IconData? icon;

  const ToastMessage({
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 3),
    this.icon,
  });

  Color get backgroundColor {
    switch (type) {
      case ToastType.success:
        return Colors.green;
      case ToastType.error:
        return Colors.red;
      case ToastType.warning:
        return Colors.orange;
      case ToastType.info:
        return Colors.blue;
    }
  }

  Color get textColor => Colors.white;

  IconData get defaultIcon {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.error:
        return Icons.error;
      case ToastType.warning:
        return Icons.warning;
      case ToastType.info:
        return Icons.info;
    }
  }
}

/// Toast服务状态
class ToastState {
  final List<ToastMessage> messages;

  const ToastState({this.messages = const []});

  ToastState copyWith({List<ToastMessage>? messages}) {
    return ToastState(messages: messages ?? this.messages);
  }
}

/// Toast服务
class ToastService extends Notifier<ToastState> {
  @override
  ToastState build() {
    return const ToastState();
  }

  /// 添加调试日志
  void _log(String message) {
    if (AppConfig.debugMode) {
      debugPrint('[ToastService] $message');
    }
  }

  /// 显示成功消息
  void success(String message, {Duration? duration, IconData? icon}) {
    _log('显示成功消息: $message');
    _show(
      ToastMessage(
        message: message,
        type: ToastType.success,
        duration: duration ?? const Duration(seconds: 3),
        icon: icon,
      ),
    );
  }

  /// 显示错误消息
  void error(String message, {Duration? duration, IconData? icon}) {
    _log('显示错误消息: $message');
    _show(
      ToastMessage(
        message: message,
        type: ToastType.error,
        duration: duration ?? const Duration(seconds: 4),
        icon: icon,
      ),
    );
  }

  /// 显示警告消息
  void warning(String message, {Duration? duration, IconData? icon}) {
    _log('显示警告消息: $message');
    _show(
      ToastMessage(
        message: message,
        type: ToastType.warning,
        duration: duration ?? const Duration(seconds: 3),
        icon: icon,
      ),
    );
  }

  /// 显示信息消息
  void info(String message, {Duration? duration, IconData? icon}) {
    _log('显示信息消息: $message');
    _show(
      ToastMessage(
        message: message,
        type: ToastType.info,
        duration: duration ?? const Duration(seconds: 3),
        icon: icon,
      ),
    );
  }

  /// 显示Toast消息
  void _show(ToastMessage message) {
    _log(
      '添加Toast消息: ${message.message}, 类型: ${message.type}, 当前消息数: ${state.messages.length}',
    );

    // 添加新消息
    state = ToastState(messages: [...state.messages, message]);
    _log('添加后消息数: ${state.messages.length}');

    // 自动移除消息
    Future.delayed(message.duration, () {
      _remove(message);
    });
  }

  /// 移除消息
  void _remove(ToastMessage message) {
    _log('尝试移除消息: ${message.message}');
    if (state.messages.contains(message)) {
      final newMessages = List<ToastMessage>.from(state.messages)
        ..remove(message);
      state = ToastState(messages: newMessages);
      _log('移除成功，剩余消息数: ${state.messages.length}');
    } else {
      _log('消息不存在，无需移除');
    }
  }

  /// 清除所有消息
  void clear() {
    _log('清除所有消息，当前消息数: ${state.messages.length}');
    state = const ToastState();
  }
}

/// Toast服务提供者
final toastServiceProvider = NotifierProvider<ToastService, ToastState>(
  ToastService.new,
);

/// Toast容器Widget
class ToastContainer extends StatelessWidget {
  const ToastContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Consumer(
        builder: (context, ref, child) {
          final messages = ref.watch(toastServiceProvider).messages;
          if (messages.isEmpty) return const SizedBox.shrink();

          return Column(
            children: messages.map((message) {
              return _ToastWidget(message: message);
            }).toList(),
          );
        },
      ),
    );
  }
}

/// 单个Toast Widget
class _ToastWidget extends StatelessWidget {
  final ToastMessage message;

  const _ToastWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: message.backgroundColor,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                message.icon ?? message.defaultIcon,
                color: message.textColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message.message,
                  style: TextStyle(
                    color: message.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toast工具类
class ToastUtils {
  /// 显示成功消息
  static void showSuccess(
    WidgetRef ref,
    String message, {
    Duration? duration,
    IconData? icon,
  }) {
    final toastService = ref.read(toastServiceProvider.notifier);
    toastService.success(message, duration: duration, icon: icon);
  }

  /// 显示错误消息
  static void showError(
    WidgetRef ref,
    String message, {
    Duration? duration,
    IconData? icon,
  }) {
    final toastService = ref.read(toastServiceProvider.notifier);
    toastService.error(message, duration: duration, icon: icon);
  }

  /// 显示警告消息
  static void showWarning(
    WidgetRef ref,
    String message, {
    Duration? duration,
    IconData? icon,
  }) {
    final toastService = ref.read(toastServiceProvider.notifier);
    toastService.warning(message, duration: duration, icon: icon);
  }

  /// 显示信息消息
  static void showInfo(
    WidgetRef ref,
    String message, {
    Duration? duration,
    IconData? icon,
  }) {
    final toastService = ref.read(toastServiceProvider.notifier);
    toastService.info(message, duration: duration, icon: icon);
  }
}
