import 'package:test/test.dart';
import 'package:openapi/openapi.dart';

/// tests for DevicesApi
void main() {
  final instance = Openapi().getDevicesApi();

  group(DevicesApi, () {
    // Create Device
    //
    // 创建设备
    //
    //Future<DeviceResponse> createDeviceApiDevicesPost(DeviceCreate deviceCreate) async
    test('test createDeviceApiDevicesPost', () async {
      // TODO
    });

    // Delete Device
    //
    // 删除设备
    //
    //Future<JsonObject> deleteDeviceApiDevicesDeviceIdDelete(int deviceId) async
    test('test deleteDeviceApiDevicesDeviceIdDelete', () async {
      // TODO
    });

    // Device Heartbeat
    //
    // 设备心跳（更新最后在线时间）
    //
    //Future<JsonObject> deviceHeartbeatApiDevicesDeviceIdHeartbeatPost(int deviceId) async
    test('test deviceHeartbeatApiDevicesDeviceIdHeartbeatPost', () async {
      // TODO
    });

    // Get Device
    //
    // 获取指定设备
    //
    //Future<DeviceResponse> getDeviceApiDevicesDeviceIdGet(int deviceId) async
    test('test getDeviceApiDevicesDeviceIdGet', () async {
      // TODO
    });

    // Get Device Stats
    //
    // 获取设备统计信息
    //
    //Future<DeviceStats> getDeviceStatsApiDevicesStatsGet() async
    test('test getDeviceStatsApiDevicesStatsGet', () async {
      // TODO
    });

    // Get Devices
    //
    // 获取设备列表
    //
    //Future<DeviceList> getDevicesApiDevicesGet({ int skip, int limit, String statusFilter, String deviceType }) async
    test('test getDevicesApiDevicesGet', () async {
      // TODO
    });

    // Update Device
    //
    // 更新设备信息
    //
    //Future<DeviceResponse> updateDeviceApiDevicesDeviceIdPut(int deviceId, DeviceUpdate deviceUpdate) async
    test('test updateDeviceApiDevicesDeviceIdPut', () async {
      // TODO
    });

    // Update Device Status
    //
    // 更新设备状态
    //
    //Future<JsonObject> updateDeviceStatusApiDevicesDeviceIdStatusPost(int deviceId, String status) async
    test('test updateDeviceStatusApiDevicesDeviceIdStatusPost', () async {
      // TODO
    });
  });
}
