import 'dart:typed_data';

/// BLE标准CTS (Current Time Service) 协议实现
/// 基于Bluetooth SIG标准规范
/// 参考: https://www.bluetooth.com/specifications/specs/current-time-service-1-1/

/// CTS时间同步状态枚举
enum BleCtsSyncState {
  none, // 未同步
  pending, // 同步中
  success, // 同步成功
  failed, // 同步失败
}

/// CTS当前时间特征数据结构
/// 特征UUID: 0x2A2B
/// 数据长度: 10字节
/// 格式:
/// - 年份 (2字节, little-endian): 0-65535
/// - 月份 (1字节): 1-12
/// - 日期 (1字节): 1-31
/// - 小时 (1字节): 0-23
/// - 分钟 (1字节): 0-59
/// - 秒钟 (1字节): 0-59
/// - 星期 (1字节): 0=未知, 1=周一, 7=周日
/// - 分数 (1字节): 1/256秒, 0-255
/// - 调整原因 (1字节): 位标志
class BleCtsCurrentTime {
  static const int dataLength = 10;

  final int year; // 年份 (完整年份，如2024)
  final int month; // 月份 (1-12)
  final int day; // 日期 (1-31)
  final int hour; // 小时 (0-23)
  final int minute; // 分钟 (0-59)
  final int second; // 秒钟 (0-59)
  final int weekday; // 星期 (0-7, 0=未知, 1=周一, 7=周日)
  final int fraction256; // 分数 (0-255, 1/256秒)
  final int adjustReason; // 调整原因 (位标志)

  const BleCtsCurrentTime({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    required this.second,
    required this.weekday,
    this.fraction256 = 0,
    this.adjustReason = 0,
  });

  /// 从字节数组解析CTS时间数据
  factory BleCtsCurrentTime.fromBytes(Uint8List bytes) {
    if (bytes.length != dataLength) {
      throw ArgumentError(
        'Invalid CTS data length: expected $dataLength, got ${bytes.length}',
      );
    }

    return BleCtsCurrentTime(
      year: bytes[0] | (bytes[1] << 8), // little-endian
      month: bytes[2],
      day: bytes[3],
      hour: bytes[4],
      minute: bytes[5],
      second: bytes[6],
      weekday: bytes[7],
      fraction256: bytes[8],
      adjustReason: bytes[9],
    );
  }

  /// 转换为字节数组
  Uint8List toBytes() {
    final bytes = Uint8List(dataLength);
    bytes[0] = year & 0xFF; // little-endian
    bytes[1] = (year >> 8) & 0xFF;
    bytes[2] = month;
    bytes[3] = day;
    bytes[4] = hour;
    bytes[5] = minute;
    bytes[6] = second;
    bytes[7] = weekday;
    bytes[8] = fraction256;
    bytes[9] = adjustReason;
    return bytes;
  }

  /// 从DateTime创建CTS时间
  factory BleCtsCurrentTime.fromDateTime(
    DateTime dateTime, {
    int adjustReason = 0,
  }) {
    // 转换星期格式 (Dart: 1=周一, 7=周日 -> CTS: 1=周一, 7=周日)
    // Dart的weekday与CTS标准一致，无需转换
    return BleCtsCurrentTime(
      year: dateTime.year,
      month: dateTime.month,
      day: dateTime.day,
      hour: dateTime.hour,
      minute: dateTime.minute,
      second: dateTime.second,
      weekday: dateTime.weekday,
      fraction256: 0, // 默认无分数秒
      adjustReason: adjustReason,
    );
  }

  /// 转换为DateTime
  DateTime toDateTime() {
    return DateTime(year, month, day, hour, minute, second);
  }

  /// 验证时间数据的有效性
  bool isValidTimeData() {
    return year >= 1582 && // Gregorian calendar start year
        year <= 9999 &&
        month >= 1 &&
        month <= 12 &&
        day >= 1 &&
        day <= 31 &&
        hour >= 0 &&
        hour <= 23 &&
        minute >= 0 &&
        minute <= 59 &&
        second >= 0 &&
        second <= 59 &&
        weekday >= 0 &&
        weekday <= 7;
  }

  @override
  String toString() {
    return 'BleCtsCurrentTime($year-$month-$day $hour:$minute:$second, '
        'weekday: $weekday, fraction: $fraction256, adjustReason: 0x${adjustReason.toRadixString(16).padLeft(2, '0')})';
  }
}

/// CTS本地时间信息特征数据结构
/// 特征UUID: 0x2A0F (可选)
/// 数据长度: 2字节
/// 格式:
/// - 时区偏移 (1字节, 有符号): -48 到 +56 (0.25小时为单位)
/// - DST偏移 (1字节): 0=标准时间, 2=+0.5小时, 4=+1小时, 8=+2小时
class BleCtsLocalTimeInfo {
  static const int dataLength = 2;

