import 'package:flutter/material.dart';
import 'package:openapi/openapi.dart';
import '../widgets/admin_data_table.dart';

/// 管理端-消息管理页面
class MessageManagementPage extends StatefulWidget {
  const MessageManagementPage({Key? key}) : super(key: key);

  @override
  State<MessageManagementPage> createState() => _MessageManagementPageState();
}

class _MessageManagementPageState extends State<MessageManagementPage> {
  late final MessagesApi _api;
  List<MessageResponse>? _messages;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = Openapi().getMessagesApi();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.adminGetAllMessagesApiMessagesAdminAllGet();
      setState(() {
        _messages = (res.data as List<MessageResponse>? ?? []);
      });
    } catch (e) {
      setState(() {
        _error = '消息获取失败: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _showMessageDetail(MessageResponse message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('消息详情'),
        content: SingleChildScrollView(child: Text(message.toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(MessageResponse message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定删除这条消息吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _api.adminDeleteMessageApiMessagesAdminMessageIdDelete(
                  messageId: message.id,
                );
                _fetchMessages();
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新消息',
            onPressed: _fetchMessages,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : AdminDataTable<MessageResponse>(
              data: _messages ?? [],
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('发送者')),
                DataColumn(label: Text('接收者')),
                DataColumn(label: Text('内容')),
                DataColumn(label: Text('时间')),
                DataColumn(label: Text('操作')),
              ],
              buildRows: (data) => data
                  .map(
                    (msg) => DataRow(
                      cells: [
                        DataCell(Text('${msg.id}')),
                        DataCell(Text('${msg.senderId}')),
                        DataCell(Text('${msg.receiverId}')),
                        DataCell(Text(msg.content ?? '')),
                        DataCell(Text('${msg.createdAt}')),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                tooltip: '查看',
                                onPressed: () => _showMessageDetail(msg),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: '删除',
                                onPressed: () => _confirmDelete(msg),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
