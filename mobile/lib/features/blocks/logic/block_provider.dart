import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/api_provider.dart';
import '../../../shared/models/block_model.dart';

/// 黑名单状态
enum BlockStatus {
  /// 初始状态
  initial,

  /// 加载中
  loading,

  /// 已加载
  loaded,

  /// 错误
  error,
}

/// 黑名单列表状态
class BlockListState {
  final BlockStatus status;
  final List<BlockedUserResponse> blockedUsers;
  final int page;
  final int total;
  final bool hasMore;
  final String? error;

  const BlockListState({
    this.status = BlockStatus.initial,
    this.blockedUsers = const [],
    this.page = 1,
    this.total = 0,
    this.hasMore = true,
    this.error,
  });

  BlockListState copyWith({
    BlockStatus? status,
    List<BlockedUserResponse>? blockedUsers,
    int? page,
    int? total,
    bool? hasMore,
    String? error,
  }) {
    return BlockListState(
      status: status ?? this.status,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      page: page ?? this.page,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockListState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          blockedUsers == other.blockedUsers &&
          page == other.page &&
          total == other.total &&
          hasMore == other.hasMore &&
          error == other.error;

  @override
  int get hashCode =>
      status.hashCode ^
      blockedUsers.hashCode ^
      page.hashCode ^
      total.hashCode ^
      hasMore.hashCode ^
      error.hashCode;

  @override
  String toString() {
    return 'BlockListState(status: $status, blockedUsers: ${blockedUsers.length}, page: $page, total: $total, hasMore: $hasMore, error: $error)';
  }
}

/// 黑名单列表提供者
final blocksProvider = NotifierProvider<BlocksNotifier, BlockListState>(
  () => BlocksNotifier(),
);

class BlocksNotifier extends Notifier<BlockListState> {
  @override
  BlockListState build() {
    return const BlockListState();
  }

  /// 加载黑名单列表
  Future<void> loadBlocks({bool refresh = false}) async {
    try {
      if (refresh) {
        state = state.copyWith(status: BlockStatus.loading, page: 1);
      } else {
        state = state.copyWith(status: BlockStatus.loading);
      }

      final restClient = ref.read(restClientProvider);
      final page = refresh ? 1 : state.page;
      final pageSize = 20;

      final response = await restClient.getBlockedUsers(
        page: page,
        size: pageSize,
      );

      if (response.response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final blockList = BlockListResponse.fromJson(data);

        final blockedUsers = refresh
            ? blockList.blockedUsers
            : [...state.blockedUsers, ...blockList.blockedUsers];

        state = BlockListState(
          status: BlockStatus.loaded,
          blockedUsers: blockedUsers,
          page: blockList.page + 1,
          total: blockList.total,
          hasMore: blockedUsers.length < blockList.total,
          error: null,
        );
      } else {
        state = state.copyWith(
          status: BlockStatus.error,
          error: '加载失败: ${response.response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('[Blocks] 加载黑名单失败：$e');
      state = state.copyWith(status: BlockStatus.error, error: '加载失败: $e');
    }
  }

  /// 加载更多黑名单
  Future<void> loadMore() async {
    if (state.status == BlockStatus.loading || !state.hasMore) {
      return;
    }

    await loadBlocks(refresh: false);
  }

  /// 刷新黑名单列表
  Future<void> refresh() async {
    await loadBlocks(refresh: true);
  }

  /// 拉黑用户
  Future<bool> blockUser(String blockedUserBipupuId, {String? reason}) async {
    try {
      final restClient = ref.read(restClientProvider);
      final response = await restClient.blockUser({
        'blocked_user_bipupu_id': blockedUserBipupuId,
        if (reason != null) 'reason': reason,
      });

      if (response.response.statusCode == 200) {
        debugPrint('[Blocks] 拉黑用户成功: $blockedUserBipupuId');
        // 刷新列表
        await refresh();
        return true;
      } else {
        debugPrint('[Blocks] 拉黑用户失败: ${response.response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('[Blocks] 拉黑用户异常：$e');
      return false;
    }
  }

  /// 取消拉黑用户
  Future<bool> unblockUser(int userId) async {
    try {
      final restClient = ref.read(restClientProvider);
      final response = await restClient.unblockUser(userId);

      if (response.response.statusCode == 200) {
        debugPrint('[Blocks] 取消拉黑成功: $userId');

        // 从本地状态中移除
        final blockedUsers = state.blockedUsers
            .where((user) => user.id != userId)
            .toList();

        state = state.copyWith(blockedUsers: blockedUsers);
        return true;
      } else {
        debugPrint('[Blocks] 取消拉黑失败: ${response.response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('[Blocks] 取消拉黑异常：$e');
      return false;
    }
  }

  /// 检查用户是否被拉黑
  bool isUserBlocked(String bipupuId) {
    return state.blockedUsers.any(
      (user) => user.blockedUserBipupuId == bipupuId,
    );
  }

  /// 根据Bipupu ID获取被拉黑用户
  BlockedUserResponse? getBlockedUserByBipupuId(String bipupuId) {
    try {
      return state.blockedUsers.firstWhere(
        (user) => user.blockedUserBipupuId == bipupuId,
      );
    } catch (e) {
      return null;
    }
  }

  /// 清除错误状态
  void clearError() {
    if (state.status == BlockStatus.error) {
      state = state.copyWith(status: BlockStatus.loaded, error: null);
    }
  }
}

/// 黑名单控制器
class BlockController {
  final Ref ref;

  BlockController({required this.ref});

  /// 获取黑名单Notifier
  BlocksNotifier get _blocksNotifier => ref.read(blocksProvider.notifier);

  /// 加载黑名单列表
  Future<void> loadBlocks({bool refresh = false}) async {
    await _blocksNotifier.loadBlocks(refresh: refresh);
  }

  /// 加载更多黑名单
  Future<void> loadMore() async {
    await _blocksNotifier.loadMore();
  }

  /// 刷新黑名单列表
  Future<void> refresh() async {
    await _blocksNotifier.refresh();
  }

  /// 拉黑用户
  Future<bool> blockUser(String blockedUserBipupuId, {String? reason}) async {
    return await _blocksNotifier.blockUser(blockedUserBipupuId, reason: reason);
  }

  /// 取消拉黑用户
  Future<bool> unblockUser(int userId) async {
    return await _blocksNotifier.unblockUser(userId);
  }

  /// 检查用户是否被拉黑
  bool isUserBlocked(String bipupuId) {
    return _blocksNotifier.isUserBlocked(bipupuId);
  }

  /// 根据Bipupu ID获取被拉黑用户
  BlockedUserResponse? getBlockedUserByBipupuId(String bipupuId) {
    return _blocksNotifier.getBlockedUserByBipupuId(bipupuId);
  }

  /// 清除错误状态
  void clearError() {
    _blocksNotifier.clearError();
  }
}

/// 黑名单控制器提供者
final blockControllerProvider = Provider<BlockController>((ref) {
  return BlockController(ref: ref);
});
