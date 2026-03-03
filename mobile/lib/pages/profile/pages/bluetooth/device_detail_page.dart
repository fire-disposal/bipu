import 'package:flutter/material.dart';
import 'package:bipupu/core/services/bluetooth_device_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class DeviceDetailPage extends StatefulWidget {
  const DeviceDetailPage({super.key});

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  final BluetoothDeviceService _bluetoothService = BluetoothDeviceService();
  final TextEditingController _messageController = TextEditingController();
  bool _isBound = false;
  String? _boundDeviceName;

  @override
  void initState() {
    super.initState();
    _loadBindingInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设备控制'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          // 绑定/解绑按钮
          IconButton(
            icon: Icon(
              _isBound ? Icons.link_off : Icons.link,
              color: _isBound
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
            onPressed: _isBound ? _unbindDevice : _bindDevice,
            tooltip: _isBound ? 'unbind_device'.tr() : 'bind_device'.tr(),
          ),
          // 断开连接按钮
          IconButton(
            icon: Icon(
              Icons.bluetooth_disabled,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              final currentContext = context;
              await _bluetoothService.disconnect();
              if (mounted) {
                Navigator.of(currentContext).pop();
              }
            },
            tooltip: 'disconnect'.tr(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 设备状态卡片
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.bluetooth_connected,
                              color: Colors.green,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'device_connected'.tr(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'can_send_text_messages'.tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 绑定状态显示
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _isBound
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isBound ? Colors.blue : Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isBound ? Icons.link : Icons.link_off,
                              color: _isBound ? Colors.blue : Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isBound
                                    ? 'bound_to'.tr(
                                        args: [
                                          _boundDeviceName ??
                                              'current_device'.tr(),
                                        ],
                                      )
                                    : 'not_bound'.tr(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _isBound
                                      ? Colors.blue
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 消息发送区域
              Text(
                'message_sending'.tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          labelText: 'enter_message_to_send'.tr(),
                          hintText: 'enter_message_content_here'.tr(),
                          prefixIcon: const Icon(Icons.message),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_messageController.text.isNotEmpty) {
                              _bluetoothService.sendTextMessage(
                                _messageController.text,
                              );
                              _messageController.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('消息已发送！'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.send),
                          label: Text('send_to_device'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 消息发送区域
              Text(
                'message_sending'.tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildControlButton(
                    icon: Icons.access_time,
                    label: 'sync_time'.tr(),
                    color: Colors.blue,
                    onPressed: () {
                      _bluetoothService.sendTimeSync();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('时间同步命令已发送！'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  _buildControlButton(
                    icon: Icons.refresh,
                    label: 'restart_device'.tr(),
                    color: Colors.orange,
                    onPressed: () {
                      // TODO: 实现重启设备功能
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('重启命令已发送！'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  _buildControlButton(
                    icon: Icons.volume_up,
                    label: 'volume_control'.tr(),
                    color: Colors.green,
                    onPressed: () {
                      // TODO: 实现音量控制功能
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('音量控制功能开发中...'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  _buildControlButton(
                    icon: Icons.settings,
                    label: 'device_settings'.tr(),
                    color: Colors.purple,
                    onPressed: () {
                      // TODO: 实现设备设置功能
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('设备设置功能开发中...'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 快速操作区域
              Text(
                'quick_actions'.tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.emergency,
                      label: 'SOS'.tr(),
                      color: Colors.red,
                      onPressed: () {
                        _bluetoothService.sendTextMessage('SOS');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('SOS信号已发送！'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.location_on,
                      label: 'location'.tr(),
                      color: Colors.teal,
                      onPressed: () {
                        // TODO: 实现位置共享功能
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('位置共享功能开发中...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 加载绑定信息
  Future<void> _loadBindingInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final boundId = prefs.getString('bluetooth_binding_info');
    final boundName = prefs.getString('bluetooth_binding_info_name');

    setState(() {
      _isBound = boundId != null;
      _boundDeviceName = boundName;
    });
  }

  /// 绑定设备
  Future<void> _bindDevice() async {
    if (!_bluetoothService.isConnected) {
      _showSnackBar('device_not_connected_cannot_bind'.tr());
      return;
    }

    try {
      // 发送绑定信息到设备
      final success = await _bluetoothService.sendBindingInfo(
        'bipupu_app',
        '用户设备',
      );

      if (success) {
        // 绑定信息会自动保存到本地
        await _loadBindingInfo();
        _showSnackBar('device_binding_success'.tr());
      } else {
        _showSnackBar('binding_failed_retry'.tr());
      }
    } catch (e) {
      _showSnackBar('binding_error_occurred'.tr(args: [e.toString()]));
    }
  }

  /// 解绑设备
  Future<void> _unbindDevice() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('unbind_confirmation'.tr()),
        content: Text('confirm_unbind_device'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performUnbind();
            },
            child: Text(
              'unbind'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// 执行解绑操作
  Future<void> _performUnbind() async {
    try {
      // 发送解绑命令到设备
      final success = await _bluetoothService.sendUnbindCommand();

      // 清除本地绑定
      await _bluetoothService.clearBinding();

      // 更新UI状态
      await _loadBindingInfo();

      if (success) {
        _showSnackBar('device_unbound'.tr());
      } else {
        _showSnackBar('local_binding_cleared_device_unbind_failed'.tr());
      }
    } catch (e) {
      _showSnackBar('unbind_error_occurred'.tr(args: [e.toString()]));
    }
  }

  /// 显示提示消息
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
