# openapi.api.DevicesApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createDeviceApiDevicesPost**](DevicesApi.md#createdeviceapidevicespost) | **POST** /api/devices/ | Create Device
[**deleteDeviceApiDevicesDeviceIdDelete**](DevicesApi.md#deletedeviceapidevicesdeviceiddelete) | **DELETE** /api/devices/{device_id} | Delete Device
[**deviceHeartbeatApiDevicesDeviceIdHeartbeatPost**](DevicesApi.md#deviceheartbeatapidevicesdeviceidheartbeatpost) | **POST** /api/devices/{device_id}/heartbeat | Device Heartbeat
[**getDeviceApiDevicesDeviceIdGet**](DevicesApi.md#getdeviceapidevicesdeviceidget) | **GET** /api/devices/{device_id} | Get Device
[**getDeviceStatsApiDevicesStatsGet**](DevicesApi.md#getdevicestatsapidevicesstatsget) | **GET** /api/devices/stats | Get Device Stats
[**getDevicesApiDevicesGet**](DevicesApi.md#getdevicesapidevicesget) | **GET** /api/devices/ | Get Devices
[**updateDeviceApiDevicesDeviceIdPut**](DevicesApi.md#updatedeviceapidevicesdeviceidput) | **PUT** /api/devices/{device_id} | Update Device
[**updateDeviceStatusApiDevicesDeviceIdStatusPost**](DevicesApi.md#updatedevicestatusapidevicesdeviceidstatuspost) | **POST** /api/devices/{device_id}/status | Update Device Status


# **createDeviceApiDevicesPost**
> DeviceResponse createDeviceApiDevicesPost(deviceCreate)

Create Device

创建设备

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDevicesApi();
final DeviceCreate deviceCreate = ; // DeviceCreate | 

try {
    final response = api.createDeviceApiDevicesPost(deviceCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DevicesApi->createDeviceApiDevicesPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **deviceCreate** | [**DeviceCreate**](DeviceCreate.md)|  | 

### Return type

[**DeviceResponse**](DeviceResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteDeviceApiDevicesDeviceIdDelete**
> JsonObject deleteDeviceApiDevicesDeviceIdDelete(deviceId)

Delete Device

删除设备

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDevicesApi();
final int deviceId = 56; // int | 

try {
    final response = api.deleteDeviceApiDevicesDeviceIdDelete(deviceId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DevicesApi->deleteDeviceApiDevicesDeviceIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **deviceId** | **int**|  | 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deviceHeartbeatApiDevicesDeviceIdHeartbeatPost**
> JsonObject deviceHeartbeatApiDevicesDeviceIdHeartbeatPost(deviceId)

Device Heartbeat

设备心跳（更新最后在线时间）

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDevicesApi();
final int deviceId = 56; // int | 

try {
    final response = api.deviceHeartbeatApiDevicesDeviceIdHeartbeatPost(deviceId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DevicesApi->deviceHeartbeatApiDevicesDeviceIdHeartbeatPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **deviceId** | **int**|  | 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDeviceApiDevicesDeviceIdGet**
> DeviceResponse getDeviceApiDevicesDeviceIdGet(deviceId)

Get Device

获取指定设备

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDevicesApi();
final int deviceId = 56; // int | 

try {
    final response = api.getDeviceApiDevicesDeviceIdGet(deviceId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DevicesApi->getDeviceApiDevicesDeviceIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **deviceId** | **int**|  | 

### Return type

[**DeviceResponse**](DeviceResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDeviceStatsApiDevicesStatsGet**
> DeviceStats getDeviceStatsApiDevicesStatsGet()

Get Device Stats

获取设备统计信息

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDevicesApi();

try {
    final response = api.getDeviceStatsApiDevicesStatsGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling DevicesApi->getDeviceStatsApiDevicesStatsGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DeviceStats**](DeviceStats.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDevicesApiDevicesGet**
> DeviceList getDevicesApiDevicesGet(skip, limit, statusFilter, deviceType)

Get Devices

获取设备列表

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDevicesApi();
final int skip = 56; // int | 
final int limit = 56; // int | 
final String statusFilter = statusFilter_example; // String | 
final String deviceType = deviceType_example; // String | 

try {
    final response = api.getDevicesApiDevicesGet(skip, limit, statusFilter, deviceType);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DevicesApi->getDevicesApiDevicesGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **skip** | **int**|  | [optional] [default to 0]
 **limit** | **int**|  | [optional] [default to 100]
 **statusFilter** | **String**|  | [optional] 
 **deviceType** | **String**|  | [optional] 

### Return type

[**DeviceList**](DeviceList.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateDeviceApiDevicesDeviceIdPut**
> DeviceResponse updateDeviceApiDevicesDeviceIdPut(deviceId, deviceUpdate)

Update Device

更新设备信息

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDevicesApi();
final int deviceId = 56; // int | 
final DeviceUpdate deviceUpdate = ; // DeviceUpdate | 

try {
    final response = api.updateDeviceApiDevicesDeviceIdPut(deviceId, deviceUpdate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DevicesApi->updateDeviceApiDevicesDeviceIdPut: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **deviceId** | **int**|  | 
 **deviceUpdate** | [**DeviceUpdate**](DeviceUpdate.md)|  | 

### Return type

[**DeviceResponse**](DeviceResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateDeviceStatusApiDevicesDeviceIdStatusPost**
> JsonObject updateDeviceStatusApiDevicesDeviceIdStatusPost(deviceId, status)

Update Device Status

更新设备状态

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDevicesApi();
final int deviceId = 56; // int | 
final String status = status_example; // String | 

try {
    final response = api.updateDeviceStatusApiDevicesDeviceIdStatusPost(deviceId, status);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DevicesApi->updateDeviceStatusApiDevicesDeviceIdStatusPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **deviceId** | **int**|  | 
 **status** | **String**|  | 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

