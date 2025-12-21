# openapi.api.NotificationsApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**cancelNotificationApiNotificationsNotificationIdCancelPost**](NotificationsApi.md#cancelnotificationapinotificationsnotificationidcancelpost) | **POST** /api/notifications/{notification_id}/cancel | Cancel Notification
[**createEmailNotificationApiNotificationsEmailPost**](NotificationsApi.md#createemailnotificationapinotificationsemailpost) | **POST** /api/notifications/email | Create Email Notification
[**createNotificationApiNotificationsPost**](NotificationsApi.md#createnotificationapinotificationspost) | **POST** /api/notifications/ | Create Notification
[**createPushNotificationApiNotificationsPushPost**](NotificationsApi.md#createpushnotificationapinotificationspushpost) | **POST** /api/notifications/push | Create Push Notification
[**deleteNotificationApiNotificationsNotificationIdDelete**](NotificationsApi.md#deletenotificationapinotificationsnotificationiddelete) | **DELETE** /api/notifications/{notification_id} | Delete Notification
[**getNotificationApiNotificationsNotificationIdGet**](NotificationsApi.md#getnotificationapinotificationsnotificationidget) | **GET** /api/notifications/{notification_id} | Get Notification
[**getNotificationStatsApiNotificationsStatsGet**](NotificationsApi.md#getnotificationstatsapinotificationsstatsget) | **GET** /api/notifications/stats | Get Notification Stats
[**getNotificationsApiNotificationsGet**](NotificationsApi.md#getnotificationsapinotificationsget) | **GET** /api/notifications/ | Get Notifications
[**sendNotificationApiNotificationsNotificationIdSendPost**](NotificationsApi.md#sendnotificationapinotificationsnotificationidsendpost) | **POST** /api/notifications/{notification_id}/send | Send Notification
[**sendPendingNotificationsApiNotificationsBatchSendPost**](NotificationsApi.md#sendpendingnotificationsapinotificationsbatchsendpost) | **POST** /api/notifications/batch/send | Send Pending Notifications
[**updateNotificationApiNotificationsNotificationIdPut**](NotificationsApi.md#updatenotificationapinotificationsnotificationidput) | **PUT** /api/notifications/{notification_id} | Update Notification


# **cancelNotificationApiNotificationsNotificationIdCancelPost**
> JsonObject cancelNotificationApiNotificationsNotificationIdCancelPost(notificationId)

Cancel Notification

取消通知

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getNotificationsApi();
final int notificationId = 56; // int | 

try {
    final response = api.cancelNotificationApiNotificationsNotificationIdCancelPost(notificationId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling NotificationsApi->cancelNotificationApiNotificationsNotificationIdCancelPost: $e\n');
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

# **createEmailNotificationApiNotificationsEmailPost**
> NotificationResponse createEmailNotificationApiNotificationsEmailPost(emailNotification)

Create Email Notification

创建邮件通知

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getNotificationsApi();
final EmailNotification emailNotification = ; // EmailNotification | 

try {
    final response = api.createEmailNotificationApiNotificationsEmailPost(emailNotification);
    print(response);
} catch on DioException (e) {
    print('Exception when calling NotificationsApi->createEmailNotificationApiNotificationsEmailPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **emailNotification** | [**EmailNotification**](EmailNotification.md)|  | 

### Return type

[**NotificationResponse**](NotificationResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createNotificationApiNotificationsPost**
> NotificationResponse createNotificationApiNotificationsPost(notificationCreate)

Create Notification

创建通知

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

# **createPushNotificationApiNotificationsPushPost**
> NotificationResponse createPushNotificationApiNotificationsPushPost(pushNotification)

Create Push Notification

创建推送通知

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getNotificationsApi();
final PushNotification pushNotification = ; // PushNotification | 

try {
    final response = api.createPushNotificationApiNotificationsPushPost(pushNotification);
    print(response);
} catch on DioException (e) {
    print('Exception when calling NotificationsApi->createPushNotificationApiNotificationsPushPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **pushNotification** | [**PushNotification**](PushNotification.md)|  | 

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

删除通知

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

获取指定通知

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

获取通知统计信息

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
> NotificationList getNotificationsApiNotificationsGet(skip, limit, notificationType, status)

Get Notifications

获取通知列表

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getNotificationsApi();
final int skip = 56; // int | 
final int limit = 56; // int | 
final AppSchemasNotificationNotificationType notificationType = ; // AppSchemasNotificationNotificationType | 
final AppSchemasNotificationNotificationStatus status = ; // AppSchemasNotificationNotificationStatus | 

try {
    final response = api.getNotificationsApiNotificationsGet(skip, limit, notificationType, status);
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
 **notificationType** | [**AppSchemasNotificationNotificationType**](.md)|  | [optional] 
 **status** | [**AppSchemasNotificationNotificationStatus**](.md)|  | [optional] 

### Return type

[**NotificationList**](NotificationList.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sendNotificationApiNotificationsNotificationIdSendPost**
> JsonObject sendNotificationApiNotificationsNotificationIdSendPost(notificationId)

Send Notification

发送通知

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getNotificationsApi();
final int notificationId = 56; // int | 

try {
    final response = api.sendNotificationApiNotificationsNotificationIdSendPost(notificationId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling NotificationsApi->sendNotificationApiNotificationsNotificationIdSendPost: $e\n');
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

# **sendPendingNotificationsApiNotificationsBatchSendPost**
> JsonObject sendPendingNotificationsApiNotificationsBatchSendPost()

Send Pending Notifications

批量发送待处理通知（需要超级用户权限）

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getNotificationsApi();

try {
    final response = api.sendPendingNotificationsApiNotificationsBatchSendPost();
    print(response);
} catch on DioException (e) {
    print('Exception when calling NotificationsApi->sendPendingNotificationsApiNotificationsBatchSendPost: $e\n');
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

# **updateNotificationApiNotificationsNotificationIdPut**
> NotificationResponse updateNotificationApiNotificationsNotificationIdPut(notificationId, notificationUpdate)

Update Notification

更新通知

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

