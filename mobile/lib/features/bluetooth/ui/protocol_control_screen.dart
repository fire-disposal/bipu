import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/bluetooth/ble_manager.dart';
import '../../../core/services/message_forwarder.dart';
import '../../../core/theme/design_system.dart';

/// 蓝牙协议控制页面提供者
final protocolControlProvider = Provider((ref) {
  return ProtocolControlController(
    bleManager: ref.read(bleManagerProvider),
    messageForwarder: ref.read(messageForwarderProvider),
  );
});

/// 蓝牙协议控制页面控制器
class ProtocolControlController {
  final BleManager bleManager;
  final MessageForwarder messageForwarder;

  ProtocolControlController({
    required this.bleManager,
    required this.messageForwarder,
  });

  /// 获取蓝牙管理器状态
  Map<String, dynamic> getBleManagerStatus() {
    return {
      'isScanning': bleManager.isScanning,
      'connectedDevices': bleManager.connectedDevices.length,
      'connectionState': bleManager.connectionState.toString(),
    };
  }

  /// 获取消息转发状态
  Map<String, dynamic> getForwarderStatus() {
    return messageForwarder.getStatus();
  }

  /// 手动触发时间同步到所有设备
  Future<void> syncTimeToAllDevices() async {
    await messageForwarder.syncTimeToAllDevices();
  }

  /// 测试发送文本消息
  Future<void> sendTestMessage(
    String deviceId,
    String senderId,
    String message,
  ) async {
    // 这里需要直接调用协议服务发送测试消息
    // 由于协议服务是内部实现，这里暂时留空
    // 实际实现时可以通过依赖注入获取协议服务实例
  }
}

/// 蓝牙协议控制页面
class ProtocolControlScreen extends HookConsumerWidget {
  const ProtocolControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(protocolControlProvider);

    // 状态
    final bleStatus = useState<Map<String, dynamic>>({});
    final forwarderStatus = useState<Map<String, dynamic>>({});
    final isLoading = useState(false);
    final lastSyncTime = useState<DateTime?>(null);

    // 定时刷新状态
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 2), (_) {
        bleStatus.value = controller.getBleManagerStatus();
        forwarderStatus.value = controller.getForwarderStatus();
      });

      // 初始加载
      bleStatus.value = controller.getBleManagerStatus();
      forwarderStatus.value = controller.getForwarderStatus();

      return timer.cancel;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('蓝牙协议控制'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 蓝牙状态卡片
            _buildStatusCard(
              context,
              '蓝牙状态',
              bleStatus.value,
              Icons.bluetooth,
              Colors.blue,
            ),
            const SizedBox(height: AppSpacing.lg),

            // 消息转发状态卡片
            _buildStatusCard(
              context,
              '消息转发状态',
              forwarderStatus.value,
              Icons.message,
              Colors.green,
            ),
            const SizedBox(height: AppSpacing.lg),

            // 控制面板
            _buildControlPanel(context, controller, isLoading, lastSyncTime),
            const SizedBox(height: AppSpacing.lg),

            // 连接设备列表
            _buildConnectedDevicesList(context, forwarderStatus.value),
          ],
        ),
      ),
    );
  }

  /// 构建状态卡片
  Widget _buildStatusCard(
    BuildContext context,
    String title,
    Map<String, dynamic> status,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...status.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${entry.key}:',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatValue(entry.value),
                        style: const TextStyle(
                          fontFamily: 'Monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// 构建控制面板
  Widget _buildControlPanel(
    BuildContext context,
    ProtocolControlController controller,
    ValueNotifier<bool> isLoading,
    ValueNotifier<DateTime?> lastSyncTime,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '协议控制',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                // 时间同步按钮
                ShadButton(
                  onPressed: isLoading.value
                      ? null
                      : () async {
                          isLoading.value = true;
                          try {
                            await controller.syncTimeToAllDevices();
                            lastSyncTime.value = DateTime.now();
                            _showSuccessSnackbar(context, '时间同步已发送到所有设备');
                          } catch (e) {
                            _showErrorSnackbar(context, '时间同步失败: $e');
                          } finally {
                            isLoading.value = false;
                          }
                        },
                  child: const Text('时间同步'),
                ),

                // 测试消息按钮
                ShadButton(
                  onPressed: isLoading.value
                      ? null
                      : () {
                          _showTestMessageDialog(context, controller);
                        },
                  child: const Text('发送测试消息'),
                ),
              ],
            ),
            if (isLoading.value)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (lastSyncTime.value != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  '上次同步: ${lastSyncTime.value!.toLocal().toString().substring(0, 19)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建连接设备列表
  Widget _buildConnectedDevicesList(
    BuildContext context,
    Map<String, dynamic> forwarderStatus,
  ) {
    final devices = forwarderStatus['devices'] as List<dynamic>? ?? [];

    if (devices.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.bluetooth_disabled,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('没有连接的设备', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.devices, color: Colors.blue),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '已连接设备 (${devices.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...devices.map((device) {
              final deviceMap = device as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: ListTile(
                  leading: Icon(
                    Icons.bluetooth_connected,
                    color: deviceMap['isConnected'] == true
                        ? Colors.green
                        : Colors.grey,
                  ),
                  title: Text(
                    deviceMap['name']?.toString() ?? '未知设备',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: deviceMap['isConnected'] == true
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                  subtitle: Text(
                    'ID: ${deviceMap['id']?.toString().substring(0, 8)}...',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: deviceMap['isConnected'] == true
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.error, color: Colors.orange),
                  contentPadding: EdgeInsets.zero,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// 显示测试消息对话框
  void _showTestMessageDialog(
    BuildContext context,
    ProtocolControlController controller,
  ) {
    final forwarderStatus = controller.getForwarderStatus();
    final devices = forwarderStatus['devices'] as List<dynamic>? ?? [];

    if (devices.isEmpty) {
      _showErrorSnackbar(context, '没有连接的设备');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final messageController = TextEditingController();
        final senderController = TextEditingController(text: 'test_user');

        return AlertDialog(
          title: const Text('发送测试消息'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: senderController,
                decoration: const InputDecoration(
                  labelText: '发送人ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: '消息内容',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final senderId = senderController.text.trim();
                final message = messageController.text.trim();

                if (senderId.isEmpty || message.isEmpty) {
                  _showErrorSnackbar(context, '请填写发送人ID和消息内容');
                  return;
                }

                // 这里应该实现实际的测试消息发送
                // 由于协议服务是内部实现，这里暂时只显示提示
                _showSuccessSnackbar(context, '测试消息已准备发送');
                Navigator.pop(context);
              },
              child: const Text('发送'),
            ),
          ],
        );
      },
    );
  }

  /// 显示成功提示
  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  /// 显示错误提示
  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// 格式化值
  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is Map) {
      return _formatMap(value);
    } else if (value is List) {
      return _formatList(value);
    } else if (value is String) {
      return value;
    } else {
      return value.toString();
    }
  }

  /// 格式化Map
  String _formatMap(Map<dynamic, dynamic> map) {
    if (map.isEmpty) return '{}';
    final entries = map.entries.take(3).toList();
    final items = entries
        .map((e) => '${e.key}: ${_formatValue(e.value)}')
        .join(', ');
    return map.length > 3 ? '{$items, ...}' : '{$items}';
  }

  /// 格式化List
  String _formatList(List<dynamic> list) {
    if (list.isEmpty) return '[]';
    final items = list.take(3).map(_formatValue).join(', ');
    return list.length > 3 ? '[$items, ...]' : '[$items]';
  }
}
