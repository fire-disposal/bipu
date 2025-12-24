import 'package:flutter/material.dart';

/// 简化版用户管理页面，仅展示占位内容，避免未定义变量和方法错误
class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('用户管理')),
      body: const Center(
        child: Text(
          '用户管理页面暂未实现',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}
