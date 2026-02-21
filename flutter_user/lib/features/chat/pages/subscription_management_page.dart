import 'package:flutter/material.dart';
import 'package:bipupu/api/service_account_api.dart';
import 'package:bipupu/api/api.dart';
import 'package:bipupu/models/service/service_account.dart';
import 'package:bipupu/models/service/subscription_settings.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:bipupu/core/widgets/service_account_avatar.dart';

class SubscriptionManagementPage extends StatefulWidget {
  const SubscriptionManagementPage({super.key});

  @override
  State<SubscriptionManagementPage> createState() =>
      _SubscriptionManagementPageState();
}

class _SubscriptionManagementPageState
    extends State<SubscriptionManagementPage> {
  late final ServiceAccountApi _api = ServiceAccountApi();
  List<ServiceAccount> _allServices = [];
  Map<String, SubscriptionSettings> _subscriptionSettings = {};
  final Map<String, bool> _isExpanded = {};
  final Map<String, bool> _isLoading = {};
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isInitialLoading = true);
    try {
      final all = await _api.getServices();
      final subs = await _api.getUserSubscriptions();

      // 构建订阅设置映射
      final settingsMap = <String, SubscriptionSettings>{};
      for (final sub in subs.items) {
        settingsMap[sub.name] = SubscriptionSettings(
          serviceName: sub.name,
          serviceDescription: sub.description,
          pushTime: sub.pushTime,
          isEnabled: sub.isEnabled,
          subscribedAt: sub.subscribedAt,
          updatedAt: sub.updatedAt,
        );
      }

      setState(() {
        _allServices = all.items;
        _subscriptionSettings = settingsMap;
        // 初始化展开状态
        for (final service in all.items) {
          _isExpanded[service.name] = false;
          _isLoading[service.name] = false;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('load_failed'.tr(args: [e.toString()])),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  Future<void> _toggleSubscription(ServiceAccount service) async {
    final serviceName = service.name;
    final isSubscribed = _subscriptionSettings.containsKey(serviceName);

    setState(() => _isLoading[serviceName] = true);

    try {
      if (isSubscribed) {
        await _api.unsubscribe(serviceName);
        setState(() {
          _subscriptionSettings.remove(serviceName);
          _isExpanded[serviceName] = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'unsubscribed_success'.tr(
                  args: [service.displayName ?? service.name],
                ),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 订阅时使用默认设置
        await _api.subscribe(serviceName);

        // 获取订阅后的设置
        final settings = await _api.getSubscriptionSettings(serviceName);
        setState(() {
          _subscriptionSettings[serviceName] = settings;
          _isExpanded[serviceName] = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'subscribed_success'.tr(
                  args: [service.displayName ?? service.name],
                ),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('operation_failed'.tr(args: [e.toString()])),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading[serviceName] = false);
      }
    }
  }

  Future<void> _updateSubscriptionSettings(
    String serviceName,
    SubscriptionSettings newSettings,
  ) async {
    setState(() => _isLoading[serviceName] = true);

    try {
      final updatedSettings = await _api.updateSubscriptionSettings(
        serviceName,
        newSettings,
      );

      setState(() {
        _subscriptionSettings[serviceName] = updatedSettings;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings_updated'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('update_failed'.tr(args: [e.toString()])),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading[serviceName] = false);
      }
    }
  }

  void _toggleExpanded(String serviceName) {
    setState(() {
      _isExpanded[serviceName] = !(_isExpanded[serviceName] ?? false);
    });
  }

  Widget _buildServiceCard(ServiceAccount service) {
    final serviceName = service.name;
    final isSubscribed = _subscriptionSettings.containsKey(serviceName);
    final settings = _subscriptionSettings[serviceName];
    final isLoading = _isLoading[serviceName] ?? false;
    final isExpanded = _isExpanded[serviceName] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // 服务号基本信息
          ListTile(
            leading: ServiceAccountAvatar(
              avatarUrl: service.avatarUrl,
              displayName: service.displayName,
              radius: 24,
              showSubscriptionIndicator: true,
              isSubscribed: isSubscribed,
              backgroundColor: isSubscribed
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : null,
            ),
            title: Text(
              service.displayName ?? service.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            subtitle: service.description != null
                ? Text(
                    service.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSubscribed)
                  IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () => _toggleExpanded(serviceName),
                  ),
                Switch(
                  value: isSubscribed,
                  onChanged: isLoading
                      ? null
                      : (_) => _toggleSubscription(service),
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            onTap: isLoading ? null : () => _toggleSubscription(service),
          ),

          // 展开的设置面板
          if (isSubscribed && isExpanded && settings != null)
            _buildSettingsPanel(service, settings),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel(
    ServiceAccount service,
    SubscriptionSettings settings,
  ) {
    final serviceName = service.name;
    final isLoading = _isLoading[serviceName] ?? false;
    TimeOfDay? pushTime;

    if (settings.pushTime != null && settings.pushTime!.isNotEmpty) {
      final parts = settings.pushTime!.split(':');
      if (parts.length == 2) {
        try {
          pushTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        } catch (_) {
          pushTime = null;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),

          // 推送时间设置
          Text(
            'push_time_settings'.tr(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    pushTime != null
                        ? DateFormat('HH:mm').format(
                            DateTime(
                              2024,
                              1,
                              1,
                              pushTime.hour,
                              pushTime.minute,
                            ),
                          )
                        : 'set_push_time'.tr(),
                    style: TextStyle(
                      color: pushTime != null
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final selectedTime = await showTimePicker(
                            context: context,
                            initialTime: pushTime ?? TimeOfDay.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );

                          if (selectedTime != null) {
                            final newSettings = settings.copyWith(
                              pushTime:
                                  '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            );
                            await _updateSubscriptionSettings(
                              serviceName,
                              newSettings,
                            );
                          }
                        },
                ),
              ),
              const SizedBox(width: 12),
              Tooltip(
                message: 'push_time_help'.tr(),
                child: Icon(
                  Icons.help_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 启用/禁用开关
          Row(
            children: [
              Expanded(
                child: Text(
                  'enable_notifications'.tr(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Switch(
                value: settings.isEnabled ?? true,
                onChanged: isLoading
                    ? null
                    : (value) async {
                        final newSettings = settings.copyWith(isEnabled: value);
                        await _updateSubscriptionSettings(
                          serviceName,
                          newSettings,
                        );
                      },
                activeThumbColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),

          // 订阅信息
          if (settings.subscribedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'subscribed_since'.tr(args: [settings.subscribedAt.toString()]),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'no_services_available'.tr(),
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'check_back_later'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('subscription_management'.tr()),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isInitialLoading ? null : _loadData,
            tooltip: 'refresh'.tr(),
          ),
        ],
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : _allServices.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: _allServices.length,
                itemBuilder: (context, index) =>
                    _buildServiceCard(_allServices[index]),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // 显示订阅统计
          final subscribedCount = _subscriptionSettings.length;
          final totalCount = _allServices.length;

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('subscription_stats'.tr()),
              content: Text(
                'subscribed_services'.tr(
                  args: [subscribedCount.toString(), totalCount.toString()],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('close'.tr()),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.analytics),
        label: Text('stats'.tr()),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
