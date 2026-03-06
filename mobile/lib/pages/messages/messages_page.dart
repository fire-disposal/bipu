import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/im_service.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final AuthService _authService = AuthService();
  final ImService _imService = ImService();

  @override
  void initState() {
    super.initState();
    _imService.addListener(_onImServiceChanged);
  }

  @override
  void dispose() {
    _imService.removeListener(_onImServiceChanged);
    super.dispose();
  }

  void _onImServiceChanged() {
    if (mounted) setState(() {});
  }

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
                badge: _imService.unreadNormalCount,
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
                badge: _imService.unreadSystemCount,
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
    int badge = 0,
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
                    Stack(
                      clipBehavior: Clip.none,
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
                        if (badge > 0)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.surface,
                                  width: 1.5,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                badge > 99 ? '99+' : badge.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
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
