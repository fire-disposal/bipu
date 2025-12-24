import 'package:flutter/material.dart';
import 'package:openapi/openapi.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_form_builder.dart';

/// 管理端-日志管理页面
class AdminLogPage extends StatefulWidget {
  const AdminLogPage({Key? key}) : super(key: key);

  @override
  State<AdminLogPage> createState() => _AdminLogPageState();
}

class _AdminLogPageState extends State<AdminLogPage> {
  late final AdminLogsApi _api;
  List<AdminLogResponse>? _logs;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = Openapi().getAdminLogsApi();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.getAdminLogsApiAdminLogsGet();
      setState(() {
        _logs = (res.data as List<AdminLogResponse>? ?? []);
      });
    } catch (e) {
      setState(() {
        _error = '日志获取失败: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _showLogDetail(AdminLogResponse log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('日志详情'),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : AdminDataTable<AdminLogResponse>(
              data: _logs ?? [],
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
                        DataCell(Text('${log.action}')),
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
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchLogs,
        child: const Icon(Icons.refresh),
        tooltip: '刷新日志',
      ),
    );
  }
}
