import 'package:test/test.dart';
import 'package:openapi/openapi.dart';

// tests for DeviceCreate
void main() {
  final instance = DeviceCreateBuilder();
  // TODO add properties to the builder and call build()

  group(DeviceCreate, () {
    // 设备唯一标识（BLE MAC/UUID/序列号）
    // String deviceIdentifier
    test('to test the property `deviceIdentifier`', () async {
      // TODO
    });

    // 绑定用户ID，强制1:1
    // int userId
    test('to test the property `userId`', () async {
      // TODO
    });

    // DateTime lastSeen
    test('to test the property `lastSeen`', () async {
      // TODO
    });

  });
}
