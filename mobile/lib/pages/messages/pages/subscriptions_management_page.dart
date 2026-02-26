import 'package:flutter/material.dart';
import 'package:bipupu/core/network/network.dart';
import 'package:bipupu/core/network/api_exception.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

class SubscriptionsManagementPage extends StatefulWidget {
  const SubscriptionsManagementPage({super.key});

  @override
  State<SubscriptionsManagementPage> createState() =>
      _SubscriptionsManagementPageState();
}

class _SubscriptionsManagementPageState
    extends State<SubscriptionsManagementPage> {
  List<ServiceAccountResponse> _allServices = [];
  Map<String, bool> _subscribedServices = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load all available services
      final allServicesResponse = await ApiClient.instance.api.serviceAccounts
          .getApiServiceAccounts();

      // Load user's subscriptions
      final userSubscriptionsResponse = await ApiClient
          .instance
          .api
          .serviceAccounts
          .getApiServiceAccountsSubscriptions();

      final subscribedNames = userSubscriptionsResponse.subscriptions
          .map((s) => s.service.name)
          .toSet();

      setState(() {
        _allServices = allServicesResponse.items;
        // Initialize subscription map
        _subscribedServices = {
          for (var service in allServicesResponse.items)
            service.name: subscribedNames.contains(service.name),
        };
      });
    } on ApiException catch (e) {
      if (mounted) {
        // 如果是401错误，说明需要重新登录，不显示错误提示
        if (e.statusCode != 401) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('加载失败: ${e.message}')));
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleSubscription(ServiceAccountResponse service) async {
    final serviceName = service.name;
    final wasSubscribed = _subscribedServices[serviceName] ?? false;

    try {
      if (wasSubscribed) {
        await ApiClient.instance.api.serviceAccounts
            .deleteApiServiceAccountsNameSubscribe(name: serviceName);
        setState(() {
          _subscribedServices[serviceName] = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('已取消订阅 ${service.name}')));
        }
      } else {
        await ApiClient.instance.api.serviceAccounts
            .postApiServiceAccountsNameSubscribe(name: serviceName);
        setState(() {
          _subscribedServices[serviceName] = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('已订阅 ${service.name}')));
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败: ${e.message}')));
      }
    }
  }

  void _showPushTimeSettings(ServiceAccountResponse service) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _PushTimeSettingsSheet(
        serviceName: service.name,
        onSaved: () {
          Navigator.of(ctx).pop();
          _loadData(); // Refresh data after settings change
        },
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
            onPressed: _loadData,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allServices.isEmpty
          ? Center(child: Text('no_services'.tr()))
          : ListView.builder(
              itemCount: _allServices.length,
              itemBuilder: (context, index) {
                final service = _allServices[index];
                final isSubscribed = _subscribedServices[service.name] ?? false;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: _buildServiceAvatar(service),
                    title: Text(
                      service.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: service.description != null
                        ? Text(
                            service.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          )
                        : null,
                    trailing: Switch(
                      value: isSubscribed,
                      onChanged: (value) => _toggleSubscription(service),
                      activeColor: Colors.green,
                    ),
                    onTap: isSubscribed
                        ? () => _showPushTimeSettings(service)
                        : null,
                  ),
                );
              },
            ),
    );
  }

  Widget _buildServiceAvatar(ServiceAccountResponse service) {
    if (service.avatarUrl != null && service.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(service.avatarUrl!),
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('Failed to load avatar: $exception');
        },
      );
    }
    return CircleAvatar(
      backgroundColor: Colors.grey.withOpacity(0.3),
      child: Text(
        service.name.isNotEmpty ? service.name[0].toUpperCase() : '?',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PushTimeSettingsSheet extends StatefulWidget {
  final String serviceName;
  final VoidCallback onSaved;

  const _PushTimeSettingsSheet({
    required this.serviceName,
    required this.onSaved,
  });

  @override
  State<_PushTimeSettingsSheet> createState() => _PushTimeSettingsSheetState();
}

class _PushTimeSettingsSheetState extends State<_PushTimeSettingsSheet> {
  late TextEditingController _timeController;
  bool _isLoading = true;
  String? _currentPushTime;

  @override
  void initState() {
    super.initState();
    _timeController = TextEditingController();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      final settings = await ApiClient.instance.api.serviceAccounts
          .getApiServiceAccountsNameSettings(name: widget.serviceName);
      setState(() {
        _currentPushTime = settings.pushTime ?? '';
        _timeController.text = _currentPushTime ?? '';
        _isLoading = false;
      });
    } on ApiException catch (e) {
      debugPrint('Error loading settings: ${e.message}');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePushTime() async {
    final newTime = _timeController.text.trim();

    // Validate time format HH:MM
    if (newTime.isNotEmpty && !RegExp(r'^\d{2}:\d{2}$').hasMatch(newTime)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入正确的时间格式 (HH:MM)')));
      return;
    }

    try {
      await ApiClient.instance.api.serviceAccounts
          .putApiServiceAccountsNameSettings(
            name: widget.serviceName,
            body: SubscriptionSettingsUpdate(
              pushTime: newTime.isEmpty ? null : newTime,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('推送时间已更新')));
        widget.onSaved();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: ${e.message}')));
      }
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.serviceName} - 推送时间设置',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '推送时间 (HH:MM 格式)',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _timeController,
                    decoration: InputDecoration(
                      hintText: '例如: 09:00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: const Icon(Icons.access_time),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _savePushTime,
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
