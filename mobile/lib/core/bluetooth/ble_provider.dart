import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'ble_manager.dart';

/// BLE 扫描状态
class BleScanState {
  final bool isScanning;
  final List<BleScanResult> results;
  final String? error;

  const BleScanState({
    this.isScanning = false,
    this.results = const [],
    this.error,
  });

  BleScanState copyWith({
    bool? isScanning,
    List<BleScanResult>? results,
    String? error,
  }) {
    return BleScanState(
      isScanning: isScanning ?? this.isScanning,
      results: results ?? this.results,
      error: error ?? this.error,
    );
  }
}

/// BLE 扫描 Notifier
final bleScannerProvider = NotifierProvider<BleScanner, BleScanState>(
  BleScanner.new,
);

class BleScanner extends Notifier<BleScanState> {
  late final BleManager _bleManager;

  @override
  BleScanState build() {
    _bleManager = ref.watch(bleManagerProvider);
    _listenToScanResults();
    return const BleScanState();
  }

  void _listenToScanResults() {
    _bleManager.scanResultsStream.listen((result) {
      state = state.copyWith(results: [...state.results, result]);
    });
  }

  /// 开始扫描
  Future<void> startScan({List<Guid>? withServices}) async {
    state = state.copyWith(isScanning: true, error: null, results: []);
    try {
      await _bleManager.startScan(withServices: withServices);
    } catch (e) {
      state = state.copyWith(isScanning: false, error: '扫描失败：$e');
    }
  }

  /// 停止扫描
  Future<void> stopScan() async {
    await _bleManager.stopScan();
    state = state.copyWith(isScanning: false);
  }

  /// 清空结果
  void clearResults() {
    state = state.copyWith(results: []);
  }
}

/// BLE 连接状态 Notifier
final bleConnectionProvider =
    NotifierProvider<BleConnection, BleConnectionState>(BleConnection.new);

class BleConnection extends Notifier<BleConnectionState> {
  late final BleManager _bleManager;
  String? _connectedDeviceId;

  @override
  BleConnectionState build() {
    _bleManager = ref.watch(bleManagerProvider);
    _listenToConnectionState();
    return BleConnectionState.disconnected;
  }

  void _listenToConnectionState() {
    _bleManager.connectionStateStream.listen((newState) {
      state = newState;
    });
  }

  /// 连接设备
  Future<void> connect(String deviceId) async {
    _connectedDeviceId = deviceId;
    await _bleManager.connect(deviceId);
  }

  /// 断开设备
  Future<void> disconnect() async {
    if (_connectedDeviceId != null) {
      await _bleManager.disconnect(_connectedDeviceId!);
      _connectedDeviceId = null;
    }
  }

  /// 获取当前连接的设备 ID
  String? get connectedDeviceId => _connectedDeviceId;
}

/// BLE 设备服务提供者
final bleDeviceServicesProvider =
    FutureProvider.family<List<BluetoothService>, String>((
      ref,
      deviceId,
    ) async {
      final bleManager = ref.watch(bleManagerProvider);
      return bleManager.getServices(deviceId);
    });
