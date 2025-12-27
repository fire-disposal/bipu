/// 管理端通用Cubit基类
/// 统一管理员界面的状态管理逻辑
library;

import '../../core/core.dart';
import '../../core/state/state.dart';

/// 管理端列表状态
class AdminListState<T> extends ListState<T> {
  final String? searchQuery;
  final Map<String, dynamic> filters;

  const AdminListState({
    required super.items,
    super.isLoading = false,
    super.error,
    super.currentPage = 1,
    super.totalPages = 1,
    super.totalItems = 0,
    super.hasMore = false,
    this.searchQuery,
    this.filters = const {},
  });

  @override
  List<Object?> get props => [...super.props, searchQuery, filters];

  @override
  AdminListState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? hasMore,
    String? searchQuery,
    Map<String, dynamic>? filters,
  }) {
    return AdminListState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
    );
  }
}

/// 管理端列表Cubit基类
abstract class AdminListCubit<T> extends AppCubit<AdminListState<T>> {
  AdminListCubit() : super(AdminListState<T>(items: []));

  /// 搜索查询
  String? get searchQuery => state.searchQuery;

  /// 当前过滤器
  Map<String, dynamic> get filters => state.filters;

  /// 加载数据（带搜索和过滤）
  Future<void> loadData({
    int page = 1,
    int pageSize = 20,
    String? searchQuery,
    Map<String, dynamic>? filters,
    bool refresh = false,
  }) async {
    try {
      // 更新搜索和过滤条件
      emit(
        state.copyWith(
          isLoading: true,
          error: null,
          searchQuery: searchQuery ?? this.searchQuery,
          filters: filters ?? this.filters,
        ),
      );

      // 调用子类实现的获取数据方法
      final result = await fetchData(
        page: page,
        pageSize: pageSize,
        searchQuery: searchQuery ?? this.searchQuery,
        filters: filters ?? this.filters,
      );

      emit(
        AdminListState<T>(
          items: result.items,
          currentPage: page,
          totalPages: result.totalPages,
          totalItems: result.totalItems,
          hasMore: page < result.totalPages,
          searchQuery: searchQuery ?? this.searchQuery,
          filters: filters ?? this.filters,
        ),
      );
    } catch (e) {
      final errorMessage = (e is Exception) ? e.toString() : '加载数据失败: $e';
      Logger.error('加载数据失败', e);
      emit(state.copyWith(error: errorMessage, isLoading: false));
    }
  }

  /// 子类必须实现的数据获取方法
  Future<FetchResult<T>> fetchData({
    required int page,
    required int pageSize,
    String? searchQuery,
    Map<String, dynamic>? filters,
  });

  /// 搜索数据
  Future<void> search(String query) async {
    await loadData(searchQuery: query, page: 1);
  }

  /// 应用过滤器
  Future<void> applyFilters(Map<String, dynamic> filters) async {
    await loadData(filters: filters, page: 1);
  }

  /// 刷新数据
  Future<void> refreshData() async {
    await loadData(page: 1, refresh: true);
  }

  /// 加载更多数据
  Future<void> loadMoreData() async {
    if (state.hasMore && !state.isLoading) {
      await loadData(page: state.currentPage + 1);
    }
  }

  /// 添加项目
  void addItem(T item) {
    final updatedItems = List<T>.from(state.items)..add(item);
    emit(state.copyWith(items: updatedItems, totalItems: state.totalItems + 1));
  }

  /// 更新项目
  void updateItem(bool Function(T) predicate, T updatedItem) {
    final updatedItems = state.items.map((item) {
      return predicate(item) ? updatedItem : item;
    }).toList();
    emit(state.copyWith(items: updatedItems));
  }

  /// 删除项目
  void removeItem(bool Function(T) predicate) {
    final updatedItems = state.items.where((item) => !predicate(item)).toList();
    emit(state.copyWith(items: updatedItems, totalItems: state.totalItems - 1));
  }

  /// 清空数据
  void clearData() {
    emit(AdminListState<T>(items: []));
  }
}

/// 数据获取结果
class FetchResult<T> {
  final List<T> items;
  final int totalPages;
  final int totalItems;

  const FetchResult({
    required this.items,
    required this.totalPages,
    required this.totalItems,
  });
}

/// 管理端表单状态
class AdminFormState extends FormState {
  final bool isCreating;
  final dynamic editingItem;

  const AdminFormState({
    super.isSubmitting,
    super.error,
    super.isValid,
    super.formData,
    this.isCreating = true,
    this.editingItem,
  });

  @override
  List<Object?> get props => [...super.props, isCreating, editingItem];

  @override
  AdminFormState copyWith({
    bool? isSubmitting,
    String? error,
    bool? isValid,
    Map<String, dynamic>? formData,
    bool? isCreating,
    dynamic editingItem,
  }) {
    return AdminFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error ?? this.error,
      isValid: isValid ?? this.isValid,
      formData: formData ?? this.formData,
      isCreating: isCreating ?? this.isCreating,
      editingItem: editingItem ?? this.editingItem,
    );
  }
}

