/// 统一应用状态管理架构
/// 提供一致的状态模式和工具方法
library;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core.dart';

/// 应用基础状态接口
abstract class AppState extends Equatable {
  const AppState();

  @override
  List<Object?> get props => [];
}

/// 空状态
class EmptyState extends AppState {
  const EmptyState();
}

/// 加载中状态
class LoadingState extends AppState {
  const LoadingState();
}

/// 错误状态
class ErrorState extends AppState {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  const ErrorState(this.message, [this.error, this.stackTrace]);

  @override
  List<Object?> get props => [message, error, stackTrace];
}

/// 成功状态
class SuccessState extends AppState {
  const SuccessState();
}

/// 带数据的成功状态
class DataState<T> extends AppState {
  final T data;

  const DataState(this.data);

  @override
  List<Object?> get props => [data];
}

/// 列表状态
class ListState<T> extends AppState {
  final List<T> items;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasMore;

  const ListState({
    required this.items,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [
    items,
    isLoading,
    error,
    currentPage,
    totalPages,
    totalItems,
    hasMore,
  ];

  ListState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? hasMore,
  }) {
    return ListState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// 表单状态
class FormState extends AppState {
  final bool isSubmitting;
  final String? error;
  final bool isValid;
  final Map<String, dynamic>? formData;

  const FormState({
    this.isSubmitting = false,
    this.error,
    this.isValid = true,
    this.formData,
  });

  @override
  List<Object?> get props => [isSubmitting, error, isValid, formData];

  FormState copyWith({
    bool? isSubmitting,
    String? error,
    bool? isValid,
    Map<String, dynamic>? formData,
  }) {
    return FormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error ?? this.error,
      isValid: isValid ?? this.isValid,
      formData: formData ?? this.formData,
    );
  }
}

/// 统一的Cubit基类
abstract class AppCubit<T extends AppState> extends Cubit<T> {
  AppCubit(T initialState) : super(initialState);

  /// 处理异步操作的标准化方法
  Future<void> handleAsyncOperation({
    required Future<void> Function() operation,
    required T Function() loadingStateBuilder,
    required T Function() successStateBuilder,
    required T Function(String error) errorStateBuilder,
    String operationName = '操作',
    bool emitLoading = true,
  }) async {
    try {
      if (emitLoading) {
        emit(loadingStateBuilder());
      }
      await operation();
      emit(successStateBuilder());
    } catch (e, stackTrace) {
      final errorMessage = _handleError(e, operationName);
      Logger.error('$operationName 失败: $errorMessage', e, stackTrace);
      emit(errorStateBuilder(errorMessage));
    }
  }

  /// 统一的错误处理
  String _handleError(dynamic error, String operation) {
    if (error is ApiException) {
      return error.message;
    } else if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    } else if (error is Error) {
      return error.toString().replaceAll('Error: ', '');
    } else if (error is String) {
      return error;
    } else {
      return '$operation失败: $error';
    }
  }

  /// 检查是否处于加载状态
  bool get isLoading {
    final currentState = state;
    if (currentState is LoadingState) return true;
    if (currentState is ListState) return currentState.isLoading;
    if (currentState is FormState) return currentState.isSubmitting;
    return false;
  }

  /// 检查是否处于错误状态
  bool get hasError {
    final currentState = state;
    if (currentState is ErrorState) return true;
    if (currentState is ListState) return currentState.error != null;
    if (currentState is FormState) return currentState.error != null;
    return false;
  }

  /// 获取错误信息
  String? get errorMessage {
    final currentState = state;
    if (currentState is ErrorState) return currentState.message;
    if (currentState is ListState) return currentState.error;
    if (currentState is FormState) return currentState.error;
    return null;
  }
}

/// 列表数据Cubit基类
abstract class ListCubit<T> extends AppCubit<ListState<T>> {
  ListCubit() : super(ListState<T>(items: []));

  /// 加载数据
  Future<void> loadData({
    int page = 1,
    int pageSize = 20,
    Map<String, dynamic>? filters,
    bool refresh = false,
  });

  /// 刷新数据
  Future<void> refreshData() async {
    await loadData(page: 1, refresh: true);
  }

  /// 加载更多数据
  Future<void> loadMoreData() async {
    final currentState = state;
    if (currentState.hasMore && !currentState.isLoading) {
      await loadData(page: currentState.currentPage + 1);
    }
  }

  /// 添加项目
  void addItem(T item) {
    final currentState = state;
    final updatedItems = List<T>.from(currentState.items)..add(item);
    emit(
      currentState.copyWith(
        items: updatedItems,
        totalItems: currentState.totalItems + 1,
      ),
    );
  }

  /// 更新项目
  void updateItem(bool Function(T) predicate, T updatedItem) {
    final currentState = state;
    final updatedItems = currentState.items.map((item) {
      return predicate(item) ? updatedItem : item;
    }).toList();
    emit(currentState.copyWith(items: updatedItems));
  }

  /// 删除项目
  void removeItem(bool Function(T) predicate) {
    final currentState = state;
    final updatedItems = currentState.items
        .where((item) => !predicate(item))
        .toList();
    emit(
      currentState.copyWith(
        items: updatedItems,
        totalItems: currentState.totalItems - 1,
      ),
    );
  }

  /// 清空数据
  void clearData() {
    emit(ListState<T>(items: []));
  }
}

/// 表单Cubit基类
abstract class FormCubit extends AppCubit<FormState> {
  FormCubit() : super(const FormState());

  /// 验证表单
  bool validate();

  /// 提交表单
  Future<void> submit() async {
    if (!validate()) {
      emit(state.copyWith(error: '表单验证失败', isValid: false));
      return;
    }

    await handleAsyncOperation(
      operation: _doSubmit,
      loadingStateBuilder: () =>
          state.copyWith(isSubmitting: true, error: null),
      successStateBuilder: () => const FormState(),
      errorStateBuilder: (error) =>
          state.copyWith(error: error, isSubmitting: false),
      operationName: '表单提交',
      emitLoading: false,
    );
  }

  /// 实际的提交逻辑
  Future<void> _doSubmit() async {
    await doSubmit();
  }

  /// 子类需要实现的提交逻辑
  Future<void> doSubmit();

  /// 重置表单
  void reset() {
    emit(const FormState());
  }

  /// 更新表单数据
  void updateFormData(Map<String, dynamic> data) {
    final currentFormData = Map<String, dynamic>.from(state.formData ?? {});
    currentFormData.addAll(data);
    emit(state.copyWith(formData: currentFormData));
  }

  /// 设置错误状态
  void setError(String error) {
    emit(state.copyWith(error: error, isValid: false));
  }

  /// 清除错误
  void clearError() {
    emit(state.copyWith(error: null));
  }
}
