import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/bluetooth/ble_pipeline.dart';
import '../../core/bluetooth/ble_simple_ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BlePipeline _blePipeline = BlePipeline();
  late final SimpleBleState _bleState;

  @override
  void initState() {
    super.initState();
    _bleState = SimpleBleState();
    _bleState.addListener(_onBleStateChanged);
  }

  @override
  void dispose() {
    _bleState.removeListener(_onBleStateChanged);
    _bleState.dispose();
    super.dispose();
  }

  void _onBleStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildConnectionStatus() {
    if (_bleState.isConnecting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 4),
            Text(
              '正在连接',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else if (_bleState.isConnected) {
      final batteryLevel = _bleState.batteryLevel;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bluetooth_connected,
              size: 14,
              color: Colors.green,
            ),
            const SizedBox(width: 4),
            Text(
              '已连�?,
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (batteryLevel != null) ...[
              const SizedBox(width: 8),
              Icon(
                batteryLevel > 20 ? Icons.battery_std : Icons.battery_alert,
                size: 14,
                color: batteryLevel > 20 ? Colors.green : Colors.red,
              ),
              Text(
                '$batteryLevel%',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.error),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.link_off,
              size: 14,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 4),
            Text(
              '未连�?,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BIPUPU',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Device Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '我的设备',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Connection status
                        _buildConnectionStatus(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.developer_board,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _bleState.isConnected
                                    ? (_bleState
                                              .connectedDevice
                                              ?.platformName ??
                                          '未知设备')
                                    : '未绑定设�?,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _bleState.isConnected
                                    ? 'ID: ${_bleState.connectedDevice?.remoteId.str ?? '--'}'
                                    : '请先连接您的蓝牙设备',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (_bleState.isConnected) {
                          context.push('/bluetooth/control');
                        } else {
                          context.push('/bluetooth/scan');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _bleState.isConnected
                                ? Icons.settings_remote
                                : Icons.add_link,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _bleState.isConnected ? '设备详情' : '立即连接',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              '快捷操作',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _buildQuickActionCard(
                  context,
                  '好友',
                  Icons.people_alt_rounded,
                  Colors.blue.shade600,
                  () => context.push('/contacts'),
                ),
                _buildQuickActionCard(
                  context,
                  '发现',
                  Icons.explore_rounded,
                  Colors.orange.shade700,
                  () => context.push('/discover'),
                ),
                _buildQuickActionCard(
                  context,
                  '订阅',
                  Icons.card_membership_rounded,
                  Colors.teal.shade600,
                  () => context.push('/subscription'),
                ),
                _buildQuickActionCard(
                  context,
                  '聊天',
                  Icons.chat_bubble_rounded,
                  Colors.indigo.shade600,
                  () => context.push('/messages'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
