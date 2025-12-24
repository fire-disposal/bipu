import 'package:flutter/material.dart';

/// 简化版消息管理页面，仅展示占位内容，避免未实现逻辑和多余依赖
class MessageManagementPage extends StatelessWidget {
  const MessageManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('消息管理')),
      body: const Center(
        child: Text(
          '消息管理页面暂未实现',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}
