import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// BLE连接相关常量配置
class BleConstants {
  // 服务UUID
  static const String serviceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String writeCharUuid = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String notifyCharUuid = "6E400004-B5A3-F393-E0A9-E50E24DCCA9E";

  // 标准电池服务
  static const String batteryServiceUuid = "180F";
  static const String batteryLevelCharUuid = "2A19";

  // 标准当前时间服务 (CTS - Current Time Service)
  static const String currentTimeServiceUuid = "1805";
  static const String currentTimeCharUuid = "2A2B";
  static const String localTimeInfoCharUuid = "2A0F"; // 可选，用于时区信息

  // CTS时间格式常量
  static const int ctsYearOffset = 1900; // CTS年份�?900年开始计�?
  static const int ctsAdjustReasonManualUpdate = 0x01;
  static const int ctsAdjustReasonExternalUpdate = 0x02;
  static const int ctsAdjustReasonTimezoneChange = 0x04;
  static const int ctsAdjustReasonDSTChange = 0x08; // 夏令时变�?

  // CTS星期定义 (BLE标准: 0=未知, 1=周一, 7=周日)
  static const int ctsWeekdayUnknown = 0;
  static const int ctsWeekdayMonday = 1;
  static const int ctsWeekdayTuesday = 2;
  static const int ctsWeekdayWednesday = 3;
  static const int ctsWeekdayThursday = 4;
  static const int ctsWeekdayFriday = 5;
  static const int ctsWeekdaySaturday = 6;
  static const int ctsWeekdaySunday = 7;

  // 设备过滤配置
  static const List<String> deviceNameFilters = ["BIPUPU", "BIPI"];

  // 连接配置
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration autoReconnectDelay = Duration(seconds: 5);
  static const int maxReconnectAttempts = 3;
  static const Duration serviceDiscoveryDelay = Duration(milliseconds: 500);

  // 扫描配置
  static const Duration scanTimeout = Duration(seconds: 10);

  // 协议配置
  static const int protocolVersion = 0x01;
  static const int maxColors = 20;
  static const int maxTextLength = 64;

  // 命令类型
  static const int cmdMessage = 0x01;
  static const int cmdErrorResponse = 0xFF;

  // SharedPreferences键名
  static const String lastConnectedDeviceKey = 'last_connected_device';
  static const String autoReconnectEnabledKey = 'auto_reconnect_enabled';

  // UUID转换
  static Guid get serviceGuid => Guid(serviceUuid);
  static Guid get writeCharGuidObj => Guid(writeCharUuid);
  static Guid get notifyCharGuidObj => Guid(notifyCharUuid);
  static Guid get currentTimeServiceGuid => Guid(currentTimeServiceUuid);
  static Guid get currentTimeCharGuidObj => Guid(currentTimeCharUuid);
  static Guid get localTimeInfoCharGuidObj => Guid(localTimeInfoCharUuid);
}
