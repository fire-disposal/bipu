import 'package:flutter/material.dart';
import 'package:openapi/openapi.dart';
import '../widgets/admin_data_table.dart';

/// 管理端-通知管理页面
class NotificationManagementPage extends StatefulWidget {
  const NotificationManagementPage({Key? key}) : super(key: key);

  @override
  State<NotificationManagementPage> createState() =>
      _NotificationManagementPageState();
}

class _NotificationManagementPageState
    extends State<NotificationManagementPage> {
  late final NotificationsApi _api;
  List<NotificationResponse>? _notifications;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = Openapi().getNotificationsApi();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.getNotificationsApiNotificationsGet();
      setState(() {
        _notifications = (res.data as List<NotificationResponse>? ?? []);
      });
    } catch (e) {
      setState(() {
        _error = '通知获取失败: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _showNotificationDetail(NotificationResponse notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('通知详情'),
        content: SingleChildScrollView(child: Text(notification.toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通知管理')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : AdminDataTable<NotificationResponse>(
              data: _notifications ?? [],
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('标题')),
                DataColumn(label: Text('内容')),
                DataColumn(label: Text('状态')),
                DataColumn(label: Text('操作')),
              ],
              buildRows: (data) => data
                  .map(
                    (n) => DataRow(
                      cells: [
                        DataCell(Text('${n.id}')),
                        DataCell(Text(n.title ?? '')),
                        DataCell(Text(n.content ?? '')),
                        DataCell(Text(n.status?.name ?? '')),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.info_outline),
                            onPressed: () => _showNotificationDetail(n),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchNotifications,
        child: const Icon(Icons.refresh),
        tooltip: '刷新通知',
      ),
    );
  }
}
