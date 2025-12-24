# openapi.api.MessageAckApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminGetAckStatsApiMessageAckAdminStatsGet**](MessageAckApi.md#admingetackstatsapimessageackadminstatsget) | **GET** /api/message-ack/admin/stats | Admin Get Ack Stats
[**adminGetAllAckEventsApiMessageAckAdminAllGet**](MessageAckApi.md#admingetallackeventsapimessageackadminallget) | **GET** /api/message-ack/admin/all | Admin Get All Ack Events
[**createMessageAckEventApiMessageAckPost**](MessageAckApi.md#createmessageackeventapimessageackpost) | **POST** /api/message-ack/ | Create Message Ack Event
[**getMessageAckEventsApiMessageAckMessageMessageIdGet**](MessageAckApi.md#getmessageackeventsapimessageackmessagemessageidget) | **GET** /api/message-ack/message/{message_id} | Get Message Ack Events


# **adminGetAckStatsApiMessageAckAdminStatsGet**
> JsonObject adminGetAckStatsApiMessageAckAdminStatsGet()

Admin Get Ack Stats

管理端：获取消息回执统计（需要超级用户权限）

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getMessageAckApi();

try {
    final response = api.adminGetAckStatsApiMessageAckAdminStatsGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling MessageAckApi->adminGetAckStatsApiMessageAckAdminStatsGet: $e\n');
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

# **adminGetAllAckEventsApiMessageAckAdminAllGet**
> BuiltList<MessageAckEventResponse> adminGetAllAckEventsApiMessageAckAdminAllGet(skip, limit)

Admin Get All Ack Events

管理端：获取所有消息回执事件（需要超级用户权限）

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getMessageAckApi();
final int skip = 56; // int | 
final int limit = 56; // int | 

try {
    final response = api.adminGetAllAckEventsApiMessageAckAdminAllGet(skip, limit);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MessageAckApi->adminGetAllAckEventsApiMessageAckAdminAllGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **skip** | **int**|  | [optional] [default to 0]
 **limit** | **int**|  | [optional] [default to 100]

### Return type

[**BuiltList&lt;MessageAckEventResponse&gt;**](MessageAckEventResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createMessageAckEventApiMessageAckPost**
> MessageAckEventResponse createMessageAckEventApiMessageAckPost(messageAckEventCreate)

Create Message Ack Event

创建消息回执事件

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getMessageAckApi();
final MessageAckEventCreate messageAckEventCreate = ; // MessageAckEventCreate | 

try {
    final response = api.createMessageAckEventApiMessageAckPost(messageAckEventCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MessageAckApi->createMessageAckEventApiMessageAckPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **messageAckEventCreate** | [**MessageAckEventCreate**](MessageAckEventCreate.md)|  | 

### Return type

[**MessageAckEventResponse**](MessageAckEventResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMessageAckEventsApiMessageAckMessageMessageIdGet**
> BuiltList<MessageAckEventResponse> getMessageAckEventsApiMessageAckMessageMessageIdGet(messageId)

Get Message Ack Events

获取指定消息的所有回执事件

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getMessageAckApi();
final int messageId = 56; // int | 

try {
    final response = api.getMessageAckEventsApiMessageAckMessageMessageIdGet(messageId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MessageAckApi->getMessageAckEventsApiMessageAckMessageMessageIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **messageId** | **int**|  | 

### Return type

[**BuiltList&lt;MessageAckEventResponse&gt;**](MessageAckEventResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

