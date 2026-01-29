import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/bluetooth/ble_pipeline.dart';
import '../../core/protocol/ble_protocol.dart';
import '../../core/services/toast_service.dart';

/// 简化的设备控制页面
class DeviceControlPage extends StatefulWidget {
  const DeviceControlPage({super.key});

  @override
  State<DeviceControlPage> createState() => _DeviceControlPageState();
}

class _DeviceControlPageState extends State<DeviceControlPage> {
  final BlePipeline _blePipeline = BlePipeline();
  final TextEditingController _textController = TextEditingController();

  // 参数状态
  VibrationType _vibrationType = VibrationType.none;
  ScreenEffect _screenEffect = ScreenEffect.none;

  // RGB颜色
  double _red = 0;
  double _green = 0;
  double _blue = 0;

  // 状态
  bool _timeSyncInProgress = false;
  bool _timeSyncCompleted = false;
  bool _isSendingMessage = false;

  @override
  void initState() {
    super.initState();
    _blePipeline.addListener(_onBleStateChanged);
    _triggerTimeSync();
  }

  @override
  void dispose() {
    _blePipeline.removeListener(_onBleStateChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onBleStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _triggerTimeSync() {
    if (_blePipeline.isConnected && !_timeSyncCompleted) {
      setState(() {
        _timeSyncInProgress = true;
      });

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _blePipeline.isConnected) {
          _sendTimeSync();
        }
      });
    }
  }

  Future<void> _sendTimeSync() async {
    try {
      final now = DateTime.now();
      await _blePipeline.syncTime();

      if (mounted) {
        setState(() {
          _timeSyncInProgress = false;
          _timeSyncCompleted = true;
        });

        _showSnackBar(
          'Time synchronized: ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _timeSyncInProgress = false;
        });

        _showSnackBar('Time sync failed: $e', isError: true);
      }
    }
  }

  // 文本验证
  bool _checkTextSupport(String text) {
    final unsupportedPattern = RegExp(r'[^\x00-\x7F]+'); // Non-ASCII check
    return !unsupportedPattern.hasMatch(text);
  }

  Future<void> _sendPacket() async {
    if (!_blePipeline.isConnected) {
      ToastService().showWarning('Not connected to any device');
      return;
    }

    final text = _textController.text;
    if (text.isEmpty) {
      ToastService().showInfo('Please enter some text');
      return;
    }

    // 检查不支持字符
    if (!_checkTextSupport(text)) {
      final shouldProceed = await _showCharacterWarningDialog();
      if (!shouldProceed) return;
    }

    // 显示发送状态
    setState(() {
      _isSendingMessage = true;
    });

    try {
      await _blePipeline.sendMessage(
        text: text,
        vibration: _vibrationType,
        screenEffect: _screenEffect,
        colors: [ColorData(_red.toInt(), _green.toInt(), _blue.toInt())],
      );

      _showSnackBar('Message sent successfully!');
    } catch (e) {
      _showSnackBar('Failed to send message: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
      }
    }
  }

  Future<bool> _showCharacterWarningDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Warning"),
            content: const Text(
              "Text contains characters that may not display correctly on the device (e.g. Emoji or non-ASCII). Continue?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Send Anyway"),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleDisconnect() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Disconnect?"),
        content: const Text("Do you want to disconnect from the device?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Disconnect"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _blePipeline.disconnect();
      if (mounted) {
        context.pushReplacement('/bluetooth/scan');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Control'),
        actions: [
          if (_blePipeline.isConnected)
            Row(
              children: [
                if (_timeSyncInProgress)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.bluetooth_connected),
                  tooltip:
                      "Connected to ${_blePipeline.connectedDevice?.platformName ?? 'Unknown'}",
                  onPressed: _handleDisconnect,
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              onPressed: () {},
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 连接状态卡片
            _buildConnectionStatusCard(),

            // 时间同步状态
            _buildTimeSyncIndicator(),

            const SizedBox(height: 16),

            // 消息控制
            const Text(
              'Message',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildMessageInput(),

            const SizedBox(height: 20),

            // 效果控制
            _buildEffectsControl(),

            const SizedBox(height: 20),

            // LED颜色控制
            _buildColorControl(),

            const SizedBox(height: 30),

            // 发送按钮
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard() {
    if (!_blePipeline.isConnected) {
      return Container(
        padding: const EdgeInsets.all(12),
        color: Colors.red.withValues(alpha: 0.1),
        child: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text(
              "Device disconnected. Please keep safe.",
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTimeSyncIndicator() {
    if (_timeSyncInProgress) {
      return Container(
        padding: const EdgeInsets.all(12),
        color: Colors.blue.withValues(alpha: 0.1),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              "Synchronizing time...",
              style: TextStyle(color: Colors.blue.shade700),
            ),
          ],
        ),
      );
    } else if (_timeSyncCompleted) {
      return Container(
        padding: const EdgeInsets.all(12),
        color: Colors.green.withValues(alpha: 0.1),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              "Time synchronized successfully",
              style: TextStyle(color: Colors.green.shade700),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Message',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              hintText: 'Type your message here...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            ),
            maxLines: 3,
            style: const TextStyle(fontSize: 16),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'ASCII characters recommended for best compatibility',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEffectsControl() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Effects',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildEffectDropdown<VibrationType>(
                  'Vibration',
                  _vibrationType,
                  VibrationType.values,
                  _getVibrationTypeName,
                  (value) => setState(() => _vibrationType = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEffectDropdown<ScreenEffect>(
                  'Screen FX',
                  _screenEffect,
                  ScreenEffect.values,
                  _getScreenEffectName,
                  (value) => setState(() => _screenEffect = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorControl() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LED Color',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          _buildColorSliders(),
        ],
      ),
    );
  }

  Widget _buildColorSliders() {
    return Column(
      children: [
        _buildColorSlider(
          'R',
          _red,
          Colors.red,
          (v) => setState(() => _red = v),
        ),
        _buildColorSlider(
          'G',
          _green,
          Colors.green,
          (v) => setState(() => _green = v),
        ),
        _buildColorSlider(
          'B',
          _blue,
          Colors.blue,
          (v) => setState(() => _blue = v),
        ),
        const SizedBox(height: 12),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Color.fromRGBO(
              _red.toInt(),
              _green.toInt(),
              _blue.toInt(),
              1,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Preview',
              style: TextStyle(
                color: (_red + _green + _blue) > 384
                    ? Colors.black
                    : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSlider(
    String label,
    double value,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Slider(
              value: value,
              min: 0,
              max: 255,
              activeColor: color,
              inactiveColor: Colors.grey.shade300,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (_blePipeline.isConnected && !_isSendingMessage)
            ? _sendPacket
            : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: _blePipeline.isConnected && !_isSendingMessage
              ? Theme.of(context).primaryColor
              : Colors.grey.shade400,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: (_blePipeline.isConnected && !_isSendingMessage) ? 2 : 0,
        ),
        icon: _isSendingMessage
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.send, size: 20),
        label: Text(
          _isSendingMessage ? 'Sending...' : 'Send Message',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  String _getVibrationTypeName(VibrationType type) {
    return type.toString().split('.').last;
  }

  String _getScreenEffectName(ScreenEffect effect) {
    return effect.toString().split('.').last;
  }

  Widget _buildEffectDropdown<T>(
    String label,
    T value,
    List<T> items,
    String Function(T) getName,
    ValueChanged<T> onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, size: 20),
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            items: items.map((T item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(getName(item)),
              );
            }).toList(),
            onChanged: (T? newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
          ),
        ),
      ),
    );
  }
}
