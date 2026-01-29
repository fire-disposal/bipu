import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/bluetooth/ble_ui_components.dart';
import '../../core/bluetooth/ble_state_manager.dart';
import '../../services/ble_service.dart';
import '../../core/protocol/ble_protocol.dart';
import '../../core/services/toast_service.dart';

/// 重构后的设备控制页面
class DeviceControlPage extends StatefulWidget {
  const DeviceControlPage({super.key});

  @override
  State<DeviceControlPage> createState() => _DeviceControlPageState();
}

class _DeviceControlPageState extends State<DeviceControlPage> {
  final BleService _bleService = BleService();
  final TextEditingController _textController = TextEditingController();

  // 参数状态
  VibrationType _vibrationType = VibrationType.none;
  ScreenEffect _screenEffect = ScreenEffect.none;

  // RGB颜色
  double _red = 0;
  double _green = 0;
  double _blue = 0;

  // 时间同步状态
  bool _timeSyncInProgress = false;
  bool _timeSyncCompleted = false;

  @override
  void initState() {
    super.initState();
    _bleService.stateManager.addListener(_onBleStateChanged);
    _triggerTimeSync();
  }

  @override
  void dispose() {
    _bleService.stateManager.removeListener(_onBleStateChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onBleStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _triggerTimeSync() {
    if (_bleService.isConnected && !_timeSyncCompleted) {
      setState(() {
        _timeSyncInProgress = true;
      });

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _bleService.isConnected) {
          _sendTimeSync();
        }
      });
    }
  }

  Future<void> _sendTimeSync() async {
    try {
      final now = DateTime.now();
      await _bleService.syncTime();

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
    if (!_bleService.isConnected) {
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

    try {
      await _bleService.sendProtocolMessage(
        text: text,
        vibration: _vibrationType,
        screenEffect: _screenEffect,
        colors: [ColorData(_red.toInt(), _green.toInt(), _blue.toInt())],
      );

      _showSnackBar('Packet sent successfully');
    } catch (e) {
      _showSnackBar('Failed to send packet: $e', isError: true);
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
      await _bleService.disconnect();
      if (mounted) {
        context.pop(); // Go back to scan page
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateManager = _bleService.stateManager;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Control'),
        actions: [
          if (_bleService.isConnected)
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
                      "Connected to ${stateManager.connectedDevice?.platformName ?? 'Unknown'}",
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
            BleConnectionCard(
              stateManager: stateManager,
              onDisconnect: _handleDisconnect,
            ),

            // 时间同步状态
            BleTimeSyncIndicator(
              isInProgress: _timeSyncInProgress,
              isCompleted: _timeSyncCompleted,
            ),

            const SizedBox(height: 20),

            // 消息控制
            const Text(
              'Messaging',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Text to Send',
                hintText: 'Type text here...',
                border: OutlineInputBorder(),
                helperText:
                    "Some special characters may not adhere to BIPI display standards.",
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 20),

            // 效果控制
            const Text(
              'Effects',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<VibrationType>(
                    value: _vibrationType,
                    decoration: const InputDecoration(
                      labelText: 'Vibration',
                      border: OutlineInputBorder(),
                    ),
                    items: VibrationType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getVibrationTypeName(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _vibrationType = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<ScreenEffect>(
                    value: _screenEffect,
                    decoration: const InputDecoration(
                      labelText: 'Screen FX',
                      border: OutlineInputBorder(),
                    ),
                    items: ScreenEffect.values.map((effect) {
                      return DropdownMenuItem(
                        value: effect,
                        child: Text(_getScreenEffectName(effect)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _screenEffect = value);
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // LED颜色控制
            const Text(
              'LED Color',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            _buildColorControl(),

            const SizedBox(height: 30),

            // 发送按钮
            ElevatedButton.icon(
              onPressed: _bleService.isConnected ? _sendPacket : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.send),
              label: const Text('Send to Device'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorControl() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
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
          const SizedBox(height: 8),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Color.fromRGBO(
                _red.toInt(),
                _green.toInt(),
                _blue.toInt(),
                1,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSlider(
    String label,
    double value,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 255,
            activeColor: color,
            onChanged: onChanged,
          ),
        ),
        Text(
          value.toInt().toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _getVibrationTypeName(VibrationType type) {
    return type.toString().split('.').last;
  }

  String _getScreenEffectName(ScreenEffect effect) {
    return effect.toString().split('.').last;
  }
}
