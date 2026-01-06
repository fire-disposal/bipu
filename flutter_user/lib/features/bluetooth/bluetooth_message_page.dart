import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_core/core/protocol/ble_protocol.dart';
import '../../services/ble_service.dart';

class BluetoothMessagePage extends StatefulWidget {
  const BluetoothMessagePage({super.key});

  @override
  State<BluetoothMessagePage> createState() => _BluetoothMessagePageState();
}

class _BluetoothMessagePageState extends State<BluetoothMessagePage> {
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

  Future<void> _scan() async {
    await _bleService.startScan();
  }

  Future<void> _connect(BluetoothDevice device) async {
    try {
      await _bleService.connect(device);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to ${device.platformName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
      }
    }
  }

  Future<void> _sendPacket() async {
    if (!_bleService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not connected to any device')),
      );
      return;
    }

    try {
      final packet = BleProtocol.createPacket(
        text: _textController.text,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Message'),
        actions: [
          if (_bleService.isConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth_connected),
              onPressed: () => _bleService.disconnect(),
            )
          else
            IconButton(icon: const Icon(Icons.refresh), onPressed: _scan),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeviceSection(),
            const Divider(height: 32),
            _buildControlSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceSection() {
    if (_bleService.isConnected) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Card(
        color: isDark
            ? Colors.green.shade900.withOpacity(0.3)
            : Colors.green.shade100,
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                Icons.bluetooth_connected,
                color: isDark ? Colors.greenAccent : Colors.green,
              ),
              title: Text(
                _bleService.connectedDevice?.platformName ?? 'Unknown Device',
              ),
              subtitle: Text(
                _bleService.connectedDevice?.remoteId.toString() ?? '',
              ),
              trailing: TextButton(
                onPressed: () => _bleService.disconnect(),
                child: const Text('Disconnect'),
              ),
            ),
            if (_bleService.batteryLevel != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Icon(
                      _bleService.batteryLevel! > 20
                          ? Icons.battery_full
                          : Icons.battery_alert,
                      color: _bleService.batteryLevel! > 20
                          ? (isDark ? Colors.greenAccent : Colors.green)
                          : (isDark ? Colors.redAccent : Colors.red),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Battery: ${_bleService.batteryLevel}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Available Devices',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_bleService.isScanning)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _bleService.scanResults.isEmpty
              ? const Center(
                  child: Text('No devices found. Tap refresh to scan.'),
                )
              : ListView.builder(
                  itemCount: _bleService.scanResults.length,
                  itemBuilder: (context, index) {
                    final result = _bleService.scanResults[index];
                    final name = result.device.platformName.isNotEmpty
                        ? result.device.platformName
                        : 'Unknown Device';
                    return ListTile(
                      title: Text(name),
                      subtitle: Text(result.device.remoteId.toString()),
                      trailing: ElevatedButton(
                        onPressed: () => _connect(result.device),
                        child: const Text('Connect'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildControlSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Message Controls',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Text Input
        TextField(
          controller: _textController,
          decoration: const InputDecoration(
            labelText: 'Message Text',
            border: OutlineInputBorder(),
            hintText: 'Enter text to display (Max 64 chars)',
            alignLabelWithHint: true,
          ),
          maxLength: 64,
          maxLines: 5,
          minLines: 3,
        ),
        const SizedBox(height: 16),

        // Vibration Controls
        DropdownButtonFormField<VibrationType>(
          initialValue: _vibrationType,
          decoration: const InputDecoration(
            labelText: 'Vibration Pattern',
            border: OutlineInputBorder(),
          ),
          items: VibrationType.values.map((type) {
            return DropdownMenuItem(value: type, child: Text(type.label));
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _vibrationType = value);
          },
        ),
        const SizedBox(height: 16),

        // Screen Effect Controls
        DropdownButtonFormField<ScreenEffect>(
          initialValue: _screenEffect,
          decoration: const InputDecoration(
            labelText: 'Screen Effect',
            border: OutlineInputBorder(),
          ),
          items: ScreenEffect.values.map((type) {
            return DropdownMenuItem(value: type, child: Text(type.label));
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _screenEffect = value);
          },
        ),

        const SizedBox(height: 16),
        const Text('LED Color (RGB)'),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const Text('R', style: TextStyle(color: Colors.red)),
                  Slider(
                    value: _red,
                    min: 0,
                    max: 255,
                    activeColor: Colors.red,
                    onChanged: (v) => setState(() => _red = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const Text('G', style: TextStyle(color: Colors.green)),
                  Slider(
                    value: _green,
                    min: 0,
                    max: 255,
                    activeColor: Colors.green,
                    onChanged: (v) => setState(() => _green = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const Text('B', style: TextStyle(color: Colors.blue)),
                  Slider(
                    value: _blue,
                    min: 0,
                    max: 255,
                    activeColor: Colors.blue,
                    onChanged: (v) => setState(() => _blue = v),
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          height: 40,
          width: double.infinity,
          color: Color.fromARGB(
            255,
            _red.toInt(),
            _green.toInt(),
            _blue.toInt(),
          ),
          child: const Center(
            child: Text(
              'Color Preview',
              style: TextStyle(
                color: Colors.white,
                shadows: [Shadow(blurRadius: 2, color: Colors.black)],
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _bleService.isConnected ? _sendPacket : null,
            icon: const Icon(Icons.send),
            label: const Text('SEND COMMAND'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
