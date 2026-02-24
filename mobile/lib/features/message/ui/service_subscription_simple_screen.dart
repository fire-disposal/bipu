import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/design_system.dart';
import '../../../shared/widgets/service_account_avatar.dart';
import '../../../shared/models/service_account_model.dart';
import '../logic/message_controller.dart';
import '../logic/message_provider.dart';

/// 简化的服务号管理界面
class ServiceSubscriptionSimpleScreen extends HookConsumerWidget {
  const ServiceSubscriptionSimpleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionState = ref.watch(serviceSubscriptionProvider);
    final serviceAccountsState = ref.watch(serviceAccountsProvider);
    final subscriptionController = ref.read(
      serviceSubscriptionControllerProvider,
    );

    // 初始化加载
    useEffect(() {
      subscriptionController.loadSubscriptions();
      ref.read(serviceAccountsProvider.notifier).loadServiceAccounts();
      return null;
    }, []);

    // 处理订阅/取消订阅
    Future<void> handleToggleSubscription(
      String serviceName,
      bool isSubscribed,
    ) async {
      if (isSubscribed) {
        // 取消订阅
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('取消订阅'),
            content: Text('确定要取消订阅服务号 "$serviceName" 吗？'),
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
          final success = await subscriptionController.unsubscribeService(
            serviceName,
          );
          if (success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('已取消订阅: $serviceName')));
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('取消订阅失败')));
          }
        }
      } else {
        // 订阅
        final success = await subscriptionController.subscribeService(
          serviceName,
        );
        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('已订阅: $serviceName')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('订阅失败')));
        }
      }
    }

    // 处理推送时间设置
    Future<void> handleSetPushTime(String serviceName) async {
      // 获取当前订阅信息
      UserSubscriptionResponse? subscription;
      try {
        subscription = subscriptionState.subscriptions.firstWhere(
          (sub) => sub.service.name == serviceName,
        );
      } catch (e) {
        subscription = null;
      }

      // 解析当前推送时间
      TimeOfDay? currentTime;
      if (subscription != null &&
          subscription.settings.pushTime != null &&
          subscription.settings.pushTime!.isNotEmpty) {
        final timeParts = subscription.settings.pushTime!.split(':');
        if (timeParts.length == 2) {
          try {
            currentTime = TimeOfDay(
              hour: int.parse(timeParts[0]),
              minute: int.parse(timeParts[1]),
            );
          } catch (e) {
            // 解析失败，使用默认时间
          }
        }
      }

      // 获取服务号默认推送时间
      TimeOfDay? defaultTime;
      if (subscription != null &&
          subscription.service.defaultPushTime != null &&
          subscription.service.defaultPushTime!.isNotEmpty) {
        final defaultParts = subscription.service.defaultPushTime!.split(':');
        if (defaultParts.length == 2) {
          try {
            defaultTime = TimeOfDay(
              hour: int.parse(defaultParts[0]),
              minute: int.parse(defaultParts[1]),
            );
          } catch (e) {
            // 解析失败
          }
        }
      }

      // 使用当前时间或默认时间（09:00）
      final initialTime =
          currentTime ?? defaultTime ?? const TimeOfDay(hour: 9, minute: 0);

      // 显示时间选择器
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
        helpText: '选择推送时间',
        cancelText: '取消',
        confirmText: '确定',
        hourLabelText: '小时',
        minuteLabelText: '分钟',
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).colorScheme.primary,
                onPrimary: Theme.of(context).colorScheme.onPrimary,
                surface: Theme.of(context).colorScheme.surface,
                onSurface: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            child: AlertDialog(
              title: const Text('设置推送时间'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '服务号: $serviceName',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  if (defaultTime != null)
                    Text(
                      '默认推送时间: ${defaultTime.hour.toString().padLeft(2, '0')}:${defaultTime.minute.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(height: 200, child: child),
                ],
              ),
            ),
          );
        },
      );

      if (selectedTime != null) {
        // 格式化时间为 HH:mm
        final formattedTime =
            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

        final success = await subscriptionController.setPushTime(
          serviceName,
          formattedTime,
        );

        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('推送时间已设置为: $formattedTime')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('设置失败')));
        }
      }
    }

    // 处理清除推送时间
    Future<void> handleClearPushTime(String serviceName) async {
      // 获取当前订阅信息
      UserSubscriptionResponse? subscription;
      try {
        subscription = subscriptionState.subscriptions.firstWhere(
          (sub) => sub.service.name == serviceName,
        );
      } catch (e) {
        subscription = null;
      }

      // 获取默认推送时间
      String? defaultTimeText;
      if (subscription != null &&
          subscription.service.defaultPushTime != null &&
          subscription.service.defaultPushTime!.isNotEmpty) {
        defaultTimeText = subscription.service.defaultPushTime;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('清除推送时间'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('确定要清除推送时间设置吗？'),
              const SizedBox(height: 8),
              if (defaultTimeText != null)
                Text(
                  '清除后将使用默认推送时间: $defaultTimeText',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              if (defaultTimeText == null)
                Text(
                  '清除后将不再有固定的推送时间',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认清除'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final success = await subscriptionController.clearPushTime(serviceName);
        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('推送时间已清除')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('清除失败')));
        }
      }
    }

    // 构建服务号项
    Widget buildServiceItem(
      String serviceName,
      String description,
      bool isSubscribed,
      String? pushTime,
    ) {
      final theme = Theme.of(context);
      UserSubscriptionResponse? subscription;
      try {
        subscription = subscriptionState.subscriptions.firstWhere(
          (sub) => sub.service.name == serviceName,
        );
      } catch (e) {
        subscription = null;
      }

      // 获取推送时间来源信息
      String? pushTimeSourceText;
      Color? pushTimeSourceColor;

      if (subscription != null) {
        final pushTimeSource = subscription.settings.pushTimeSource;
        if (pushTimeSource == 'subscription') {
          pushTimeSourceText = '自定义时间';
          pushTimeSourceColor = theme.colorScheme.primary;
        } else if (pushTimeSource == 'service_default') {
          pushTimeSourceText = '默认时间';
          pushTimeSourceColor = theme.colorScheme.secondary;
        } else if (subscription.settings.pushTime != null &&
            subscription.settings.pushTime!.isNotEmpty) {
          pushTimeSourceText = '已设置';
          pushTimeSourceColor = theme.colorScheme.primary;
        }
      }

      return Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        child: ListTile(
          leading: ServiceAccountAvatar(serviceName: serviceName, radius: 24),
          title: Text(
            serviceName,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isSubscribed)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (subscription != null &&
                          subscription.settings.pushTime != null &&
                          subscription.settings.pushTime!.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color:
                                  pushTimeSourceColor ??
                                  theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '推送时间: ${subscription.settings.pushTime}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    pushTimeSourceColor ??
                                    theme.colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      if (pushTimeSourceText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            pushTimeSourceText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  pushTimeSourceColor ??
                                  theme.colorScheme.outline,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      // 显示默认推送时间（如果有且当前未设置）
                      if (subscription != null &&
                          subscription.service.defaultPushTime != null &&
                          subscription.service.defaultPushTime!.isNotEmpty &&
                          (subscription.settings.pushTime == null ||
                              subscription.settings.pushTime!.isEmpty))
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '默认时间: ${subscription.service.defaultPushTime}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 推送时间设置按钮
              if (isSubscribed)
                IconButton(
                  icon: Icon(
                    Icons.access_time,
                    size: 20,
                    color:
                        subscription?.settings.pushTime != null &&
                            subscription!.settings.pushTime!.isNotEmpty
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  onPressed: () => handleSetPushTime(serviceName),
                  tooltip:
                      subscription?.settings.pushTime != null &&
                          subscription!.settings.pushTime!.isNotEmpty
                      ? '修改推送时间'
                      : '设置推送时间',
                ),
              // 订阅开关
              Switch(
                value: isSubscribed,
                onChanged: (value) =>
                    handleToggleSubscription(serviceName, !value),
              ),
            ],
          ),
          onTap: isSubscribed
              ? () {
                  // 显示更多选项
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 服务号信息
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                ServiceAccountAvatar(
                                  serviceName: serviceName,
                                  radius: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        serviceName,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      Text(
                                        description,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.outline,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // 推送时间信息
                          if (subscription != null &&
                              subscription.settings.pushTime != null &&
                              subscription.settings.pushTime!.isNotEmpty)
                            ListTile(
                              leading: Icon(
                                Icons.access_time,
                                color: theme.colorScheme.primary,
                              ),
                              title: Text(
                                '当前推送时间: ${subscription.settings.pushTime}',
                              ),
                              subtitle: Text(
                                subscription.settings.pushTimeSource ==
                                        'subscription'
                                    ? '自定义时间'
                                    : subscription.settings.pushTimeSource ==
                                          'service_default'
                                    ? '服务号默认时间'
                                    : '已设置',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              enabled: false,
                            ),
                          // 设置推送时间
                          ListTile(
                            leading: const Icon(Icons.access_time),
                            title: const Text('设置推送时间'),
                            subtitle: const Text('选择每天接收消息的时间'),
                            onTap: () {
                              Navigator.pop(context);
                              handleSetPushTime(serviceName);
                            },
                          ),
                          // 清除推送时间
                          if (subscription != null &&
                              subscription.settings.pushTime != null &&
                              subscription.settings.pushTime!.isNotEmpty)
                            ListTile(
                              leading: const Icon(Icons.clear),
                              title: const Text('清除推送时间'),
                              subtitle: const Text('恢复使用默认时间'),
                              onTap: () {
                                Navigator.pop(context);
                                handleClearPushTime(serviceName);
                              },
                            ),
                          // 查看服务号详情
                          ListTile(
                            leading: Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.outline,
                            ),
                            title: const Text('服务号详情'),
                            subtitle: const Text('查看服务号介绍和默认设置'),
                            onTap: () {
                              Navigator.pop(context);
                              // TODO: 添加服务号详情页面
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('查看 $serviceName 详情')),
                              );
                            },
                          ),
                          // 取消订阅
                          ListTile(
                            leading: Icon(
                              Icons.unsubscribe,
                              color: theme.colorScheme.error,
                            ),
                            title: Text(
                              '取消订阅',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              handleToggleSubscription(serviceName, false);
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                }
              : null,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('服务号管理'),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await subscriptionController.loadSubscriptions();
        },
        child: CustomScrollView(
          slivers: [
            // 统计信息
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '订阅统计',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              subscriptionState.isLoading
                                  ? '加载中...'
                                  : '已订阅 ${subscriptionState.subscriptions.length} 个服务号',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        Icon(
                          Icons.subscriptions,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 服务号列表
            SliverPadding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              sliver: serviceAccountsState.isLoading
                  ? const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : serviceAccountsState.error != null
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48),
                            const SizedBox(height: AppSpacing.md),
                            Text('加载失败: ${serviceAccountsState.error}'),
                            const SizedBox(height: AppSpacing.md),
                            ElevatedButton(
                              onPressed: () {
                                ref
                                    .read(serviceAccountsProvider.notifier)
                                    .loadServiceAccounts();
                              },
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final serviceAccount =
                            serviceAccountsState.accounts[index];
                        final isSubscribed = subscriptionState.subscriptions
                            .any(
                              (sub) => sub.service.name == serviceAccount.name,
                            );
                        UserSubscriptionResponse? subscription;
                        try {
                          subscription = subscriptionState.subscriptions
                              .firstWhere(
                                (sub) =>
                                    sub.service.name == serviceAccount.name,
                              );
                        } catch (e) {
                          subscription = null;
                        }
                        final pushTime = subscription?.settings.pushTime;

                        return buildServiceItem(
                          serviceAccount.name,
                          serviceAccount.description ?? '暂无描述',
                          isSubscribed,
                          pushTime,
                        );
                      }, childCount: serviceAccountsState.accounts.length),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
