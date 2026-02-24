import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/design_system.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/models/block_model.dart';
import '../logic/block_provider.dart';

/// 黑名单管理界面
class BlocksScreen extends HookConsumerWidget {
  const BlocksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockState = ref.watch(blocksProvider);
    final blockController = ref.read(blockControllerProvider);
    final searchController = useTextEditingController();
    final searchQuery = useState('');

    // 初始化加载黑名单
    useEffect(() {
      blockController.loadBlocks(refresh: true);
      return null;
    }, []);

    // 处理搜索
    void handleSearch(String query) {
      searchQuery.value = query;
    }

    // 处理拉黑用户
    Future<void> handleBlockUser() async {
      final bipupuIdController = TextEditingController();
      final reasonController = TextEditingController();

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('拉黑用户'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: bipupuIdController,
                decoration: const InputDecoration(
                  labelText: '用户Bipupu ID',
                  hintText: '请输入要拉黑的用户Bipupu ID',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入用户Bipupu ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: '拉黑原因（可选）',
                  hintText: '请输入拉黑原因',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (bipupuIdController.text.isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('拉黑'),
            ),
          ],
        ),
      );

      if (result == true) {
        final success = await blockController.blockUser(
          bipupuIdController.text.trim(),
          reason: reasonController.text.trim().isNotEmpty
              ? reasonController.text.trim()
              : null,
        );

        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('用户已拉黑')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('拉黑失败')));
        }
      }
    }

    // 处理取消拉黑
    Future<void> handleUnblockUser(BlockedUserResponse blockedUser) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('取消拉黑'),
          content: Text('确定要取消拉黑用户 "${blockedUser.displayName}" 吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final success = await blockController.unblockUser(blockedUser.id);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已取消拉黑: ${blockedUser.displayName}')),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('取消拉黑失败')));
        }
      }
    }

    // 获取要显示的黑名单列表
    List<BlockedUserResponse> getDisplayBlocks() {
      if (searchQuery.value.isEmpty) {
        return blockState.blockedUsers;
      }

      final lowercaseQuery = searchQuery.value.toLowerCase();
      return blockState.blockedUsers.where((user) {
        return user.displayName.toLowerCase().contains(lowercaseQuery) ||
            user.username.toLowerCase().contains(lowercaseQuery) ||
            user.blockedUserBipupuId.toLowerCase().contains(lowercaseQuery) ||
            (user.reason?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('黑名单管理'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.block),
            onPressed: handleBlockUser,
            tooltip: '拉黑用户',
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: '搜索黑名单用户...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: handleSearch,
            ),
          ),

          // 黑名单列表
          Expanded(
            child:
                blockState.status == BlockStatus.loading &&
                    blockState.blockedUsers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : blockState.status == BlockStatus.error
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: AppSpacing.md),
                        Text('加载失败: ${blockState.error}'),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton(
                          onPressed: () =>
                              blockController.loadBlocks(refresh: true),
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  )
                : getDisplayBlocks().isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.block_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          searchQuery.value.isEmpty ? '黑名单为空' : '未找到相关用户',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (searchQuery.value.isEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            '点击右上角按钮拉黑用户',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await blockController.refresh();
                    },
                    child: ListView.builder(
                      itemCount:
                          getDisplayBlocks().length +
                          (blockState.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < getDisplayBlocks().length) {
                          final blockedUser = getDisplayBlocks()[index];
                          return _buildBlockedUserItem(
                            context,
                            blockedUser,
                            handleUnblockUser,
                          );
                        } else {
                          // 加载更多
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            blockController.loadMore();
                          });
                          return const Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUserItem(
    BuildContext context,
    BlockedUserResponse blockedUser,
    Function(BlockedUserResponse) onUnblock,
  ) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: ListTile(
        leading: UserAvatar(
          bipupuId: blockedUser.blockedUserBipupuId,
          radius: 24,
        ),
        title: Text(
          blockedUser.displayName,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '@${blockedUser.username}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (blockedUser.reason != null && blockedUser.reason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '原因: ${blockedUser.reason}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '拉黑时间: ${_formatDate(blockedUser.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.block_outlined),
          color: theme.colorScheme.error,
          onPressed: () => onUnblock(blockedUser),
          tooltip: '取消拉黑',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '今天 ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return '昨天 ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
