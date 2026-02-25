import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'base_service.dart';
import '../models/user_model.dart';

/// 个人资料服务 - 效仿AuthService模式
class ProfileService extends BaseService {
  static ProfileService get instance => Get.find();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  /// 获取当前用户信息
  Future<ServiceResponse<UserModel>> getCurrentUser() async {
    isLoading.value = true;
    error.value = '';

    final response = await get<UserModel>(
      '/api/profile/me',
      fromJson: (json) => UserModel.fromJson(json),
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      currentUser.value = response.data!;
      return ServiceResponse.success(response.data!);
    } else if (response.error != null) {
      error.value = response.error!.message;
    }

    return response;
  }

  /// 获取用户详细资料
  Future<ServiceResponse<UserModel>> getUserProfile() async {
    isLoading.value = true;
    error.value = '';

    final response = await get<UserModel>(
      '/api/profile/',
      fromJson: (json) => UserModel.fromJson(json),
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      return ServiceResponse.success(response.data!);
    } else if (response.error != null) {
      error.value = response.error!.message;
    }

    return response;
  }

  /// 更新用户信息
  Future<ServiceResponse<UserModel>> updateUserProfile({
    String? nickname,
    Map<String, dynamic>? cosmicProfile,
  }) async {
    isLoading.value = true;
    error.value = '';

    final response = await put<UserModel>(
      '/api/profile/',
      data: {
        if (nickname != null) 'nickname': nickname,
        if (cosmicProfile != null) 'cosmic_profile': cosmicProfile,
      },
      fromJson: (json) => UserModel.fromJson(json),
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      currentUser.value = response.data!;
      Get.snackbar('成功', '个人资料更新成功', duration: const Duration(seconds: 2));
      return ServiceResponse.success(response.data!);
    } else if (response.error != null) {
      error.value = response.error!.message;
      Get.snackbar('错误', response.error!.message);
    }

    return response;
  }

  /// 更新用户密码
  Future<ServiceResponse<Map<String, dynamic>>> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    isLoading.value = true;
    error.value = '';

    final response = await put<Map<String, dynamic>>(
      '/api/profile/password',
      data: {'old_password': oldPassword, 'new_password': newPassword},
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      Get.snackbar('成功', '密码更新成功', duration: const Duration(seconds: 2));
      return ServiceResponse.success(response.data!);
    } else if (response.error != null) {
      error.value = response.error!.message;
      Get.snackbar('错误', response.error!.message);
    }

