import 'package:shared_preferences/shared_preferences.dart';
import '../constants/ble_constants.dart';

/// BLE存储管理器
class BleStorageManager {
  static BleStorageManager? _instance;
  SharedPreferences? _prefs;

  BleStorageManager._();

  static BleStorageManager get instance {
    _instance ??= BleStorageManager._();
    return _instance!;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 获取最后连接的设备ID
  String? getLastConnectedDeviceId() {
    return _prefs?.getString(BleConstants.lastConnectedDeviceKey);
  }

  /// 保存最后连接的设备ID
  Future<bool> saveLastConnectedDeviceId(String deviceId) async {
    return await _prefs?.setString(
          BleConstants.lastConnectedDeviceKey,
          deviceId,
        ) ??
        false;
  }

  /// 清除最后连接的设备ID
  Future<bool> clearLastConnectedDeviceId() async {
    return await _prefs?.remove(BleConstants.lastConnectedDeviceKey) ?? false;
  }

  /// 获取自动重连设置
  bool getAutoReconnectEnabled() {
    return _prefs?.getBool(BleConstants.autoReconnectEnabledKey) ?? true;
  }

  /// 设置自动重连
  Future<bool> setAutoReconnectEnabled(bool enabled) async {
    return await _prefs?.setBool(
          BleConstants.autoReconnectEnabledKey,
          enabled,
        ) ??
        false;
  }

  /// 清除所有BLE相关数据
  Future<void> clearAll() async {
    await _prefs?.remove(BleConstants.lastConnectedDeviceKey);
    await _prefs?.remove(BleConstants.autoReconnectEnabledKey);
  }
}
