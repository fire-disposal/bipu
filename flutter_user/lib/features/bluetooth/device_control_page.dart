import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/toast_service.dart';
import '../../core/protocol/ble_protocol.dart';
import '../../services/ble_service.dart';

class DeviceControlPage extends StatefulWidget {
  const DeviceControlPage({super.key});

  @override
  State<DeviceControlPage> createState() => _DeviceControlPageState();
}

class _DeviceControlPageState extends State<DeviceControlPage> {
  final BleService _bleService = BleService();
  final TextEditingController _textController = TextEditingController();

  // Parameters
  VibrationType _vibrationType = VibrationType.none;
  ScreenEffect _screenEffect = ScreenEffect.none;

  // RGB Colors
  double _red = 0;
  double _green = 0;
  double _blue = 0;

  @override
  void initState() {
    super.initState();
    _bleService.addListener(_onBleStateChanged);
  }

  @override
  void dispose() {
    _bleService.removeListener(_onBleStateChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onBleStateChanged() {
    if (mounted) setState(() {});
  }

  // Pre-check hook for unsupported characters
  bool _checkTextSupport(String text) {
    // Determine which characters are not supported.
    // For this example, let's assume only ASCII is supported perfectly,
    // and we want to warn about non-ASCII for now (as a placeholder logic).
    // Or simpler: warn about Emoji.

    // Regex for detecting simple emoji or non-basic-multilingual-plane chars if needed.
    // Let's assume the MCU supports Latin-1 or similar.

    // For demonstration, let's just warn if the text contains any Emoji or non-ASCII
    // just to fulfill the "Pre-prepare checker hook" requirement.
    // Hook implementation:
    final unsupportedPattern = RegExp(r'[^\x00-\x7F]+'); // Non-ASCII check

    if (unsupportedPattern.hasMatch(text)) {
      // Logic for warning
      return false;
    }
    return true;
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

    // Check unsupported characters
    if (!_checkTextSupport(text)) {
      bool proceed =
          await showDialog(
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

      if (!proceed) return;
    }

    try {
      final packet = BleProtocol.createPacket(
        text: text,
        vibration: _vibrationType,
        screenEffect: _screenEffect,
        colors: [ColorData(_red.toInt(), _green.toInt(), _blue.toInt())],
      );

      await _bleService.sendData(packet);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Packet sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send packet: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectedDevice = _bleService.connectedDevice;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Control'),
        actions: [
          if (_bleService.isConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth_connected),
              tooltip:
                  "Connected: ${connectedDevice?.platformName ?? 'Unknown'}",
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Disconnect?"),
                    content: const Text(
                      "Do you want to disconnect from the device?",
                    ),
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
                  if (context.mounted) {
                    context.pop(); // Go back to scan page
                  }
                }
              },
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
            if (!_bleService.isConnected)
              Container(
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
              ),

            const SizedBox(height: 20),

            // Message Controls
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

            // Effects Section
            const Text(
              'Effects',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<VibrationType>(
                    initialValue: _vibrationType,
                    decoration: const InputDecoration(
                      labelText: 'Vibration',
                      border: OutlineInputBorder(),
                    ),
                    items: VibrationType.values.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(e.toString().split('.').last),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _vibrationType = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<ScreenEffect>(
                    initialValue: _screenEffect,
                    decoration: const InputDecoration(
                      labelText: 'Screen FX',
                      border: OutlineInputBorder(),
                    ),
                    items: ScreenEffect.values.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(e.toString().split('.').last),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _screenEffect = v!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Text(
              'LED Color',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildColorSlider(
                    "R",
                    _red,
                    Colors.red,
                    (v) => setState(() => _red = v),
                  ),
                  _buildColorSlider(
                    "G",
                    _green,
                    Colors.green,
                    (v) => setState(() => _green = v),
                  ),
                  _buildColorSlider(
                    "B",
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
            ),

            const SizedBox(height: 30),

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
}