    return response;
  }

  /// 更新用户时区
  Future<ServiceResponse<Map<String, dynamic>>> updateTimezone({
    required String timezone,
  }) async {
    isLoading.value = true;
    error.value = '';

    final response = await put<Map<String, dynamic>>(
      '/api/profile/timezone',
      data: {'timezone': timezone},
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      // 更新当前用户的时区信息
      if (currentUser.value != null) {
        final updatedUser = UserModel(
          id: currentUser.value!.id,
          username: currentUser.value!.username,
          bipupuId: currentUser.value!.bipupuId,
          nickname: currentUser.value!.nickname,
          avatarUrl: currentUser.value!.avatarUrl,
          cosmicProfile: currentUser.value!.cosmicProfile,
          isActive: currentUser.value!.isActive,
          isSuperuser: currentUser.value!.isSuperuser,
          lastActive: currentUser.value!.lastActive,
          createdAt: currentUser.value!.createdAt,
          updatedAt: currentUser.value!.updatedAt,
          timezone: timezone,
          avatarVersion: currentUser.value!.avatarVersion,
        );
        currentUser.value = updatedUser;
      }
      Get.snackbar('成功', '时区更新成功', duration: const Duration(seconds: 2));
      return ServiceResponse.success(response.data!);
    } else if (response.error != null) {
      error.value = response.error!.message;
      Get.snackbar('错误', response.error!.message);
    }

    return response;
  }

  /// 获取用户推送设置
  Future<ServiceResponse<Map<String, dynamic>>> getPushSettings() async {
    isLoading.value = true;
    error.value = '';

    final response = await get<Map<String, dynamic>>(
      '/api/profile/push-settings',
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      return ServiceResponse.success(response.data!);
    } else if (response.error != null) {
      error.value = response.error!.message;
    }

    return response;
  }

  /// 上传头像
  Future<ServiceResponse<Map<String, dynamic>>> uploadAvatar({
    required String filePath,
    required String fileName,
  }) async {
    isLoading.value = true;
    error.value = '';

    try {
      // 创建FormData
      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await post<Map<String, dynamic>>(
        '/api/profile/avatar',
        data: formData,
      );

      isLoading.value = false;

      if (response.success && response.data != null) {
        // 更新当前用户的头像信息
        if (currentUser.value != null) {
          final updatedUser = UserModel(
            id: currentUser.value!.id,
            username: currentUser.value!.username,
            bipupuId: currentUser.value!.bipupuId,
            nickname: currentUser.value!.nickname,
            avatarUrl: response.data!['avatar_url'] as String?,
            cosmicProfile: currentUser.value!.cosmicProfile,
            isActive: currentUser.value!.isActive,
            isSuperuser: currentUser.value!.isSuperuser,
            lastActive: currentUser.value!.lastActive,
            createdAt: currentUser.value!.createdAt,
            updatedAt: currentUser.value!.updatedAt,
            timezone: currentUser.value!.timezone,
            avatarVersion: (currentUser.value!.avatarVersion + 1),
          );
          currentUser.value = updatedUser;
        }
        Get.snackbar('成功', '头像上传成功', duration: const Duration(seconds: 2));
        return ServiceResponse.success(response.data!);
      } else if (response.error != null) {
        error.value = response.error!.message;
        Get.snackbar('错误', response.error!.message);
      }

      return response;
    } catch (e) {
      isLoading.value = false;
      error.value = '上传失败: $e';
      Get.snackbar('错误', '上传失败: $e');
      return ServiceResponse.failure(
        ServiceError('上传失败: $e', ServiceErrorType.unknown),
      );
    }
  }

  /// 清空错误信息
  void clearError() {
    error.value = '';
  }

  /// 重置用户数据
  void reset() {
    currentUser.value = null;
    error.value = '';
  }

  /// 获取当前用户的Bipupu ID
  String? get currentUserBipupuId => currentUser.value?.bipupuId;

  /// 获取当前用户的昵称
  String? get currentUserNickname => currentUser.value?.nickname;

  /// 获取当前用户的头像URL
  String? get currentUserAvatarUrl => currentUser.value?.avatarUrl;

  /// 检查是否有当前用户
  bool get hasCurrentUser => currentUser.value != null;

  /// 初始化用户资料
  Future<void> initialize() async {
    if (hasCurrentUser) {
      // 如果已经有用户信息，刷新一次
      await getCurrentUser();
    }
  }

  /// 获取用户基本信息摘要
  Map<String, dynamic> get userSummary {
    if (currentUser.value == null) {
      return {'hasUser': false};
    }

    final user = currentUser.value!;
    return {
      'hasUser': true,
      'username': user.username,
      'bipupuId': user.bipupuId,
      'nickname': user.nickname,
      'avatarUrl': user.avatarUrl,
      'isActive': user.isActive,
      'isSuperuser': user.isSuperuser,
      'timezone': user.timezone,
      'hasCosmicProfile': user.cosmicProfile != null,
    };
  }

  /// 检查用户是否活跃
  bool get isUserActive => currentUser.value?.isActive ?? false;

  /// 检查用户是否是超级用户
  bool get isSuperuser => currentUser.value?.isSuperuser ?? false;

  /// 获取用户创建时间
  DateTime? get userCreatedAt => currentUser.value?.createdAt;

  /// 获取用户最后活跃时间
  DateTime? get userLastActive => currentUser.value?.lastActive;
}
