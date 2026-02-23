import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/bluetooth/ble_manager.dart';
import '../../../../core/theme/design_system.dart';

/// 蓝牙状态卡片组件
class BluetoothStatusCard extends HookConsumerWidget {
  /// 点击连接按钮回调
  final VoidCallback? onConnectPressed;

  /// 点击控制按钮回调
  final VoidCallback? onControlPressed;

  const BluetoothStatusCard({
    super.key,
    this.onConnectPressed,
    this.onControlPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听连接状态
    final asyncConnectionState = ref.watch(bleConnectionStateProvider);
    // 监听已连接设备
    final asyncConnectedDevices = ref.watch(bleConnectedDevicesProvider);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '蓝牙设备',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _buildStatusIndicator(context, asyncConnectionState.value),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // 设备信息
            asyncConnectedDevices.when(
              data: (devices) {
                if (devices.isEmpty) {
                  return _buildNoDeviceInfo(context);
                }
                // 显示第一个连接的设备
                final device = devices.first;
                return _buildDeviceInfo(context, device);
              },
              loading: () => _buildLoadingInfo(context),
              error: (error, stack) => _buildErrorInfo(context, error),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 操作按钮
            _buildActionButton(
              context,
              asyncConnectionState.value,
              asyncConnectedDevices.value,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建状态指示器
  Widget _buildStatusIndicator(
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

  /// 构建无设备信息
  Widget _buildNoDeviceInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '未连接设备',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '点击下方按钮扫描并连接设备',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  /// 构建设备信息
  Widget _buildDeviceInfo(BuildContext context, BleDevice device) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          device.name.isNotEmpty ? device.name : '未知设备',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'ID: ${device.id}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
            fontFamily: 'Monospace',
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '信号强度: ${device.rssi} dBm',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  /// 构建加载信息
  Widget _buildLoadingInfo(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          '加载设备信息...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  /// 构建错误信息
  Widget _buildErrorInfo(BuildContext context, Object error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 16,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '加载失败',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          error.toString(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.error.withOpacity(0.8),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton(
    BuildContext context,
    BleConnectionState? connectionState,
    List<BleDevice>? connectedDevices,
  ) {
    final isConnected =
        connectionState == BleConnectionState.connected &&
        connectedDevices != null &&
        connectedDevices.isNotEmpty;

    if (isConnected) {
      // 已连接状态 - 显示控制按钮
      return ElevatedButton(
        onPressed: onControlPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings_remote, size: 20),
            SizedBox(width: AppSpacing.sm),
            Text('设备控制'),
          ],
        ),
      );
    } else {
      // 未连接状态 - 显示连接按钮
      final isConnecting = connectionState == BleConnectionState.connecting;

      return ElevatedButton(
        onPressed: isConnecting ? null : onConnectPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          backgroundColor: isConnecting
              ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
              : Theme.of(context).colorScheme.primary,
          foregroundColor: isConnecting
              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
              : Theme.of(context).colorScheme.onPrimary,
        ),
        child: isConnecting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('连接中...'),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bluetooth, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Text('连接设备'),
                ],
              ),
      );
    }
  }
}
