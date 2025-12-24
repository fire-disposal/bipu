import 'package:flutter/material.dart';
import '../widgets/admin_widgets.dart';
import '../widgets/admin_layout.dart';

/// 管理端首页（仪表盘）
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: '仪表盘',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '欢迎回来，管理员！',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            // 统计面板区
            CoreStatPanel(
              stats: [
                StatCard(title: '用户总数', value: '1,024', icon: Icons.people),
                StatCard(title: '今日活跃', value: '128', icon: Icons.bolt),
                StatCard(title: '消息数', value: '3,456', icon: Icons.message),
              ],
            ),
            const SizedBox(height: 32),
            // 近期操作/公告等
            CoreCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('系统公告', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('暂无公告。'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
