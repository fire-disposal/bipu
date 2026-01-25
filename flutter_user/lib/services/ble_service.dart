import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/protocol/ble_protocol.dart';

class BleService extends ChangeNotifier {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  static const String serviceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String writeCharUuid = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String notifyCharUuid = "6E400004-B5A3-F393-E0A9-E50E24DCCA9E";

  // Standard Battery Service
  static const String batteryServiceUuid = "180F";
  static const String batteryLevelCharUuid = "2A19";

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  BluetoothCharacteristic? _batteryCharacteristic;

  bool _isScanning = false;
  List<ScanResult> _scanResults = [];
  int? _batteryLevel;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isScanning => _isScanning;
  List<ScanResult> get scanResults => _scanResults;
  bool get isConnected => _connectedDevice != null;
  int? get batteryLevel => _batteryLevel;

  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _batterySubscription;

  Future<bool> checkPermissions() async {
    if (Platform.isAndroid) {
      final locationStatus = await Permission.location.request();
      final bluetoothScan = await Permission.bluetoothScan.request();
      final bluetoothConnect = await Permission.bluetoothConnect.request();

      return locationStatus.isGranted &&
          bluetoothScan.isGranted &&
          bluetoothConnect.isGranted;
    } else if (Platform.isIOS) {
      final bluetooth = await Permission.bluetooth.request();
      return bluetooth.isGranted;
    }
    return false;
  }

  Future<void> startScan() async {
    if (_isScanning) return;

    final hasPerms = await checkPermissions();
    if (!hasPerms) {
      debugPrint("BLE Permissions denied");
      return;
    }

    _scanResults.clear();
    notifyListeners();

    try {
      // Use withServices is better if UUID is standard, but some devices don't advertise it immediately.
      // Filtering by name in the listener is safer for generic modules if they have a specific name prefix.
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        // withServices: [Guid(serviceUuid)], // Uncomment if the device advertises this UUID
      );
      _isScanning = true;
      notifyListeners();

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        // Filter Logic:
        // 1. Must have a name
        // 2. Name contains "BIPUPU" or "BIPI" (Case insensitive) OR advertises the Service UUID

        final filtered = results.where((r) {
          final name = r.device.platformName.toUpperCase();
          final hasNameMatch = name.contains("BIPUPU") || name.contains("BIPI");
          final hasServiceMatch = r.advertisementData.serviceUuids.contains(
            Guid(serviceUuid),
          );

          return hasNameMatch || hasServiceMatch;
        }).toList();

        _scanResults = filtered;
        notifyListeners();
      });

      FlutterBluePlus.isScanning.listen((scanning) {
        _isScanning = scanning;
        notifyListeners();
      });
    } catch (e) {
      debugPrint("Start scan error: $e");
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      _isScanning = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Stop scan error: $e");
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    try {
      await stopScan();
      await device.connect(license: License.free);
      _connectedDevice = device;
      notifyListeners();

      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _cleanupConnection();
        }
      });

      await _discoverServices(device);
    } catch (e) {
      debugPrint("Connection error: $e");
      _cleanupConnection();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      await _connectedDevice?.disconnect();
    } catch (e) {
      debugPrint("Disconnect error: $e");
    } finally {
      _cleanupConnection();
    }
  }

  void _cleanupConnection() {
    _connectedDevice = null;
    _writeCharacteristic = null;
    _notifyCharacteristic = null;
    _batteryCharacteristic = null;
    _batteryLevel = null;
    _connectionSubscription?.cancel();
    _batterySubscription?.cancel();
    notifyListeners();
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        final sUuid = service.uuid.toString().toUpperCase();

        // Private Service
        if (sUuid == serviceUuid) {
          for (var characteristic in service.characteristics) {
            final cUuid = characteristic.uuid.toString().toUpperCase();
            if (cUuid == writeCharUuid) {
              _writeCharacteristic = characteristic;
            } else if (cUuid == notifyCharUuid) {
              _notifyCharacteristic = characteristic;
              await _notifyCharacteristic!.setNotifyValue(true);
              _notifyCharacteristic!.lastValueStream.listen((value) {
                debugPrint("Received notification: $value");
                // Handle received data here if needed
              });
            }
          }
        }

        // Battery Service
        if (sUuid.contains(batteryServiceUuid)) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toUpperCase().contains(
              batteryLevelCharUuid,
            )) {
              _batteryCharacteristic = characteristic;

              // Read initial value
              try {
                final value = await characteristic.read();
                if (value.isNotEmpty) {
                  _batteryLevel = value[0];
                  notifyListeners();
                }
              } catch (e) {
                debugPrint("Error reading battery level: $e");
              }

              // Subscribe to updates
              if (characteristic.properties.notify) {
                await characteristic.setNotifyValue(true);
                _batterySubscription = characteristic.lastValueStream.listen((
                  value,
                ) {
                  if (value.isNotEmpty) {
                    _batteryLevel = value[0];
                    notifyListeners();
                  }
                });
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Discover services error: $e");
    }
  }

  Future<void> sendData(List<int> data) async {
    if (_writeCharacteristic == null) {
      throw Exception("Device not connected or characteristic not found");
    }
    try {
      await _writeCharacteristic!.write(data, withoutResponse: true);
    } catch (e) {
      debugPrint("Send data error: $e");
      rethrow;
    }
  }

  // --- High Level Protocol Methods ---

  Future<void> sendProtocolMessage({
    List<ColorData> colors = const [],
    VibrationType vibration = VibrationType.none,
    ScreenEffect screenEffect = ScreenEffect.none,
    String text = '',
  }) async {
    final packet = BleProtocol.createPacket(
      colors: colors,
      vibration: vibration,
      screenEffect: screenEffect,
      text: text,
    );
    await sendData(packet);
  }
}
