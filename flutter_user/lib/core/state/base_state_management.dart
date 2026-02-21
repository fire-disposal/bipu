import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 基础状态类（简化版，移除Equatable依赖）
abstract class BaseState {
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const BaseState({this.isLoading = false, this.error, this.lastUpdated});

  /// 是否有错误
  bool get hasError => error != null;

  /// 是否成功状态（无加载，无错误）
  bool get isSuccess => !isLoading && !hasError;

  /// 简单的相等性检查
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          error == other.error &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode => Object.hash(isLoading, error, lastUpdated);
}

/// 基础Bloc类，提供通用功能
abstract class BaseBloc<Event, State> extends Bloc<Event, State> {
  BaseBloc(super.initialState) {
    // 添加全局错误处理
    on<Event>((event, emit) {
      // 默认错误处理
      try {
        // 子类应该重写具体的事件处理
      } catch (error, stackTrace) {
        debugPrint('Bloc Error: $error');
        debugPrint('Stack Trace: $stackTrace');
      }
    });
  }

  /// 安全执行异步操作
  Future<void> safeExecute<T>(
    Future<T> Function() operation,
    void Function(T result) onSuccess,
    Emitter<State> emit, {
    State Function()? loadingState,
    State Function(String error)? errorState,
  }) async {
    try {
      if (loadingState != null) {
        emit(loadingState());
      }

      final result = await operation();
      onSuccess(result);
    } catch (error, stackTrace) {
      debugPrint('SafeExecute Error: $error');
      debugPrint('Stack Trace: $stackTrace');

      if (errorState != null) {
        emit(errorState(error.toString()));
      }
    }
  }
}

/// 状态管理工具类
class StateManager {
  /// 防抖执行器
  static Timer? _debounceTimer;

  static void debounce(
    VoidCallback action, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, action);
  }

  /// 节流执行器
  static DateTime? _lastThrottleTime;

  static void throttle(
    VoidCallback action, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final now = DateTime.now();
    if (_lastThrottleTime == null ||
        now.difference(_lastThrottleTime!) >= duration) {
      _lastThrottleTime = now;
      action();
    }
  }
}
