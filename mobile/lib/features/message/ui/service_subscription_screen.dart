import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/design_system.dart';
import '../logic/message_provider.dart';

/// 服务号订阅管理页面
class ServiceSubscriptionScreen extends HookConsumerWidget {
  const ServiceSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionState = ref.watch(serviceSubscriptionProvider);
    final serviceAccountsState = ref.watch(serviceAccountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('服务号订阅'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 订阅统计
            Card(
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

            const SizedBox(height: AppSpacing.lg),

            // 订阅列表标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '我的订阅',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subscriptionState.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // 订阅列表
            Expanded(
              child: subscriptionState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : subscriptionState.subscriptions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.subscriptions_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            '暂无订阅',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '订阅服务号以接收推送消息',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: subscriptionState.subscriptions.length,
                      itemBuilder: (context, index) {
                        final subscription =
                            subscriptionState.subscriptions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(AppSpacing.md),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(
                                Icons.account_circle,
                                size: 32,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              subscription.service.name,
                              style: Theme.of(context).textTheme.titleMedium!,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  subscription.service.description ?? '暂无描述',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.notifications,
                                      size: 14,
                                      color:
                                          subscription.settings.isEnabled ==
                                              true
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.outline,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      subscription.settings.isEnabled == true
                                          ? '推送已开启'
                                          : '推送已关闭',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color:
                                                subscription
                                                        .settings
                                                        .isEnabled ==
                                                    true
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.outline,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Switch(
                              value: subscription.settings.isEnabled == true,
                              onChanged: (value) {
                                // TODO: 实现推送开关
                              },
                            ),
                            onTap: () {
                              // TODO: 跳转到服务号详情页面
                            },
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 发现更多服务号
            if (!serviceAccountsState.isLoading &&
                serviceAccountsState.accounts.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '推荐服务号',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: serviceAccountsState.accounts.length,
                      itemBuilder: (context, index) {
                        final service = serviceAccountsState.accounts[index];
                        return Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: AppSpacing.sm),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    service.description ?? '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // TODO: 实现订阅功能
                                      },
                                      child: const Text('订阅'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
