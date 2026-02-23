import 'package:flutter/material.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../core/bluetooth/ble_manager.dart';
import '../../../core/bluetooth/ble_provider.dart';
import '../../../core/theme/design_system.dart';

/// 蓝牙扫描页面
class BluetoothScanScreen extends HookConsumerWidget {
  const BluetoothScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleManager = ref.watch(bleManagerProvider);
    final asyncScanState = ref.watch(bleScannerProvider);
    final asyncAdapterState = ref.watch(bleAdapterStateProvider);
    final asyncConnectedDevices = ref.watch(bleConnectedDevicesProvider);

    // 扫描控制
    final isScanning = asyncScanState.isScanning;
    final scanResults = asyncScanState.results;

    // 连接状态
    final bleDevices = asyncConnectedDevices.value ?? [];
    // 转换为BluetoothDevice列表用于显示
    final connectedDevices = bleDevices.map((bleDevice) {
      return BluetoothDevice(remoteId: DeviceIdentifier(bleDevice.id));
    }).toList();

    // 开始扫描
    void startScan() async {
      try {
        await bleManager.startScan();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('开始扫描失败: $e'), backgroundColor: Colors.red),
        );
      }
    }

    // 停止扫描
    void stopScan() async {
      try {
        await bleManager.stopScan();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('停止扫描失败: $e'), backgroundColor: Colors.red),
        );
      }
    }

    // 连接设备
    Future<void> connectToDevice(BleDevice device) async {
      try {
        await bleManager.connect(device.id);
        // 连接成功后返回
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('连接失败: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    // 断开设备
    Future<void> disconnectDevice(BleDevice device) async {
      try {
        await bleManager.disconnect(device.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('断开失败: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('蓝牙设备扫描'),
        centerTitle: true,
        actions: [
          // 扫描控制按钮
          IconButton(
            icon: Icon(isScanning ? Icons.stop : Icons.search),
            onPressed: () {
              if (isScanning) {
                stopScan();
              } else {
                startScan();
              }
            },
            tooltip: isScanning ? '停止扫描' : '开始扫描',
          ),
        ],
      ),
      body: asyncAdapterState.when(
        data: (adapterState) {
          // 检查蓝牙状态
          if (adapterState != BluetoothAdapterState.on) {
            return _buildBluetoothOffState(context);
          }

          return Column(
            children: [
              // 状态栏
              _buildStatusBar(context, isScanning, connectedDevices),

              // 设备列表
              Expanded(
                child: _buildDeviceList(
                  context,
                  scanResults,
                  connectedDevices,
                  connectToDevice,
                  disconnectDevice,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
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
                '蓝牙状态获取失败',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建蓝牙关闭状态
  Widget _buildBluetoothOffState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_disabled,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '蓝牙未开启',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '请开启设备的蓝牙功能以扫描和连接设备',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () {
                // TODO: 打开蓝牙设置
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('请手动开启蓝牙')));
              },
              child: const Text('开启蓝牙'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建状态栏
  Widget _buildStatusBar(
    BuildContext context,
    bool isScanning,
    List<BluetoothDevice> connectedDevices,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 扫描状态
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isScanning ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isScanning ? '扫描中...' : '已停止',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),

          // 设备计数
          Text(
            '已连接: ${connectedDevices.length}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建设备列表
  Widget _buildDeviceList(
    BuildContext context,
    List<BleScanResult> scanResults,
    List<BluetoothDevice> connectedDevices,
    Future<void> Function(BleDevice) onConnect,
    Future<void> Function(BleDevice) onDisconnect,
  ) {
    if (scanResults.isEmpty) {
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
              '未发现设备',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '请确保设备已开启并处于可被发现状态',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: scanResults.length,
      itemBuilder: (context, index) {
        final result = scanResults[index];
        final device = result.device;
        final isConnected = connectedDevices.any(
          (d) => d.remoteId.str == device.id,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ListTile(
            leading: Icon(
              Icons.bluetooth,
              color: isConnected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
            title: Text(
              device.name.isNotEmpty ? device.name : '未知设备',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'ID: ${device.id}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontFamily: 'Monospace',
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.signal_cellular_alt,
                      size: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${device.rssi} dBm',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '发现于: ${_formatTime(result.timestamp)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: isConnected
                ? OutlinedButton(
                    onPressed: () => onDisconnect(device),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    child: const Text('断开'),
                  )
                : ElevatedButton(
                    onPressed: () => onConnect(device),
                    child: const Text('连接'),
                  ),
            onTap: () {
              // 显示设备详情
              _showDeviceDetails(context, result, isConnected);
            },
          ),
        );
      },
    );
  }

  /// 格式化时间
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}秒前';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else {
      return '${difference.inDays}天前';
    }
  }

  /// 显示设备详情
  void _showDeviceDetails(
    BuildContext context,
    BleScanResult result,
    bool isConnected,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '设备详情',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // 设备信息
              _buildDetailItem(context, '设备名称', result.device.name),
              _buildDetailItem(context, '设备ID', result.device.id),
              _buildDetailItem(context, '信号强度', '${result.device.rssi} dBm'),
              _buildDetailItem(
                context,
                '发现时间',
                '${_formatTime(result.timestamp)} (${result.timestamp.toLocal()})',
              ),
              _buildDetailItem(context, '连接状态', isConnected ? '已连接' : '未连接'),

              // 服务信息
              if (result.advertisedServices.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  '广播服务:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: AppSpacing.xs),
                ...result.advertisedServices.map((service) {
                  return Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.md),
                    child: Text(
                      service.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontFamily: 'Monospace',
                      ),
                    ),
                  );
                }).toList(),
              ],

              const SizedBox(height: AppSpacing.lg),

              // 操作按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('关闭'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建详情项
  Widget _buildDetailItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
