import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// Standard BLE Service and Characteristic UUIDs
const String batteryServiceUuid = "0000180f-0000-1000-8000-00805f9b34fb";
const String batteryLevelCharacteristicUuid =
    "00002a19-0000-1000-8000-00805f9b34fb";
const String currentTimeServiceUuid = "00001805-0000-1000-8000-00805f9b34fb";
const String currentTimeCharacteristicUuid =
    "00002a2b-0000-1000-8000-00805f9b34fb";

// Custom service for message forwarding (e.g., Nordic UART Service)
const String nordicUartServiceUuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
const String nordicUartTxCharacteristicUuid =
    "6e400002-b5a3-f393-e0a9-e50e24dcca9e"; // App writes to this (TX for the peripheral)
const String nordicUartRxCharacteristicUuid =
    "6e400003-b5a3-f393-e0a9-e50e24dcca9e"; // App receives from this (RX for the peripheral)

class BluetoothDeviceService {
  static final BluetoothDeviceService _instance =
      BluetoothDeviceService._internal();
  factory BluetoothDeviceService() => _instance;

  BluetoothDeviceService._internal();

  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  // Characteristics
  BluetoothCharacteristic? _batteryLevelCharacteristic;
  BluetoothCharacteristic? _currentTimeCharacteristic;
  BluetoothCharacteristic? _messageForwardingCharacteristic;

  // State Notifiers
  final ValueNotifier<BluetoothConnectionState> connectionState = ValueNotifier(
    BluetoothConnectionState.disconnected,
  );
  final ValueNotifier<int?> batteryLevel = ValueNotifier(null);

  Future<void> connect(BluetoothDevice device) async {
    if (_connectedDevice != null) {
      await disconnect();
    }

    _connectionStateSubscription = device.connectionState.listen((state) async {
      connectionState.value = state;
      if (state == BluetoothConnectionState.connected) {
        _connectedDevice = device;
        await _discoverServicesAndSetup();
      } else if (state == BluetoothConnectionState.disconnected) {
        _cleanup();
      }
    });

    try {
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 15),
      );
    } catch (e) {
      // Handle connection error
      _cleanup();
    }
  }

  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _cleanup();
  }

  Future<void> _discoverServicesAndSetup() async {
    if (_connectedDevice == null) return;

    List<BluetoothService> services = await _connectedDevice!
        .discoverServices();
    for (var service in services) {
      // Find Battery Service
      if (service.uuid.str.toLowerCase() == batteryServiceUuid) {
        for (var c in service.characteristics) {
          if (c.uuid.str.toLowerCase() == batteryLevelCharacteristicUuid) {
            _batteryLevelCharacteristic = c;
            await _setupBatteryLevelNotifications();
          }
        }
      }
      // Find Current Time Service
      else if (service.uuid.str.toLowerCase() == currentTimeServiceUuid) {
        for (var c in service.characteristics) {
          if (c.uuid.str.toLowerCase() == currentTimeCharacteristicUuid) {
            _currentTimeCharacteristic = c;
            await syncTime();
          }
        }
      }
      // Find Custom Message Service
      else if (service.uuid.str.toLowerCase() == nordicUartServiceUuid) {
        for (var c in service.characteristics) {
          if (c.uuid.str.toLowerCase() == nordicUartTxCharacteristicUuid) {
            _messageForwardingCharacteristic = c;
          }
        }
      }
    }
  }

  Future<void> _setupBatteryLevelNotifications() async {
    if (_batteryLevelCharacteristic != null &&
        _batteryLevelCharacteristic!.properties.notify) {
      await _batteryLevelCharacteristic!.setNotifyValue(true);
      _batteryLevelCharacteristic!.lastValueStream.listen((value) {
        if (value.isNotEmpty) {
          batteryLevel.value = value[0];
        }
      });
      // Also read initial value
      final initialValue = await _batteryLevelCharacteristic!.read();
      if (initialValue.isNotEmpty) {
        batteryLevel.value = initialValue[0];
      }
    }
  }

  Future<void> syncTime() async {
    if (_currentTimeCharacteristic != null &&
        _currentTimeCharacteristic!.properties.write) {
      final now = DateTime.now();
      // Exact Time 256 format
      // See: https://www.bluetooth.com/specifications/specs/gatt-specification-supplement-6/
      ByteData timeData = ByteData(10);
      timeData.setUint16(0, now.year, Endian.little);
      timeData.setUint8(2, now.month);
      timeData.setUint8(3, now.day);
      timeData.setUint8(4, now.hour);
      timeData.setUint8(5, now.minute);
      timeData.setUint8(6, now.second);
      timeData.setUint8(7, now.weekday % 7); // 1=Monday..7=Sunday
      timeData.setUint8(8, (now.millisecond * 256 / 1000).floor());
      timeData.setUint8(9, 0); // Adjust reason

      await _currentTimeCharacteristic!.write(
        timeData.buffer.asUint8List(),
        withoutResponse: false,
      );
    }
  }

  Future<void> forwardMessage(String message) async {
    if (_messageForwardingCharacteristic != null &&
        _messageForwardingCharacteristic!.properties.write) {
      // Split message into chunks of MTU size - 20 is a safe default
      final mtu = _connectedDevice?.mtuNow ?? 23;
      final chunkSize = mtu - 3;
      final bytes = utf8.encode(message);
      for (int i = 0; i < bytes.length; i += chunkSize) {
        final chunk = bytes.sublist(
          i,
          i + chunkSize > bytes.length ? bytes.length : i + chunkSize,
        );
        await _messageForwardingCharacteristic!.write(
          chunk,
          withoutResponse: true,
        );
      }
    }
  }

  void _cleanup() {
    _connectionStateSubscription?.cancel();
    _connectedDevice = null;
    _batteryLevelCharacteristic = null;
    _currentTimeCharacteristic = null;
    _messageForwardingCharacteristic = null;
    batteryLevel.value = null;
    if (connectionState.value != BluetoothConnectionState.disconnected) {
      connectionState.value = BluetoothConnectionState.disconnected;
    }
  }
}
