import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../utils/logger.dart';

/// 蓝牙服务类 - 单例模式
class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();

  factory BluetoothService() => _instance;
  BluetoothService._internal();

  static BluetoothService get instance => _instance;

  bool _initialized = false;

  /// 初始化蓝牙服务
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 检查蓝牙是否可用
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        throw Exception('蓝牙不可用');
      }

      // 检查蓝牙是否开启
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        // 尝试开启蓝牙
        await FlutterBluePlus.turnOn();
      }

      _initialized = true;
      Logger.info('蓝牙服务初始化完成');
    } catch (e) {
      Logger.error('蓝牙服务初始化失败: $e');
      rethrow;
    }
  }

  /// 开始扫描设备
  Future<void> startScan() async {
    if (!_initialized) {
      throw Exception('蓝牙服务未初始化');
    }

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (e) {
      Logger.error('扫描设备失败: $e');
      rethrow;
    }
  }

  /// 停止扫描
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      Logger.error('停止扫描失败: $e');
      rethrow;
    }
  }

  /// 连接设备
  /// 连接设备
  Future<void> connectToDevice(String deviceId) async {
    try {
      // 1. 【逻辑修正】不要从 connectedDevices 里找，因为未连接的设备不在那里。
      // 直接通过 ID 构建 BluetoothDevice 对象。
      // 注意：确保 deviceId 格式正确（MAC地址或UUID）
      final device = BluetoothDevice.fromId(deviceId);

      // 2. 检查当前连接状态（可选，防止重复连接）
      // 注意：device.isConnected 是同步属性，可能需要先监听状态，但在发起连接前简单判断是可以的
      if (device.isConnected) {
        Logger.info('设备已在连接状态: $deviceId');
        return;
      }

      Logger.info('开始连接设备: $deviceId');

      // 3. 【参数修正】根据你的 API 定义，必须传入 license
      // 请检查 License 枚举的具体值，通常是 License.agree 或类似的
      // 如果你的编辑器报错，请查看 License 枚举定义选择正确的值
      await device.connect(
        license: License.free, // <--- 关键修改：根据你的库版本选择正确的枚举值
        timeout: const Duration(seconds: 15), // 建议设置超时
        autoConnect: false, // 通常设为 false 连接速度更快
      );

      Logger.info('设备连接成功: $deviceId');
    } catch (e) {
      Logger.error('设备连接失败: $e');
      rethrow;
    }
  }

  /// 断开设备连接
  Future<void> disconnectDevice(String deviceId) async {
    try {
      final device = FlutterBluePlus.connectedDevices.firstWhere(
        (device) => device.remoteId.str == deviceId,
        orElse: () => throw Exception('设备未找到'),
      );

      await device.disconnect();
      Logger.info('设备断开连接: $deviceId');
    } catch (e) {
      Logger.error('设备断开连接失败: $e');
      rethrow;
    }
  }

  /// 获取已连接的设备
  List<BluetoothDevice> getConnectedDevices() {
    return FlutterBluePlus.connectedDevices;
  }

  /// 获取扫描结果
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  /// 检查是否已初始化
  bool get isInitialized => _initialized;
}
