import 'package:flutter/material.dart';
import 'package:flutter_core/models/admin_log_model.dart';
import 'package:flutter_core/repositories/admin_log_repository.dart';
import 'package:intl/intl.dart';

class AdminLogPage extends StatefulWidget {
  const AdminLogPage({super.key});

  @override
  State<AdminLogPage> createState() => _AdminLogPageState();
}

class _AdminLogPageState extends State<AdminLogPage> {
  final AdminLogRepository _repository = AdminLogRepository();
  List<AdminLog> _logs = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _total = 0;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _repository.getLogs(
        page: _currentPage,
        size: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        _logs = response.items;
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            ElevatedButton(onPressed: _loadLogs, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Logs',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: ListView.separated(
                itemCount: _logs.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(log.action),
                    subtitle: Text(
                      'Admin ID: ${log.adminId} • ${DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp)}',
                    ),
                    trailing: log.detail != null
                        ? IconButton(
                            icon: const Icon(Icons.info_outline),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Log Details'),
                                  content: SingleChildScrollView(
                                    child: Text(log.detail.toString()),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : null,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Page $_currentPage of ${(_total / _pageSize).ceil()}'),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1
                    ? () {
                        setState(() => _currentPage--);
                        _loadLogs();
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage * _pageSize < _total
                    ? () {
                        setState(() => _currentPage++);
                        _loadLogs();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