/// 管理端表单Cubit基类
abstract class AdminFormCubit<T> extends AppCubit<AdminFormState> {
  AdminFormCubit() : super(const AdminFormState());

  /// 创建新项目
  Future<void> createItem(Map<String, dynamic> formData) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        error: null,
        isCreating: true,
        formData: formData,
      ),
    );

    try {
      await handleAsyncOperation(
        operation: () => doCreate(formData),
        loadingStateBuilder: () => state.copyWith(isSubmitting: true),
        successStateBuilder: () => const AdminFormState(),
        errorStateBuilder: (error) =>
            state.copyWith(error: error, isSubmitting: false),
        operationName: '创建项目',
        emitLoading: false,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isSubmitting: false));
    }
  }

  /// 更新项目
  Future<void> updateItem(T item, Map<String, dynamic> formData) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        error: null,
        isCreating: false,
        editingItem: item,
        formData: formData,
      ),
    );

    try {
      await handleAsyncOperation(
        operation: () => doUpdate(item, formData),
        loadingStateBuilder: () => state.copyWith(isSubmitting: true),
        successStateBuilder: () => const AdminFormState(),
        errorStateBuilder: (error) =>
            state.copyWith(error: error, isSubmitting: false),
        operationName: '更新项目',
        emitLoading: false,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isSubmitting: false));
    }
  }

  /// 删除项目
  Future<void> deleteItem(T item) async {
    emit(state.copyWith(isSubmitting: true, error: null));

    try {
      await handleAsyncOperation(
        operation: () => doDelete(item),
        loadingStateBuilder: () => state.copyWith(isSubmitting: true),
        successStateBuilder: () => const AdminFormState(),
        errorStateBuilder: (error) =>
            state.copyWith(error: error, isSubmitting: false),
        operationName: '删除项目',
        emitLoading: false,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isSubmitting: false));
    }
  }

  /// 子类必须实现的创建方法
  Future<void> doCreate(Map<String, dynamic> formData);

  /// 子类必须实现的更新方法
  Future<void> doUpdate(T item, Map<String, dynamic> formData);

  /// 子类必须实现的删除方法
  Future<void> doDelete(T item);

  /// 验证表单数据
  @override
  bool validate() {
    // 基础验证：检查必填字段
    final formData = state.formData ?? {};
    return formData.isNotEmpty;
  }

  /// 重置表单
  @override
  void reset() {
    emit(const AdminFormState());
  }

  /// 设置编辑项目
  void setEditingItem(T? item) {
    emit(state.copyWith(editingItem: item, isCreating: item == null));
  }
}

/// 管理端登录状态
class AdminLoginState extends FormState {
  final bool isLoggedIn;
  final bool isAdmin;

  const AdminLoginState({
    super.isSubmitting,
    super.error,
    super.isValid,
    this.isLoggedIn = false,
    this.isAdmin = false,
  });

  @override
  List<Object?> get props => [...super.props, isLoggedIn, isAdmin];

  @override
  AdminLoginState copyWith({
    bool? isSubmitting,
    String? error,
    bool? isValid,
    bool? isLoggedIn,
    bool? isAdmin,
    Map<String, dynamic>? formData,
  }) {
    return AdminLoginState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error ?? this.error,
      isValid: isValid ?? this.isValid,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}

/// 管理端登录Cubit基类
abstract class AdminLoginCubit extends AppCubit<AdminLoginState> {
  final AuthService _authService;

  AdminLoginCubit({AuthService? authService})
    : _authService = authService ?? ServiceLocatorConfig.get<AuthService>(),
      super(const AdminLoginState());

  /// 管理员登录
  Future<void> adminLogin({
    required String username,
    required String password,
  }) async {
    emit(state.copyWith(isSubmitting: true, error: null));

    try {
      // 普通用户登录
      final loginResult = await _authService.login(
        username: username,
        password: password,
      );

      if (!loginResult.success) {
        emit(
          state.copyWith(
            isSubmitting: false,
            error: loginResult.message ?? '登录失败，请检查用户名和密码',
          ),
        );
        return;
      }

      // 验证管理员权限
      final adminValidation = await _authService.validateAdminAccess();
      if (!adminValidation.success) {
        await _authService.logout();
        emit(
          state.copyWith(
            isSubmitting: false,
            error: adminValidation.message ?? '需要管理员权限才能访问管理端',
          ),
        );
        return;
      }

      // 登录成功
      emit(const AdminLoginState(isLoggedIn: true, isAdmin: true));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: '登录异常: $e'));
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      await _authService.logout();
      emit(const AdminLoginState());
    } catch (e) {
      emit(state.copyWith(error: '登出失败: $e'));
    }
  }

  /// 检查登录状态
  Future<void> checkLoginStatus() async {
    try {
      final isLoggedIn = _authService.isAuthenticated();
      if (isLoggedIn) {
        final adminValidation = await _authService.validateAdminAccess();
        emit(
          AdminLoginState(isLoggedIn: true, isAdmin: adminValidation.success),
        );
      } else {
        emit(const AdminLoginState());
      }
    } catch (e) {
      emit(const AdminLoginState());
    }
  }
}