  final int timezoneOffset; // 时区偏移 (-48 到 +56, 0.25小时为单位)
  final int dstOffset; // DST偏移 (0, 2, 4, 8)

  const BleCtsLocalTimeInfo({
    required this.timezoneOffset,
    required this.dstOffset,
  });

  /// 从字节数组解析本地时间信息
  factory BleCtsLocalTimeInfo.fromBytes(Uint8List bytes) {
    if (bytes.length != dataLength) {
      throw ArgumentError(
        'Invalid local time info length: expected $dataLength, got ${bytes.length}',
      );
    }

    // 时区偏移是有符号数，需要处理
    final timezoneByte = bytes[0];
    final timezoneOffset = timezoneByte > 127
        ? timezoneByte - 256
        : timezoneByte;

    return BleCtsLocalTimeInfo(
      timezoneOffset: timezoneOffset,
      dstOffset: bytes[1],
    );
  }

  /// 转换为字节数组
  Uint8List toBytes() {
    final bytes = Uint8List(dataLength);

    // 时区偏移转换为有符号字节
    if (timezoneOffset < 0) {
      bytes[0] = timezoneOffset + 256;
    } else {
      bytes[0] = timezoneOffset;
    }

    bytes[1] = dstOffset;
    return bytes;
  }

  /// 从当前系统时区创建本地时间信息
  factory BleCtsLocalTimeInfo.fromSystemTimezone() {
    // 获取当前时区偏移（小时）
    final now = DateTime.now();
    final utc = now.toUtc();
    final local = now.toLocal();

    // 计算时区差异（小时）
    final timezoneDiff = local.difference(utc).inHours;

    // 转换为0.25小时单位
    final timezoneOffset = (timezoneDiff * 4).round();

    // 简化的DST检测（实际应用中可能需要更复杂的逻辑）
    int dstOffset = 0;
    if (local.isAfter(DateTime(local.year, 3, 1)) &&
        local.isBefore(DateTime(local.year, 11, 1))) {
      // 假设3月到11月为DST期间
      dstOffset = 4; // +1小时
    }

    return BleCtsLocalTimeInfo(
      timezoneOffset: timezoneOffset,
      dstOffset: dstOffset,
    );
  }

  /// 获取时区偏移的小时数
  double getTimezoneOffsetHours() {
    return timezoneOffset / 4.0;
  }

  /// 获取DST偏移的小时数
  double getDstOffsetHours() {
    return dstOffset / 4.0;
  }

  @override
  String toString() {
    return 'BleCtsLocalTimeInfo(timezone: ${getTimezoneOffsetHours()}h, dst: ${getDstOffsetHours()}h)';
  }
}

/// BLE CTS协议主类
class BleCtsProtocol {
  /// 创建当前时间特征数据
  static BleCtsCurrentTime createCurrentTime(
    DateTime dateTime, {
    int adjustReason = 0,
  }) {
    return BleCtsCurrentTime.fromDateTime(dateTime, adjustReason: adjustReason);
  }

  /// 创建本地时间信息特征数据
  static BleCtsLocalTimeInfo createLocalTimeInfo() {
    return BleCtsLocalTimeInfo.fromSystemTimezone();
  }

  /// 创建手动时间更新请求
  static BleCtsCurrentTime createManualTimeUpdate(DateTime dateTime) {
    return BleCtsCurrentTime.fromDateTime(
      dateTime,
      adjustReason: 0x01, // 手动更新
    );
  }

  /// 创建外部时间更新请求
  static BleCtsCurrentTime createExternalTimeUpdate(DateTime dateTime) {
    return BleCtsCurrentTime.fromDateTime(
      dateTime,
      adjustReason: 0x02, // 外部更新
    );
  }

  /// 创建时区变化更新
  static BleCtsCurrentTime createTimezoneChangeUpdate(DateTime dateTime) {
    return BleCtsCurrentTime.fromDateTime(
      dateTime,
      adjustReason: 0x04, // 时区变化
    );
  }

  /// 创建DST变化更新
  static BleCtsCurrentTime createDstChangeUpdate(DateTime dateTime) {
    return BleCtsCurrentTime.fromDateTime(
      dateTime,
      adjustReason: 0x08, // DST变化
    );
  }

  /// 验证CTS时间数据
  static bool validateCurrentTime(BleCtsCurrentTime currentTime) {
    return currentTime.isValidTimeData();
  }

  /// 验证本地时间信息
  static bool validateLocalTimeInfo(BleCtsLocalTimeInfo localTimeInfo) {
    return localTimeInfo.timezoneOffset >= -48 &&
        localTimeInfo.timezoneOffset <= 56 &&
        (localTimeInfo.dstOffset == 0 ||
            localTimeInfo.dstOffset == 2 ||
            localTimeInfo.dstOffset == 4 ||
            localTimeInfo.dstOffset == 8);
  }
}
