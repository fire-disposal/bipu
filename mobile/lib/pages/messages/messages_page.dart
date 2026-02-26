import 'package:flutter/material.dart';
import 'package:bipupu/core/network/network.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';
import 'pages/subscriptions_management_page.dart';
import 'pages/received_messages_page.dart';
import 'pages/sent_messages_page.dart';
import 'pages/system_messages_page.dart';
import 'pages/favorites_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('messages_title'.tr())),
        body: Center(child: Text('please_login'.tr())),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('messages_title'.tr()), elevation: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 收到的消息
              _buildMenuCard(
                'messages_menu_received'.tr(),
                Icons.mail_outline,
                () => context.push('/messages/received'),
              ),
              const SizedBox(height: 12),
              // 发出的消息
              _buildMenuCard(
                'messages_menu_sent'.tr(),
                Icons.send_outlined,
                () => context.push('/messages/sent'),
              ),
              const SizedBox(height: 12),
              // 系统消息
              _buildMenuCard(
                'messages_menu_system'.tr(),
                Icons.notifications_outlined,
                () => context.push('/messages/system'),
              ),
              const SizedBox(height: 12),
              // 我的收藏
              _buildMenuCard(
                'messages_menu_favorites'.tr(),
                Icons.favorite_outline,
                () => context.push('/messages/favorites'),
              ),
              const SizedBox(height: 12),
              // 消息设置
              _buildMenuCard(
                'subscription_management'.tr(),
                Icons.settings_outlined,
                () => context.push('/messages/subscriptions'),
                isSettings: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isSettings = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSettings
                            ? Colors.orange.withValues(alpha: 0.1)
                            : Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: isSettings
                            ? Colors.orange
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (isSettings)
                            Text(
                              'manage_subscriptions'.tr(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
