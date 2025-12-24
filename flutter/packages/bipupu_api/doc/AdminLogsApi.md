# openapi.api.AdminLogsApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**deleteAdminLogApiAdminLogsLogIdDelete**](AdminLogsApi.md#deleteadminlogapiadminlogslogiddelete) | **DELETE** /api/admin-logs/{log_id} | Delete Admin Log
[**getAdminLogApiAdminLogsLogIdGet**](AdminLogsApi.md#getadminlogapiadminlogslogidget) | **GET** /api/admin-logs/{log_id} | Get Admin Log
[**getAdminLogStatsApiAdminLogsStatsGet**](AdminLogsApi.md#getadminlogstatsapiadminlogsstatsget) | **GET** /api/admin-logs/stats | Get Admin Log Stats
[**getAdminLogsApiAdminLogsGet**](AdminLogsApi.md#getadminlogsapiadminlogsget) | **GET** /api/admin-logs/ | Get Admin Logs


# **deleteAdminLogApiAdminLogsLogIdDelete**
> JsonObject deleteAdminLogApiAdminLogsLogIdDelete(logId)

Delete Admin Log

删除管理员日志（需要超级用户权限）

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getAdminLogsApi();
final int logId = 56; // int | 

try {
    final response = api.deleteAdminLogApiAdminLogsLogIdDelete(logId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminLogsApi->deleteAdminLogApiAdminLogsLogIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **logId** | **int**|  | 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAdminLogApiAdminLogsLogIdGet**
> AdminLogResponse getAdminLogApiAdminLogsLogIdGet(logId)

Get Admin Log

获取指定管理员日志（需要超级用户权限）

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getAdminLogsApi();
final int logId = 56; // int | 

try {
    final response = api.getAdminLogApiAdminLogsLogIdGet(logId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminLogsApi->getAdminLogApiAdminLogsLogIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **logId** | **int**|  | 

### Return type

[**AdminLogResponse**](AdminLogResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAdminLogStatsApiAdminLogsStatsGet**
> JsonObject getAdminLogStatsApiAdminLogsStatsGet()

Get Admin Log Stats

获取管理员操作日志统计（需要超级用户权限）

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getAdminLogsApi();

try {
    final response = api.getAdminLogStatsApiAdminLogsStatsGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminLogsApi->getAdminLogStatsApiAdminLogsStatsGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAdminLogsApiAdminLogsGet**
> BuiltList<AdminLogResponse> getAdminLogsApiAdminLogsGet(skip, limit, adminId, action, startDate, endDate)

Get Admin Logs

获取管理员操作日志（需要超级用户权限）

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getAdminLogsApi();
final int skip = 56; // int | 
final int limit = 56; // int | 
final int adminId = 56; // int | 
final String action = action_example; // String | 
final Date startDate = 2013-10-20; // Date | 
final Date endDate = 2013-10-20; // Date | 

try {
    final response = api.getAdminLogsApiAdminLogsGet(skip, limit, adminId, action, startDate, endDate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdminLogsApi->getAdminLogsApiAdminLogsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **skip** | **int**|  | [optional] [default to 0]
 **limit** | **int**|  | [optional] [default to 100]
 **adminId** | **int**|  | [optional] 
 **action** | **String**|  | [optional] 
 **startDate** | **Date**|  | [optional] 
 **endDate** | **Date**|  | [optional] 

### Return type

[**BuiltList&lt;AdminLogResponse&gt;**](AdminLogResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

