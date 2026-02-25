import 'package:get/get.dart';
import 'base_service.dart';
import '../models/block_model.dart';

/// 黑名单服务 - 处理用户黑名单相关API
class BlockService extends BaseService {
  static BlockService get instance => Get.find();

  final blockedUsers = <BlockedUserResponse>[].obs;
  final isLoading = false.obs;
  final RxString error = ''.obs;

  /// 获取黑名单列表
  Future<ServiceResponse<List<BlockedUserResponse>>> getBlockedUsers({
    int? page,
    int? size,
  }) async {
    isLoading.value = true;
    error.value = '';

    final response = await get<List<dynamic>>(
      '/api/blocks',
      query: {
        if (page != null) 'page': page.toString(),
        if (size != null) 'size': size.toString(),
      },
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      final blockList = response.data!
          .map(
            (json) =>
                BlockedUserResponse.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      blockedUsers.assignAll(blockList);
      return ServiceResponse.success(blockList);
    } else if (response.error != null) {
      error.value = response.error!.message;
    }

    return ServiceResponse.failure(
      response.error ?? ServiceError('获取黑名单失败', ServiceErrorType.unknown),
    );
  }

  /// 拉黑用户
  Future<ServiceResponse<BlockedUserResponse>> blockUser({
    required String bipupuId,
    String? reason,
  }) async {
    isLoading.value = true;
    error.value = '';

    final response = await post<BlockedUserResponse>(
      '/api/blocks',
      data: {'bipupu_id': bipupuId, if (reason != null) 'reason': reason},
      fromJson: (json) => BlockedUserResponse.fromJson(json),
    );

    isLoading.value = false;

    if (response.success && response.data != null) {
      blockedUsers.add(response.data!);
      Get.snackbar('成功', '用户已加入黑名单', duration: const Duration(seconds: 2));
      return ServiceResponse.success(response.data!);
    } else if (response.error != null) {
      error.value = response.error!.message;
      Get.snackbar('错误', response.error!.message);
    }

    return response;
  }

  /// 取消拉黑用户
  Future<ServiceResponse<void>> unblockUser(String bipupuId) async {
    isLoading.value = true;
    error.value = '';

    final response = await delete<void>('/api/blocks/$bipupuId');

    isLoading.value = false;

    if (response.success) {
      blockedUsers.removeWhere((block) => block.bipupuId == bipupuId);
      Get.snackbar('成功', '用户已从黑名单移除', duration: const Duration(seconds: 2));
    } else if (response.error != null) {
      error.value = response.error!.message;
      Get.snackbar('错误', response.error!.message);
    }

    return response;
  }

  /// 检查用户是否在黑名单中
  bool isUserBlocked(String bipupuId) {
    return blockedUsers.any((block) => block.bipupuId == bipupuId);
  }

  /// 获取黑名单统计
  Map<String, int> getBlockStats() {
    return {'total': blockedUsers.length};
  }

  /// 根据Bipupu ID查找黑名单记录
  BlockedUserResponse? findBlockByBipupuId(String bipupuId) {
    return blockedUsers.firstWhereOrNull((block) => block.bipupuId == bipupuId);
  }

  /// 清空错误信息
  void clearError() {
    error.value = '';
  }

  /// 清空黑名单列表
  void clearAll() {
    blockedUsers.clear();
    error.value = '';
  }

  /// 初始化黑名单数据
  Future<void> initialize() async {
    if (blockedUsers.isEmpty) {
      await getBlockedUsers();
    }
  }

  /// 获取黑名单用户ID列表
  List<String> get blockedUserIds {
    return blockedUsers.map((block) => block.bipupuId).toList();
  }

  /// 获取最近拉黑的用户
  List<BlockedUserResponse> get recentlyBlockedUsers {
    return List.from(blockedUsers)
      ..sort((a, b) => b.blockedAt.compareTo(a.blockedAt));
  }

  /// 获取显示名称列表
  List<String> get blockedUserDisplayNames {
    return blockedUsers.map((block) => block.displayName).toList();
  }
}
