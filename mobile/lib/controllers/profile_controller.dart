import 'package:get/get.dart';
import '../repos/profile_repo.dart';
import '../shared/models/user_model.dart';

/// 极简个人资料控制器 - GetX风格
class ProfileController extends GetxController {
  static ProfileController get to => Get.find();

  // 状态
  final userProfile = Rxn<UserModel>();
  final isLoading = false.obs;
  final error = ''.obs;
  final pushSettings = <String, dynamic>{}.obs;

  // 仓库
  final ProfileRepo _repo = ProfileRepo();

  /// 加载用户资料
  Future<void> loadUserProfile() async {
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _repo.getUserProfile();

      if (result['success'] == true) {
        userProfile.value = UserModel.fromJson(result['data']);
      } else {
        error.value = result['error'] as String;
        Get.snackbar('错误', result['error'] as String);
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('错误', '加载资料失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 更新用户信息
  Future<void> updateProfile(Map<String, dynamic> data) async {
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _repo.updateUserProfile(data);

      if (result['success'] == true) {
        Get.snackbar('成功', '资料更新成功');
        await loadUserProfile(); // 刷新资料
      } else {
        error.value = result['error'] as String;
        Get.snackbar('错误', result['error'] as String);
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('错误', '更新失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 更新密码
  Future<void> updatePassword(String oldPassword, String newPassword) async {
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _repo.updatePassword(oldPassword, newPassword);

      if (result['success'] == true) {
        Get.snackbar('成功', '密码更新成功');
      } else {
        error.value = result['error'] as String;
        Get.snackbar('错误', result['error'] as String);
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('错误', '密码更新失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 更新时区
  Future<void> updateTimezone(String timezone) async {
    try {
      final result = await _repo.updateTimezone(timezone);

      if (result['success'] == true) {
        Get.snackbar('成功', '时区更新成功');
        await loadUserProfile();
      } else {
        Get.snackbar('错误', result['error'] as String);
      }
    } catch (e) {
      Get.snackbar('错误', '时区更新失败: $e');
    }
  }

  /// 加载推送设置
  Future<void> loadPushSettings() async {
    try {
      final result = await _repo.getPushSettings();

      if (result['success'] == true) {
        pushSettings.value = result['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      // 静默失败
    }
  }

  /// 上传头像
  Future<void> uploadAvatar(String filePath) async {
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _repo.uploadAvatar(filePath);

      if (result['success'] == true) {
        Get.snackbar('成功', '头像上传成功');
        await loadUserProfile(); // 刷新资料
      } else {
        error.value = result['error'] as String;
        Get.snackbar('错误', result['error'] as String);
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('错误', '头像上传失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 获取用户基本信息
  Map<String, dynamic> getUserBasicInfo() {
    final user = userProfile.value;
    if (user == null) return {};

    return {
      'username': user.username,
      'nickname': user.nickname,
      'bipupuId': user.bipupuId,
      'avatar': user.avatarUrl,
      'email': '', // UserModel中没有email字段
    };
  }

  /// 初始化
  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
    loadPushSettings();
  }
}
