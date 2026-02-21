import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'base_state_management.dart';

/// 应用级状态管理（合并了UiCubit功能）
class AppCubit extends Cubit<AppState> {
  AppCubit() : super(const AppState.initial());

  /// 更新主题模式
  void updateThemeMode(ThemeMode mode) {
    emit(state.copyWith(themeMode: mode));
  }

  /// 更新语言
  void updateLocale(Locale locale) {
    emit(state.copyWith(locale: locale));
  }

  /// 更新连接状态
  void updateConnectivity(bool isConnected) {
    emit(state.copyWith(isConnected: isConnected));
  }

  /// 设置应用为后台状态
  void setAppInBackground(bool inBackground) {
    emit(state.copyWith(isInBackground: inBackground));
  }

  /// 更新应用版本信息
  void updateAppInfo({String? version, String? buildNumber}) {
    emit(
      state.copyWith(
        appVersion: version ?? state.appVersion,
        buildNumber: buildNumber ?? state.buildNumber,
      ),
    );
  }

  /// 更新底部导航索引（从UiCubit迁移）
  void updateBottomNavIndex(int index) {
    emit(state.copyWith(currentBottomNavIndex: index));
  }

  /// 显示加载指示器（从UiCubit迁移）
  void showLoading({String? message}) {
    emit(state.copyWith(isLoading: true, loadingMessage: message));
  }

  /// 隐藏加载指示器（从UiCubit迁移）
  void hideLoading() {
    emit(state.copyWith(isLoading: false, loadingMessage: null));
  }

  /// 显示底部表单（从UiCubit迁移）
  void showBottomSheet({String? title}) {
    emit(state.copyWith(showBottomSheet: true, bottomSheetTitle: title));
  }

  /// 隐藏底部表单（从UiCubit迁移）
  void hideBottomSheet() {
    emit(state.copyWith(showBottomSheet: false, bottomSheetTitle: null));
  }

  /// 切换侧边栏（从UiCubit迁移）
  void toggleDrawer() {
    emit(state.copyWith(isDrawerOpen: !state.isDrawerOpen));
  }

  /// 更新搜索状态（从UiCubit迁移）
  void updateSearchState({bool? isSearching, String? searchQuery}) {
    emit(
      state.copyWith(
        isSearching: isSearching ?? state.isSearching,
        searchQuery: searchQuery ?? state.searchQuery,
      ),
    );
  }

  /// 设置键盘可见性（从UiCubit迁移）
  void setKeyboardVisible(bool visible) {
    emit(state.copyWith(isKeyboardVisible: visible));
  }
}

/// 应用状态（合并了UiState字段）
class AppState extends BaseState {
  final ThemeMode themeMode;
  final Locale locale;
  final bool isConnected;
  final bool isInBackground;
  final String appVersion;
  final String buildNumber;

  // 从UiState合并过来的字段
  final String? loadingMessage;
  final bool showBottomSheet;
  final String? bottomSheetTitle;
  final bool isDrawerOpen;
  final bool isSearching;
  final String searchQuery;
  final bool isKeyboardVisible;
  final int currentBottomNavIndex;

  const AppState({
    required this.themeMode,
    required this.locale,
    required this.isConnected,
    this.isInBackground = false,
    this.appVersion = '1.0.0',
    this.buildNumber = '1',
    // 从UiState合并的字段默认值
    this.loadingMessage,
    this.showBottomSheet = false,
    this.bottomSheetTitle,
    this.isDrawerOpen = false,
    this.isSearching = false,
    this.searchQuery = '',
    this.isKeyboardVisible = false,
    this.currentBottomNavIndex = 0,
    super.isLoading,
    super.error,
    super.lastUpdated,
  });

  const AppState.initial()
    : themeMode = ThemeMode.system,
      locale = const Locale('zh', 'CN'),
      isConnected = true,
      isInBackground = false,
      appVersion = '1.0.0',
      buildNumber = '1',
      // 从UiState合并的字段初始值
      loadingMessage = null,
      showBottomSheet = false,
      bottomSheetTitle = null,
      isDrawerOpen = false,
      isSearching = false,
      searchQuery = '',
      isKeyboardVisible = false,
      currentBottomNavIndex = 0,
      super();

  AppState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? isConnected,
    bool? isInBackground,
    String? appVersion,
    String? buildNumber,
    // 从UiState合并的字段
    String? loadingMessage,
    bool? showBottomSheet,
    String? bottomSheetTitle,
    bool? isDrawerOpen,
    bool? isSearching,
    String? searchQuery,
    bool? isKeyboardVisible,
    int? currentBottomNavIndex,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return AppState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      isConnected: isConnected ?? this.isConnected,
      isInBackground: isInBackground ?? this.isInBackground,
      appVersion: appVersion ?? this.appVersion,
      buildNumber: buildNumber ?? this.buildNumber,
      // 从UiState合并的字段
      loadingMessage: loadingMessage,
      showBottomSheet: showBottomSheet ?? this.showBottomSheet,
      bottomSheetTitle: bottomSheetTitle,
      isDrawerOpen: isDrawerOpen ?? this.isDrawerOpen,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      isKeyboardVisible: isKeyboardVisible ?? this.isKeyboardVisible,
      currentBottomNavIndex:
          currentBottomNavIndex ?? this.currentBottomNavIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppState &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          locale == other.locale &&
          isConnected == other.isConnected &&
          isInBackground == other.isInBackground &&
          appVersion == other.appVersion &&
          buildNumber == other.buildNumber &&
          // 从UiState合并的字段
          loadingMessage == other.loadingMessage &&
          showBottomSheet == other.showBottomSheet &&
          bottomSheetTitle == other.bottomSheetTitle &&
          isDrawerOpen == other.isDrawerOpen &&
          isSearching == other.isSearching &&
          searchQuery == other.searchQuery &&
          isKeyboardVisible == other.isKeyboardVisible &&
          currentBottomNavIndex == other.currentBottomNavIndex &&
          isLoading == other.isLoading &&
          error == other.error &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode => Object.hash(
    themeMode,
    locale,
    isConnected,
    isInBackground,
    appVersion,
    buildNumber,
    // 从UiState合并的字段
    loadingMessage,
    showBottomSheet,
    bottomSheetTitle,
    isDrawerOpen,
    isSearching,
    searchQuery,
    isKeyboardVisible,
    currentBottomNavIndex,
    isLoading,
    error,
    lastUpdated,
  );
}

/// 状态管理Provider（移除UiCubit）
class StateProviders {
  static final List<BlocProvider> providers = [
    BlocProvider<AppCubit>(create: (context) => AppCubit()),
  ];

  /// 获取应用状态
  static AppCubit getAppCubit(BuildContext context) {
    return BlocProvider.of<AppCubit>(context);
  }
}

/// 智能状态构建器
class SmartBlocBuilder<C extends Cubit<S>, S> extends StatelessWidget {
  final Widget Function(BuildContext context, S state) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String error)? errorBuilder;
  final bool Function(S previous, S current)? buildWhen;

  const SmartBlocBuilder({
    super.key,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.buildWhen,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<C, S>(
      buildWhen: buildWhen,
      builder: (context, state) {
        if (state is BaseState) {
          if (state.isLoading && loadingBuilder != null) {
            return loadingBuilder!(context);
          }
          if (state.hasError && errorBuilder != null) {
            return errorBuilder!(context, state.error!);
          }
        }
        return builder(context, state);
      },
    );
  }
}
