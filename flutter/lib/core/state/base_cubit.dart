import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

/// 基础状态基类
abstract class BaseState extends Equatable {
  const BaseState();

  @override
  List<Object?> get props => [];
}

/// 加载状态
class LoadingState extends BaseState {
  const LoadingState();
}

/// 错误状态
class ErrorState extends BaseState {
  final String message;
  final dynamic error;

  const ErrorState(this.message, [this.error]);

  @override
  List<Object?> get props => [message, error];
}

/// 成功状态
class SuccessState extends BaseState {
  const SuccessState();
}

/// 空状态
class EmptyState extends BaseState {
  const EmptyState();
}

/// 基础Cubit类，提供通用的状态管理功能
abstract class BaseCubit<T extends BaseState> extends Cubit<T> {
  BaseCubit(super.initialState);

  /// 处理异步操作，自动管理加载和错误状态
  Future<void> handleAsyncOperation(
    Future<void> Function() operation, {
    T? loadingState,
    T? successState,
    T? errorState,
  }) async {
    try {
      // 发出加载状态
      if (loadingState != null) {
        emit(loadingState);
      }

      // 执行操作
      await operation();

      // 发出成功状态
      if (successState != null) {
        emit(successState);
      }
    } catch (e) {
      // 发出错误状态
      if (errorState != null) {
        emit(errorState);
      } else {
        // 如果没有提供错误状态，创建一个默认的
        emit(_createErrorState(e) as T);
      }
    }
  }

  /// 创建错误状态（子类可以重写）
  BaseState _createErrorState(dynamic error) {
    return ErrorState(error is Exception ? error.toString() : '发生未知错误', error);
  }

  /// 安全地发出状态
  void safeEmit(T state) {
    if (!isClosed) {
      emit(state);
    }
  }
}
