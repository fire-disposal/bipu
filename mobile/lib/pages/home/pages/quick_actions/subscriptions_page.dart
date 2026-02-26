import 'package:flutter/material.dart';
import 'package:bipupu/core/network/network.dart';
import 'package:bipupu/core/network/api_exception.dart';
import 'package:easy_localization/easy_localization.dart';

class SubscriptionManagementPage extends StatefulWidget {
  const SubscriptionManagementPage({super.key});

  @override
  State<SubscriptionManagementPage> createState() =>
      _SubscriptionManagementPageState();
}

class _SubscriptionManagementPageState
    extends State<SubscriptionManagementPage> {
  List<dynamic> _allServices = [];
  Set<String> _subscribedServiceNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final all = await ApiClient.instance.api.serviceAccounts
          .getApiServiceAccounts();
      final subs = await ApiClient.instance.api.serviceAccounts
          .getApiServiceAccountsSubscriptions();
      setState(() {
        _allServices = all.items;
        _subscribedServiceNames = subs.subscriptions
            .map((s) => s.service.name)
            .toSet();
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载失败: ${e.message}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleSubscription(dynamic service) async {
    final serviceName = service.name as String;
    final wasSubscribed = _subscribedServiceNames.contains(serviceName);
    try {
      if (wasSubscribed) {
        await ApiClient.instance.api.serviceAccounts
            .deleteApiServiceAccountsNameSubscribe(name: serviceName);
        setState(() {
          _subscribedServiceNames.remove(serviceName);
        });
      } else {
        await ApiClient.instance.api.serviceAccounts
            .postApiServiceAccountsNameSubscribe(name: serviceName);
        setState(() {
          _subscribedServiceNames.add(serviceName);
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败: ${e.message}')));
      }
    }
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
                final isSubscribed = _subscribedServiceNames.contains(
                  service.name,
                );

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSubscribed
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      child: Icon(
                        isSubscribed
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSubscribed ? Colors.green : Colors.grey,
                      ),
                    ),
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
                      activeThumbColor: Colors.green,
                    ),
                    onTap: () => _toggleSubscription(service),
                  ),
                );
              },
            ),
    );
  }
}
