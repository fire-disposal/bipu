import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

/// 基础状态类
abstract class BaseState extends Equatable {
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const BaseState({this.isLoading = false, this.error, this.lastUpdated});

  @override
  List<Object?> get props => [isLoading, error, lastUpdated];

  /// 是否有错误
  bool get hasError => error != null;

  /// 是否成功状态（无加载，无错误）
  bool get isSuccess => !isLoading && !hasError;
}

/// 基础事件类
abstract class BaseEvent extends Equatable {
  const BaseEvent();

  @override
  List<Object?> get props => [];
}

/// 基础Bloc类，提供通用功能
abstract class BaseBloc<Event extends BaseEvent, State extends BaseState>
    extends Bloc<Event, State> {
  BaseBloc(super.initialState) {
    // 添加全局错误处理
    on<Event>(_handleError, transformer: _errorTransformer());
  }

  /// 错误处理变换器
  EventTransformer<T> _errorTransformer<T>() {
    return (events, mapper) =>
        events.asyncExpand(mapper).handleError((error, stackTrace) {
          debugPrint('Bloc Error: $error');
          debugPrint('Stack Trace: $stackTrace');
          // 可以在这里添加错误上报逻辑
        });
  }

  /// 通用错误处理
  void _handleError(Event event, Emitter<State> emit) {
    // 子类可以重写此方法来处理特定错误
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

/// 可刷新状态的Mixin
mixin RefreshableStateMixin<T> on BaseState {
  bool get isRefreshing;
  DateTime? get lastRefresh;

  /// 数据是否过期（默认5分钟）
  bool get isDataStale {
    if (lastRefresh == null) return true;
    return DateTime.now().difference(lastRefresh!) > const Duration(minutes: 5);
  }
}

/// 分页状态的Mixin
mixin PaginationStateMixin<T> on BaseState {
  List<T> get items;
  bool get hasMore;
  int get currentPage;
  bool get isLoadingMore;

  /// 是否为首页
  bool get isFirstPage => currentPage <= 1;

  /// 总项目数
  int get totalItems => items.length;
}

/// 搜索状态的Mixin
mixin SearchableStateMixin on BaseState {
  String get searchQuery;
  bool get isSearching;

  /// 是否有搜索查询
  bool get hasSearchQuery => searchQuery.isNotEmpty;
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

  /// 批量状态更新
  static void batchUpdate(List<VoidCallback> updates) {
    for (final update in updates) {
      update();
    }
  }
}

/// 全局状态监听器
class GlobalStateListener {
  static final List<void Function(dynamic state)> _listeners = [];

  static void addListener(void Function(dynamic state) listener) {
    _listeners.add(listener);
  }

  static void removeListener(void Function(dynamic state) listener) {
    _listeners.remove(listener);
  }

  static void notifyAll(dynamic state) {
    for (final listener in _listeners) {
      try {
        listener(state);
      } catch (error) {
        debugPrint('GlobalStateListener Error: $error');
      }
    }
  }
}

/// 性能监控Mixin
mixin PerformanceMonitorMixin<Event extends BaseEvent, State extends BaseState>
    on BaseBloc<Event, State> {
  final Map<Type, DateTime> _eventTimestamps = {};
  final Map<Type, int> _eventCounts = {};

  @override
  void add(Event event) {
    _trackEvent(event);
    super.add(event);
  }

  void _trackEvent(Event event) {
    final eventType = event.runtimeType;
    final now = DateTime.now();

    _eventTimestamps[eventType] = now;
    _eventCounts[eventType] = (_eventCounts[eventType] ?? 0) + 1;

    // 检测频繁事件
    if (_eventCounts[eventType]! > 10) {
      debugPrint(
        'Warning: Event $eventType triggered ${_eventCounts[eventType]} times',
      );
    }
  }

  /// 获取性能统计
  Map<String, dynamic> getPerformanceStats() {
    return {
      'eventCounts': Map.from(_eventCounts),
      'lastEventTimestamps': _eventTimestamps.map(
        (key, value) => MapEntry(key.toString(), value.toIso8601String()),
      ),
    };
  }
}
