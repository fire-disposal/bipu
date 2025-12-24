import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openapi/openapi.dart';
import '../../core/injection/service_locator.dart';

/// 用户管理状态
class UserManagementState {
  final List<UserResponse> users;
  final bool loading;
  final String? error;

  const UserManagementState({
    this.users = const [],
    this.loading = false,
    this.error,
  });

  UserManagementState copyWith({
    List<UserResponse>? users,
    bool? loading,
    String? error,
  }) {
    return UserManagementState(
      users: users ?? this.users,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}

/// 用户管理Cubit
class UserManagementCubit extends Cubit<UserManagementState> {
  final UsersApi _api;

  UserManagementCubit({UsersApi? api})
    : _api = api ?? ServiceLocatorConfig.get<Openapi>().getUsersApi(),
      super(const UserManagementState());

  /// 加载用户列表
  Future<void> loadUsers({bool? isActive, bool? isSuperuser}) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final params = <String, dynamic>{};
      if (isActive != null) params['is_active'] = isActive;
      if (isSuperuser != null) params['is_superuser'] = isSuperuser;
      final res = await _api.adminGetAllUsersApiUsersAdminAllGet(
        skip: 0,
        limit: 100,
        isActive: params['is_active'],
        isSuperuser: params['is_superuser'],
      );
      final users = (res.data as List<UserResponse>? ?? []);
      emit(state.copyWith(users: users, loading: false));
    } catch (e) {
      emit(state.copyWith(error: '用户获取失败: $e', loading: false));
    }
  }

  /// 新增用户
  Future<void> createUser({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      await _api.registerUserApiUsersRegisterPost(
        userCreate: UserCreate(
          (b) => b
            ..username = username
            ..email = email
            ..password = password,
        ),
      );
      await loadUsers();
    } catch (e) {
      emit(state.copyWith(error: '新增用户失败: $e'));
    }
  }

  /// 更新用户
  Future<void> updateUser({
    required int userId,
    String? username,
    String? email,
    bool? isActive,
  }) async {
    try {
      await _api.updateUserApiUsersUserIdPut(
        userId: userId,
        userUpdate: UserUpdate(
          (b) => b
            ..username = username
            ..email = email
            ..isActive = isActive,
        ),
      );
      await loadUsers();
    } catch (e) {
      emit(state.copyWith(error: '更新用户失败: $e'));
    }
  }

  /// 删除用户
  Future<void> deleteUser(int userId) async {
    try {
      await _api.deleteUserApiUsersUserIdDelete(userId: userId);
      await loadUsers();
    } catch (e) {
      emit(state.copyWith(error: '删除用户失败: $e'));
    }
  }
}
