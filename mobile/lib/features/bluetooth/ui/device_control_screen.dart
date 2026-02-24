import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../core/bluetooth/ble_manager.dart';

import '../../../core/theme/design_system.dart';

/// 设备控制页面
class DeviceControlScreen extends HookConsumerWidget {
  final String deviceId;
  final String deviceName;

  const DeviceControlScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleManager = ref.watch(bleManagerProvider);
    final asyncConnectionState = ref.watch(bleConnectionStateProvider);
    final asyncServices = useState<List<BluetoothService>?>(null);
    final isLoadingServices = useState(false);
    final errorMessage = useState<String?>(null);

    // 加载设备服务
    Future<void> loadServices() async {
      isLoadingServices.value = true;
      errorMessage.value = null;

      try {
        final services = await bleManager.getServices(deviceId);
        asyncServices.value = services;
      } catch (e) {
        errorMessage.value = '加载服务失败: $e';
      } finally {
        isLoadingServices.value = false;
      }
    }

    // 初始化加载服务
    useEffect(() {
      loadServices();
      return null;
    }, []);

    // 断开连接
    Future<void> disconnect() async {
      try {
        await bleManager.disconnect(deviceId);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('断开连接失败: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    // 发送命令
    Future<void> sendCommand(
      String serviceUuid,
      String characteristicUuid,
      List<int> data,
    ) async {
      try {
        await bleManager.writeCharacteristic(
          deviceId,
          serviceUuid,
          characteristicUuid,
          data,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('命令发送成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('命令发送失败: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('设备控制'),
        centerTitle: true,
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadServices,
            tooltip: '刷新服务',
          ),
        ],
      ),
      body: Column(
        children: [
          // 设备信息卡片
          _buildDeviceInfoCard(
            context,
            deviceId,
            deviceName,
            asyncConnectionState.value,
          ),

          // 控制面板
          Expanded(
            child: _buildControlPanel(
              context,
              asyncServices.value,
              isLoadingServices.value,
              errorMessage.value,
              sendCommand,
            ),
          ),

          // 操作按钮
          _buildActionButtons(context, disconnect),
        ],
      ),
    );
  }

  /// 构建设备信息卡片
  Widget _buildDeviceInfoCard(
    BuildContext context,
    String deviceId,
    String deviceName,
    BleConnectionState? connectionState,
  ) {
    return Card(
      margin: const EdgeInsets.all(AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 设备名称和状态
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    deviceName.isNotEmpty ? deviceName : '未知设备',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildConnectionStatus(context, connectionState),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // 设备详情
            _buildDetailRow(context, '设备ID', deviceId),
            _buildDetailRow(context, '信号强度', 'N/A dBm'),
            _buildDetailRow(context, '设备类型', deviceName),
          ],
        ),
      ),
    );
  }

  /// 构建连接状态指示器
  Widget _buildConnectionStatus(
    BuildContext context,
    BleConnectionState? connectionState,
  ) {
    Color color;
    String text;

    switch (connectionState) {
      case BleConnectionState.connected:
        color = Colors.green;
        text = '已连接';
        break;
      case BleConnectionState.connecting:
        color = Colors.orange;
        text = '连接中';
        break;
      case BleConnectionState.disconnecting:
        color = Colors.orange;
        text = '断开中';
        break;
      case BleConnectionState.error:
        color = Colors.red;
        text = '错误';
        break;
      case BleConnectionState.disconnected:
      default:
        color = Colors.grey;
        text = '未连接';
        break;
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 构建详情行
  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontFamily: 'Monospace'),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建控制面板
  Widget _buildControlPanel(
    BuildContext context,
    List<BluetoothService>? services,
    bool isLoading,
    String? errorMessage,
    Future<void> Function(String, String, List<int>) onSendCommand,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '加载失败',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                errorMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () {
                  // 重试加载
                  // 这里需要从外部调用 loadServices
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (services == null || services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_other,
              size: 64,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '未发现服务',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '该设备可能没有可用的蓝牙服务',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // 服务列表
        Text(
          '可用服务 (${services.length})',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),

        ...services.map((service) {
          return _buildServiceCard(context, service, onSendCommand);
        }).toList(),

        // 自定义命令
        const SizedBox(height: AppSpacing.xl),
        _buildCustomCommandCard(context, onSendCommand),
      ],
    );
  }

  /// 构建服务卡片
  Widget _buildServiceCard(
    BuildContext context,
    BluetoothService service,
    Future<void> Function(String, String, List<int>) onSendCommand,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExpansionTile(
        leading: const Icon(Icons.settings_input_component),
        title: Text(
          '服务: ${service.uuid.str.substring(0, 8)}...',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '特性: ${service.characteristics.length}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 服务UUID
                _buildUuidRow(context, '服务UUID', service.uuid.str),

                const SizedBox(height: AppSpacing.md),

                // 特性列表
                if (service.characteristics.isNotEmpty) ...[
                  Text(
                    '特性列表:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...service.characteristics.map((characteristic) {
                    return _buildCharacteristicItem(
                      context,
                      characteristic,
                      service.uuid.str,
                      onSendCommand,
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建UUID行
  Widget _buildUuidRow(BuildContext context, String label, String uuid) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            uuid,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontFamily: 'Monospace'),
          ),
        ),
      ],
    );
  }

  /// 构建特性项
  Widget _buildCharacteristicItem(
    BuildContext context,
    BluetoothCharacteristic characteristic,
    String serviceUuid,
    Future<void> Function(String, String, List<int>) onSendCommand,
  ) {
    final canWrite =
        characteristic.properties.write ||
        characteristic.properties.writeWithoutResponse;
    final canRead = characteristic.properties.read;
    final canNotify =
        characteristic.properties.notify || characteristic.properties.indicate;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 特性UUID
            _buildUuidRow(context, '特性UUID', characteristic.uuid.str),

            const SizedBox(height: AppSpacing.sm),

            // 特性属性
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (canRead) _buildPropertyChip(context, '读取', Colors.blue),
                if (canWrite) _buildPropertyChip(context, '写入', Colors.green),
                if (canNotify) _buildPropertyChip(context, '通知', Colors.orange),
                if (characteristic.properties.broadcast)
                  _buildPropertyChip(context, '广播', Colors.purple),
                if (characteristic.properties.extendedProperties)
                  _buildPropertyChip(context, '扩展', Colors.teal),
              ],
            ),

