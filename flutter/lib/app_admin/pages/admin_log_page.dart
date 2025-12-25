import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openapi/openapi.dart';
import '../widgets/admin_data_table.dart';
import '../state/admin_log_cubit.dart';

/// 管理端-日志管理页面
class AdminLogPage extends StatefulWidget {
  const AdminLogPage({super.key});

  @override
  State<AdminLogPage> createState() => _AdminLogPageState();
}

class _AdminLogPageState extends State<AdminLogPage> {
  late final AdminLogCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = AdminLogCubit();
    _cubit.loadLogs();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _showLogDetail(AdminLogResponse log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('日志详情'),
        content: SingleChildScrollView(child: Text(log.toString())),
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
      appBar: AppBar(title: const Text('日志管理')),
      body: BlocBuilder<AdminLogCubit, AdminLogState>(
        bloc: _cubit,
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(child: Text(state.error!));
          }
          return AdminDataTable<AdminLogResponse>(
            data: state.logs,
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('管理员ID')),
              DataColumn(label: Text('操作')),
              DataColumn(label: Text('时间')),
              DataColumn(label: Text('详情')),
            ],
            buildRows: (data) => data
                .map(
                  (log) => DataRow(
                    cells: [
                      DataCell(Text('${log.id}')),
                      DataCell(Text('${log.adminId}')),
                      DataCell(Text(log.action)),
                      DataCell(Text('${log.timestamp ?? ''}')),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () => _showLogDetail(log),
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
        onPressed: () => _cubit.loadLogs(),
        tooltip: '刷新日志',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
