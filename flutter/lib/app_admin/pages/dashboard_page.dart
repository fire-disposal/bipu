import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/admin_widgets.dart';
import '../state/dashboard_cubit.dart';

/// 管理端首页（仪表盘）
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = DashboardCubit();
    _cubit.loadDashboardData();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: '仪表盘',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: BlocBuilder<DashboardCubit, DashboardState>(
          bloc: _cubit,
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
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
                    StatCard(
                      title: '用户总数',
                      value: state.totalUsers.toString(),
                      icon: Icons.people,
                    ),
                    StatCard(
                      title: '活跃用户',
                      value: state.activeUsers.toString(),
                      icon: Icons.bolt,
                    ),
                    StatCard(
                      title: '设备总数',
                      value: state.totalDevices.toString(),
                      icon: Icons.devices,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // 近期数据概览
                if (state.error != null)
                  CoreCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '数据加载错误',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(state.error!),
                      ],
                    ),
                  ),
                if (state.error == null) ...[
                  CoreCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '最近用户',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (state.recentUsers.isEmpty)
                          const Text('暂无用户数据')
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: state.recentUsers
                                .take(3)
                                .map(
                                  (user) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      '• ${user.username} (${user.email})',
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CoreCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '最近消息',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (state.recentMessages.isEmpty)
                          const Text('暂无消息数据')
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: state.recentMessages
                                .map(
                                  (message) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      '• ${message.content ?? '无内容'}',
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