            // 操作按钮
            if (canWrite) ...[
              const SizedBox(height: AppSpacing.md),
              _buildCommandButtons(
                context,
                serviceUuid,
                characteristic.uuid.str,
                onSendCommand,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建属性芯片
  Widget _buildPropertyChip(BuildContext context, String text, Color color) {
    return Chip(
      label: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: Colors.white),
      ),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  /// 构建命令按钮
  Widget _buildCommandButtons(
    BuildContext context,
    String serviceUuid,
    String characteristicUuid,
    Future<void> Function(String, String, List<int>) onSendCommand,
  ) {
    // 预定义命令
    final commands = [
      {
        'label': '开灯',
        'data': [0x01],
      },
      {
        'label': '关灯',
        'data': [0x00],
      },
      {
        'label': '蜂鸣',
        'data': [0x02],
      },
      {
        'label': '振动',
        'data': [0x03],
      },
      {
        'label': '测试',
        'data': [0xFF],
      },
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: commands.map((command) {
        return ElevatedButton(
          onPressed: () => onSendCommand(
            serviceUuid,
            characteristicUuid,
            command['data'] as List<int>,
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 36),
          ),
          child: Text(command['label'] as String),
        );
      }).toList(),
    );
  }

  /// 构建自定义命令卡片
  Widget _buildCustomCommandCard(
    BuildContext context,
    Future<void> Function(String, String, List<int>) onSendCommand,
  ) {
    final serviceUuidController = useTextEditingController();
    final characteristicUuidController = useTextEditingController();
    final commandController = useTextEditingController();
    final isSending = useState(false);

    Future<void> sendCustomCommand() async {
      if (serviceUuidController.text.isEmpty ||
          characteristicUuidController.text.isEmpty ||
          commandController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请填写所有字段'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      try {
        isSending.value = true;

        // 解析命令数据（支持十六进制和十进制）
        List<int> data;
        final commandText = commandController.text.trim();

        if (commandText.startsWith('0x')) {
          // 十六进制格式: 0x01 0x02 0xFF
          data = commandText
              .split(' ')
              .where((hex) => hex.isNotEmpty)
              .map((hex) => int.parse(hex.replaceFirst('0x', ''), radix: 16))
              .toList();
        } else {
          // 十进制格式: 1,2,255
          data = commandText
              .split(',')
              .where((number) => number.isNotEmpty)
              .map((number) => int.parse(number.trim()))
              .toList();
        }

        await onSendCommand(
          serviceUuidController.text.trim(),
          characteristicUuidController.text.trim(),
          data,
        );

        // 清空命令输入
        commandController.clear();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('命令格式错误: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        isSending.value = false;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '自定义命令',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.md),

            // 服务UUID输入
            TextField(
              controller: serviceUuidController,
              decoration: const InputDecoration(
                labelText: '服务UUID',
                hintText: '例如: 0000ffe0-0000-1000-8000-00805f9b34fb',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 特性UUID输入
            TextField(
              controller: characteristicUuidController,
              decoration: const InputDecoration(
                labelText: '特性UUID',
                hintText: '例如: 0000ffe1-0000-1000-8000-00805f9b34fb',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 命令数据输入
            TextField(
              controller: commandController,
              decoration: const InputDecoration(
                labelText: '命令数据',
                hintText: '十六进制: 0x01 0x02 0xFF 或 十进制: 1,2,255',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 发送按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSending.value ? null : sendCustomCommand,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: isSending.value
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text('发送中...'),
                        ],
                      )
                    : const Text('发送自定义命令'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(
    BuildContext context,
    Future<void> Function() onDisconnect,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onDisconnect,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bluetooth_disabled, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Text('断开连接'),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // 返回首页
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Text('返回首页'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
