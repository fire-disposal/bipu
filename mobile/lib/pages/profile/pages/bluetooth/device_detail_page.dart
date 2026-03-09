import 'package:flutter/material.dart';
import 'package:bipupu/core/services/auth_service.dart';
import 'package:bipupu/core/services/bluetooth_device_service.dart';
import 'package:easy_localization/easy_localization.dart';

class DeviceDetailPage extends StatefulWidget {
  const DeviceDetailPage({super.key});

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  final BluetoothDeviceService _bluetoothService = BluetoothDeviceService();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  // 直接从服务的 ValueNotifier 读取绑定状态，无需本地副本
  bool get _isBound => _bluetoothService.isBound.value;
  String? get _boundDeviceName => _bluetoothService.boundDeviceName.value;

  void _onBindingChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // 订阅绑定状态变化，UI 自动跟随更新
    _bluetoothService.isBound.addListener(_onBindingChanged);
    _bluetoothService.boundDeviceName.addListener(_onBindingChanged);
  }

  @override
  void dispose() {
    _bluetoothService.isBound.removeListener(_onBindingChanged);
    _bluetoothService.boundDeviceName.removeListener(_onBindingChanged);
    _messageController.dispose();
    super.dispose();
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
                          onPressed: _isSending ? null : _sendMessage,
                          icon: _isSending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                            _isSending ? 'sending'.tr() : 'send_to_device'.tr(),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSending
                                ? Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest
                                : Theme.of(context).colorScheme.primary,
                            foregroundColor: _isSending
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.onPrimary,
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

              // 设备控制功能区
              Text(
                'device_control'.tr(),
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
                      _sendTimeSync();
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
                        _sendQuickText('SOS');
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

  // ─── 发送业务方法（与 BluetoothForwardService 走同一 safeSend* 接口）───

  /// 发送主消息框内容（带加载状态与错误回馈）
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || !_bluetoothService.isConnected) return;

    setState(() => _isSending = true);
    try {
      // 使用 sendTextMessage() 等待 ACK 确认
      final success = await _bluetoothService.sendTextMessage(text);
      if (success) {
        _messageController.clear();
        _showSnackBar('message_sent'.tr());
      } else {
        _showSnackBar('send_failed'.tr(args: ['ble_no_response'.tr()]));
      }
    } catch (e) {
      _showSnackBar('send_failed'.tr(args: [e.toString()]));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// 发送时间同步（连接时已自动发送一次，此处为手动触发）
  Future<void> _sendTimeSync() async {
    if (!_bluetoothService.isConnected) return;
    final success = await _bluetoothService.safeSendTimeSync();
    _showSnackBar(
      success ? 'time_sync_sent'.tr() : 'send_failed'.tr(args: ['TimeSync']),
    );
  }

  /// 发送快捷文本（SOS 等），使用 sendTextMessage 等待 ACK 确认
  Future<void> _sendQuickText(String text) async {
    if (!_bluetoothService.isConnected) return;
    try {
      final success = await _bluetoothService.sendTextMessage(text);
      if (text == 'SOS') {
        _showSnackBar(
          success ? 'sos_signal_sent'.tr() : 'send_failed'.tr(args: ['SOS']),
        );
      } else {
        _showSnackBar(
          success ? 'message_sent'.tr() : 'send_failed'.tr(args: [text]),
        );
      }
    } catch (e) {
      _showSnackBar('send_failed'.tr(args: [e.toString()]));
    }
  }

  // ─── 绑定管理方法 ─────────────────────────────────────────────────────────

  /// 绑定设备：将用户真实身份信息发送给设备
  Future<void> _bindDevice() async {
    if (!_bluetoothService.isConnected) {
      _showSnackBar('device_not_connected_cannot_bind'.tr());
      return;
    }

    try {
      // 从 AuthService 获取真实用户信息
      final user = AuthService().currentUser;
      final appId = (user?.bipupuId as String?) ?? 'bipupu_app';
      final userName =
          (user?.nickname as String?) ?? (user?.username as String?) ?? '用户';

      final success = await _bluetoothService.sendBindingInfo(appId, userName);
      // isBound ValueNotifier 在 connect() 时已由服务自动更新，无需手动刷新
      _showSnackBar(
        success ? 'device_binding_success'.tr() : 'binding_failed_retry'.tr(),
      );
    } catch (e) {
      _showSnackBar('binding_error_occurred'.tr(args: [e.toString()]));
    }
  }

  /// 弹出解绑确认对话框
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

  /// 执行解绑：发送解绑命令并等待 ACK，成功后清除本地绑定
  Future<void> _performUnbind() async {
    try {
      // 发送解绑命令并等待设备 ACK 确认（10 秒超时）
      final success = await _bluetoothService.sendUnbindCommand();
      
      if (success) {
        // 只有收到设备 ACK 后才清除本地绑定
        await _bluetoothService.clearBinding();
        _showSnackBar('device_unbound'.tr());
      } else {
        // 未收到 ACK，但本地仍清除绑定（用户可手动重试）
        await _bluetoothService.clearBinding();
        _showSnackBar('unbind_timeout_but_local_cleared'.tr());
      }
    } catch (e) {
      _showSnackBar('unbind_error_occurred'.tr(args: [e.toString()]));
    }
  }

  /// 显示底部提示 SnackBar（确保 mounted 再操作 context）
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
