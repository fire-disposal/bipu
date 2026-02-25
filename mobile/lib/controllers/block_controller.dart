import 'package:get/get.dart';
import '../repos/block_repo.dart';
import '../shared/models/block_model.dart';

/// 极简黑名单控制器 - GetX风格
class BlockController extends GetxController {
  static BlockController get to => Get.find();

  // 状态
  final blockedUsers = <BlockedUserResponse>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;

  // 仓库
  final BlockRepo _repo = BlockRepo();

  /// 加载黑名单列表
  Future<void> loadBlockedUsers({int? page, int? size}) async {
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _repo.getBlockedUsers(page: page, size: size);

      if (result['success'] == true) {
        blockedUsers.value = result['data'] as List<BlockedUserResponse>;
      } else {
        error.value = result['error'] as String;
        Get.snackbar('错误', result['error'] as String);
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('错误', '加载黑名单失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 拉黑用户
  Future<void> blockUser(String bipupuId) async {
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _repo.blockUser(bipupuId);

      if (result['success'] == true) {
        Get.snackbar('成功', '用户已拉黑');
        await loadBlockedUsers(); // 刷新列表
      } else {
        error.value = result['error'] as String;
        Get.snackbar('错误', result['error'] as String);
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('错误', '拉黑失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 取消拉黑用户
  Future<void> unblockUser(String bipupuId) async {
    try {
      final result = await _repo.unblockUser(bipupuId);

      if (result['success'] == true) {
        Get.snackbar('成功', '已取消拉黑');
        blockedUsers.removeWhere((block) => block.bipupuId == bipupuId);
      } else {
        Get.snackbar('错误', result['error'] as String);
      }
    } catch (e) {
      Get.snackbar('错误', '取消拉黑失败: $e');
    }
  }

  /// 检查用户是否被拉黑
  bool isUserBlocked(String bipupuId) {
    return blockedUsers.any((block) => block.bipupuId == bipupuId);
  }

  /// 检查用户是否被拉黑（通过userId）
  bool isUserBlockedById(int userId) {
    return blockedUsers.any((block) => block.id == userId);
  }

  /// 获取黑名单统计
  Map<String, int> getBlockStats() {
    return {
      'total': blockedUsers.length,
      'active': blockedUsers.length, // 简化：全部视为活跃
    };
  }

  /// 初始化
  @override
  void onInit() {
    super.onInit();
    loadBlockedUsers();
  }
}
