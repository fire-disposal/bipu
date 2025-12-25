/// 用户管理Cubit
/// 使用新的统一状态管理架构
library;

import 'package:openapi/openapi.dart';
import '../../core/core.dart';
import 'base_admin_cubit.dart';

/// 用户管理Cubit实现
class UserManagementCubit extends AdminListCubit<UserResponse> {
  final UsersApi _api;

  UserManagementCubit({UsersApi? api})
    : _api = api ?? ServiceLocatorConfig.get<Openapi>().getUsersApi(),
      super();

  @override
  Future<FetchResult<UserResponse>> fetchData({
    required int page,
    required int pageSize,
    String? searchQuery,
    Map<String, dynamic>? filters,
  }) async {
    try {
      // 构建查询参数
      final isActive = filters?['is_active'] as bool?;
      final isSuperuser = filters?['is_superuser'] as bool?;

      final response = await _api.adminGetAllUsersApiUsersAdminAllGet(
        skip: (page - 1) * pageSize,
        limit: pageSize,
        isActive: isActive,
        isSuperuser: isSuperuser,
      );

      final users = (response.data as List<UserResponse>? ?? []);

      return FetchResult<UserResponse>(
        items: users,
        totalPages: (users.length / pageSize).ceil(),
        totalItems: users.length,
      );
    } catch (e) {
      Logger.error('获取用户列表失败', e);
      rethrow;
    }
  }

  /// 创建用户
  Future<void> createUser({
    required String username,
    required String email,
    required String password,
    String? nickname,
    String? fullName,
    bool? isActive,
    bool? isSuperuser,
  }) async {
    try {
      await _api.registerUserApiUsersRegisterPost(
        userCreate: UserCreate(
          (b) => b
            ..username = username
            ..email = email
            ..password = password
            ..nickname = nickname
            ..fullName = fullName
            ..isActive = isActive ?? true
            ..isSuperuser = isSuperuser ?? false,
        ),
      );

      // 重新加载数据
      await loadData(page: 1);
    } catch (e) {
      Logger.error('创建用户失败', e);
      rethrow;
    }
  }

  /// 更新用户
  Future<void> updateUser({
    required int userId,
    String? username,
    String? email,
    String? nickname,
    String? fullName,
    bool? isActive,
    bool? isSuperuser,
  }) async {
    try {
      await _api.updateUserApiUsersUserIdPut(
        userId: userId,
        userUpdate: UserUpdate(
          (b) => b
            ..username = username
            ..email = email
            ..nickname = nickname
            ..fullName = fullName
            ..isActive = isActive
            ..isSuperuser = isSuperuser,
        ),
      );

      // 更新本地数据
      updateItem(
        (user) => user.id == userId,
        UserResponse(
          (b) => b
            ..id = userId
            ..username = username ?? ''
            ..email = email ?? ''
            ..nickname = nickname
            ..fullName = fullName
            ..isActive = isActive ?? true
            ..isSuperuser = isSuperuser ?? false
            ..createdAt = DateTime.now().toUtc(),
        ),
      );
    } catch (e) {
      Logger.error('更新用户失败', e);
      rethrow;
    }
  }

  /// 删除用户
  Future<void> deleteUser(int userId) async {
    try {
      await _api.deleteUserApiUsersUserIdDelete(userId: userId);

      // 从本地列表中删除
      removeItem((user) => user.id == userId);
    } catch (e) {
      Logger.error('删除用户失败', e);
      rethrow;
    }
  }

  /// 更新用户状态
  Future<void> updateUserStatus(int userId, bool isActive) async {
    try {
      await _api.adminUpdateUserStatusApiUsersAdminUserIdStatusPut(
        userId: userId,
        isActive: isActive,
      );

      // 更新本地数据
      updateItem(
        (user) => user.id == userId,
        UserResponse(
          (b) => b
            ..id = userId
            ..username = ''
            ..email = ''
            ..isActive = isActive
            ..createdAt = DateTime.now().toUtc(),
        ),
      );
    } catch (e) {
      Logger.error('更新用户状态失败', e);
      rethrow;
    }
  }

  /// 获取用户统计信息
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await _api.adminGetUserStatsApiUsersAdminStatsGet();
      return response.data as Map<String, dynamic>? ?? {};
    } catch (e) {
      Logger.error('获取用户统计失败', e);
      return {};
    }
  }
}
