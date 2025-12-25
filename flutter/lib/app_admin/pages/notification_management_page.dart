import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openapi/openapi.dart';
import '../widgets/admin_data_table.dart';
import '../state/notification_management_cubit.dart';

/// 管理端-通知管理页面
class NotificationManagementPage extends StatefulWidget {
  const NotificationManagementPage({super.key});

  @override
  State<NotificationManagementPage> createState() =>
      _NotificationManagementPageState();
}

class _NotificationManagementPageState
    extends State<NotificationManagementPage> {
  late final NotificationManagementCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = NotificationManagementCubit();
    _cubit.loadNotifications();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _showNotificationDetail(NotificationResponse notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('通知详情'),
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
      body:
          BlocBuilder<NotificationManagementCubit, NotificationManagementState>(
            bloc: _cubit,
            builder: (context, state) {
              if (state.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.error != null) {
                return Center(child: Text(state.error!));
              }
              return AdminDataTable<NotificationResponse>(
                data: state.notifications,
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
                          DataCell(Text(n.status.name ?? '')),
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
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _cubit.loadNotifications(),
        tooltip: '刷新通知',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
