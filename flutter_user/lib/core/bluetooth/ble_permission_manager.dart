import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// BLE权限管理器
class BlePermissionManager {
  /// 检查并请求所有必要的BLE权限
  static Future<BlePermissionStatus> checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      return await _checkAndroidPermissions();
    } else if (Platform.isIOS) {
      return await _checkIOSPermissions();
    }

    return BlePermissionStatus.denied;
  }

  /// 检查Android权限
  static Future<BlePermissionStatus> _checkAndroidPermissions() async {
    final locationStatus = await Permission.location.request();
    final bluetoothScan = await Permission.bluetoothScan.request();
    final bluetoothConnect = await Permission.bluetoothConnect.request();

    if (locationStatus.isGranted &&
        bluetoothScan.isGranted &&
        bluetoothConnect.isGranted) {
      return BlePermissionStatus.granted;
    } else if (locationStatus.isPermanentlyDenied ||
        bluetoothScan.isPermanentlyDenied ||
        bluetoothConnect.isPermanentlyDenied) {
      return BlePermissionStatus.permanentlyDenied;
    } else {
      return BlePermissionStatus.denied;
    }
  }

  /// 检查iOS权限
  static Future<BlePermissionStatus> _checkIOSPermissions() async {
    final bluetooth = await Permission.bluetooth.request();

    if (bluetooth.isGranted) {
      return BlePermissionStatus.granted;
    } else if (bluetooth.isPermanentlyDenied) {
      return BlePermissionStatus.permanentlyDenied;
    } else {
      return BlePermissionStatus.denied;
    }
  }

  /// 检查特定权限状态
  static Future<bool> isPermissionGranted() async {
    final status = await checkAndRequestPermissions();
    return status == BlePermissionStatus.granted;
  }

  /// 打开应用设置页面
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}

/// BLE权限状态枚举
enum BlePermissionStatus { granted, denied, permanentlyDenied }
