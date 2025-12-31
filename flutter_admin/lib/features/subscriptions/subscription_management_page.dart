import 'package:flutter/material.dart';
import 'package:flutter_core/models/subscription_model.dart';
import 'package:flutter_core/repositories/subscription_repository.dart';

class SubscriptionManagementPage extends StatefulWidget {
  const SubscriptionManagementPage({super.key});

  @override
  State<SubscriptionManagementPage> createState() =>
      _SubscriptionManagementPageState();
}

class _SubscriptionManagementPageState
    extends State<SubscriptionManagementPage> {
  final SubscriptionRepository _subscriptionRepository =
      SubscriptionRepository();
  List<SubscriptionType> _subscriptionTypes = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _total = 0;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionTypes();
  }

  Future<void> _loadSubscriptionTypes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _subscriptionRepository.getSubscriptionTypes(
        page: _currentPage,
        size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _subscriptionTypes = response.items;
        _total = response.total;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubscriptionTypes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _subscriptionTypes.length,
                    itemBuilder: (context, index) {
                      final subType = _subscriptionTypes[index];
                      return ListTile(
                        title: Text(subType.name),
                        subtitle: Text(subType.description ?? 'No description'),
                        trailing: Chip(
                          label: Text(subType.isActive ? 'Active' : 'Inactive'),
                          backgroundColor: subType.isActive
                              ? Colors.green[100]
                              : Colors.grey[100],
                        ),
                      );
                    },
                  ),
                ),
                _buildPagination(),
              ],
            ),
    );
  }

  Widget _buildPagination() {
    final totalPages = (_total / _pageSize).ceil();
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                    _loadSubscriptionTypes();
                  }
                : null,
          ),
          Text('Page $_currentPage of $totalPages (Total: $_total)'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                    _loadSubscriptionTypes();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
