import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openapi/openapi.dart';
import '../widgets/admin_data_table.dart';
import '../state/message_management_cubit.dart';

/// 管理端-消息管理页面
class MessageManagementPage extends StatefulWidget {
  const MessageManagementPage({super.key});

  @override
  State<MessageManagementPage> createState() => _MessageManagementPageState();
}

class _MessageManagementPageState extends State<MessageManagementPage> {
  late final MessageManagementCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = MessageManagementCubit();
    _cubit.loadMessages();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
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
        content: const Text('确定删除这条消息吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cubit.deleteMessage(message.id);
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
            onPressed: () => _cubit.loadMessages(),
          ),
        ],
      ),
      body: BlocBuilder<MessageManagementCubit, MessageManagementState>(
        bloc: _cubit,
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(child: Text(state.error!));
          }
          return AdminDataTable<MessageResponse>(
            data: state.messages,
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
          );
        },
      ),
    );
  }
}
