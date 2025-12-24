# openapi.api.NotificationsApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createNotificationApiNotificationsPost**](NotificationsApi.md#createnotificationapinotificationspost) | **POST** /api/notifications/ | Create Notification
[**deleteNotificationApiNotificationsNotificationIdDelete**](NotificationsApi.md#deletenotificationapinotificationsnotificationiddelete) | **DELETE** /api/notifications/{notification_id} | Delete Notification
[**getNotificationApiNotificationsNotificationIdGet**](NotificationsApi.md#getnotificationapinotificationsnotificationidget) | **GET** /api/notifications/{notification_id} | Get Notification
[**getNotificationStatsApiNotificationsStatsGet**](NotificationsApi.md#getnotificationstatsapinotificationsstatsget) | **GET** /api/notifications/stats | Get Notification Stats
[**getNotificationsApiNotificationsGet**](NotificationsApi.md#getnotificationsapinotificationsget) | **GET** /api/notifications/ | Get Notifications
[**markAllNotificationsAsReadApiNotificationsReadAllPut**](NotificationsApi.md#markallnotificationsasreadapinotificationsreadallput) | **PUT** /api/notifications/read-all | Mark All Notifications As Read
[**markNotificationAsReadApiNotificationsNotificationIdReadPut**](NotificationsApi.md#marknotificationasreadapinotificationsnotificationidreadput) | **PUT** /api/notifications/{notification_id}/read | Mark Notification As Read
[**updateNotificationApiNotificationsNotificationIdPut**](NotificationsApi.md#updatenotificationapinotificationsnotificationidput) | **PUT** /api/notifications/{notification_id} | Update Notification


# **createNotificationApiNotificationsPost**
> NotificationResponse createNotificationApiNotificationsPost(notificationCreate)

Create Notification

创建站内信

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getNotificationsApi();
final NotificationCreate notificationCreate = ; // NotificationCreate | 

try {
    final response = api.createNotificationApiNotificationsPost(notificationCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling NotificationsApi->createNotificationApiNotificationsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notificationCreate** | [**NotificationCreate**](NotificationCreate.md)|  | 

### Return type

[**NotificationResponse**](NotificationResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteNotificationApiNotificationsNotificationIdDelete**
> JsonObject deleteNotificationApiNotificationsNotificationIdDelete(notificationId)

Delete Notification

删除站内信（软删除）

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getNotificationsApi();
final int notificationId = 56; // int | 

try {
    final response = api.deleteNotificationApiNotificationsNotificationIdDelete(notificationId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling NotificationsApi->deleteNotificationApiNotificationsNotificationIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notificationId** | **int**|  | 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getNotificationApiNotificationsNotificationIdGet**
> NotificationResponse getNotificationApiNotificationsNotificationIdGet(notificationId)

Get Notification

获取指定站内信

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getNotificationsApi();
final int notificationId = 56; // int | 

try {
    final response = api.getNotificationApiNotificationsNotificationIdGet(notificationId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling NotificationsApi->getNotificationApiNotificationsNotificationIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notificationId** | **int**|  | 

### Return type

[**NotificationResponse**](NotificationResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getNotificationStatsApiNotificationsStatsGet**
> NotificationStats getNotificationStatsApiNotificationsStatsGet()

Get Notification Stats

获取站内信统计信息

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getNotificationsApi();

try {
    final response = api.getNotificationStatsApiNotificationsStatsGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling NotificationsApi->getNotificationStatsApiNotificationsStatsGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**NotificationStats**](NotificationStats.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getNotificationsApiNotificationsGet**
> NotificationList getNotificationsApiNotificationsGet(skip, limit, status)

Get Notifications

获取站内信列表

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getNotificationsApi();
final int skip = 56; // int | 
final int limit = 56; // int | 
final AppSchemasNotificationNotificationStatus status = ; // AppSchemasNotificationNotificationStatus | 

try {
    final response = api.getNotificationsApiNotificationsGet(skip, limit, status);
    print(response);
} catch on DioException (e) {
    print('Exception when calling NotificationsApi->getNotificationsApiNotificationsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **skip** | **int**|  | [optional] [default to 0]
 **limit** | **int**|  | [optional] [default to 100]
 **status** | [**AppSchemasNotificationNotificationStatus**](.md)|  | [optional] 

### Return type

[**NotificationList**](NotificationList.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markAllNotificationsAsReadApiNotificationsReadAllPut**
> JsonObject markAllNotificationsAsReadApiNotificationsReadAllPut()

Mark All Notifications As Read

标记所有站内信为已读

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getNotificationsApi();

try {
    final response = api.markAllNotificationsAsReadApiNotificationsReadAllPut();
    print(response);
} catch on DioException (e) {
    print('Exception when calling NotificationsApi->markAllNotificationsAsReadApiNotificationsReadAllPut: $e\n');
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

# **markNotificationAsReadApiNotificationsNotificationIdReadPut**
> JsonObject markNotificationAsReadApiNotificationsNotificationIdReadPut(notificationId)

Mark Notification As Read

标记站内信为已读

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getNotificationsApi();
final int notificationId = 56; // int | 

try {
    final response = api.markNotificationAsReadApiNotificationsNotificationIdReadPut(notificationId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling NotificationsApi->markNotificationAsReadApiNotificationsNotificationIdReadPut: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notificationId** | **int**|  | 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateNotificationApiNotificationsNotificationIdPut**
> NotificationResponse updateNotificationApiNotificationsNotificationIdPut(notificationId, notificationUpdate)

Update Notification

更新站内信

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getNotificationsApi();
final int notificationId = 56; // int | 
final NotificationUpdate notificationUpdate = ; // NotificationUpdate | 

try {
    final response = api.updateNotificationApiNotificationsNotificationIdPut(notificationId, notificationUpdate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling NotificationsApi->updateNotificationApiNotificationsNotificationIdPut: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notificationId** | **int**|  | 
 **notificationUpdate** | [**NotificationUpdate**](NotificationUpdate.md)|  | 

### Return type

[**NotificationResponse**](NotificationResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

