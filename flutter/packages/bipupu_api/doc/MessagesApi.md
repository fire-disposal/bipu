# openapi.api.MessagesApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createMessageApiMessagesPost**](MessagesApi.md#createmessageapimessagespost) | **POST** /api/messages/ | Create Message
[**deleteMessageApiMessagesMessageIdDelete**](MessagesApi.md#deletemessageapimessagesmessageiddelete) | **DELETE** /api/messages/{message_id} | Delete Message
[**deleteReadMessagesApiMessagesDelete**](MessagesApi.md#deletereadmessagesapimessagesdelete) | **DELETE** /api/messages/ | Delete Read Messages
[**getMessageApiMessagesMessageIdGet**](MessagesApi.md#getmessageapimessagesmessageidget) | **GET** /api/messages/{message_id} | Get Message
[**getMessageStatsApiMessagesStatsGet**](MessagesApi.md#getmessagestatsapimessagesstatsget) | **GET** /api/messages/stats | Get Message Stats
[**getMessagesApiMessagesGet**](MessagesApi.md#getmessagesapimessagesget) | **GET** /api/messages/ | Get Messages
[**markAllMessagesAsReadApiMessagesReadAllPut**](MessagesApi.md#markallmessagesasreadapimessagesreadallput) | **PUT** /api/messages/read-all | Mark All Messages As Read
[**markMessageAsReadApiMessagesMessageIdReadPut**](MessagesApi.md#markmessageasreadapimessagesmessageidreadput) | **PUT** /api/messages/{message_id}/read | Mark Message As Read
[**updateMessageApiMessagesMessageIdPut**](MessagesApi.md#updatemessageapimessagesmessageidput) | **PUT** /api/messages/{message_id} | Update Message


# **createMessageApiMessagesPost**
> MessageResponse createMessageApiMessagesPost(messageCreate)

Create Message

创建消息

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getMessagesApi();
final MessageCreate messageCreate = ; // MessageCreate | 

try {
    final response = api.createMessageApiMessagesPost(messageCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MessagesApi->createMessageApiMessagesPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **messageCreate** | [**MessageCreate**](MessageCreate.md)|  | 

### Return type

[**MessageResponse**](MessageResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteMessageApiMessagesMessageIdDelete**
> JsonObject deleteMessageApiMessagesMessageIdDelete(messageId)

Delete Message

删除消息

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getMessagesApi();
final int messageId = 56; // int | 

try {
    final response = api.deleteMessageApiMessagesMessageIdDelete(messageId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MessagesApi->deleteMessageApiMessagesMessageIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **messageId** | **int**|  | 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteReadMessagesApiMessagesDelete**
> JsonObject deleteReadMessagesApiMessagesDelete()

Delete Read Messages

删除所有已读消息

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getMessagesApi();

try {
    final response = api.deleteReadMessagesApiMessagesDelete();
    print(response);
} catch on DioException (e) {
    print('Exception when calling MessagesApi->deleteReadMessagesApiMessagesDelete: $e\n');
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

# **getMessageApiMessagesMessageIdGet**
> MessageResponse getMessageApiMessagesMessageIdGet(messageId)

Get Message

获取指定消息

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getMessagesApi();
final int messageId = 56; // int | 

try {
    final response = api.getMessageApiMessagesMessageIdGet(messageId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MessagesApi->getMessageApiMessagesMessageIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **messageId** | **int**|  | 

### Return type

[**MessageResponse**](MessageResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMessageStatsApiMessagesStatsGet**
> MessageStats getMessageStatsApiMessagesStatsGet()

Get Message Stats

获取消息统计信息

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getMessagesApi();

try {
    final response = api.getMessageStatsApiMessagesStatsGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling MessagesApi->getMessageStatsApiMessagesStatsGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**MessageStats**](MessageStats.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMessagesApiMessagesGet**
> MessageList getMessagesApiMessagesGet(skip, limit, messageType, status, isRead)

Get Messages

获取消息列表

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getMessagesApi();
final int skip = 56; // int | 
final int limit = 56; // int | 
final AppSchemasMessageMessageType messageType = ; // AppSchemasMessageMessageType | 
final AppSchemasMessageMessageStatus status = ; // AppSchemasMessageMessageStatus | 
final bool isRead = true; // bool | 

try {
    final response = api.getMessagesApiMessagesGet(skip, limit, messageType, status, isRead);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MessagesApi->getMessagesApiMessagesGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **skip** | **int**|  | [optional] [default to 0]
 **limit** | **int**|  | [optional] [default to 100]
 **messageType** | [**AppSchemasMessageMessageType**](.md)|  | [optional] 
 **status** | [**AppSchemasMessageMessageStatus**](.md)|  | [optional] 
 **isRead** | **bool**|  | [optional] 

### Return type

[**MessageList**](MessageList.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markAllMessagesAsReadApiMessagesReadAllPut**
> JsonObject markAllMessagesAsReadApiMessagesReadAllPut()

Mark All Messages As Read

标记所有消息为已读

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getMessagesApi();

try {
    final response = api.markAllMessagesAsReadApiMessagesReadAllPut();
    print(response);
} catch on DioException (e) {
    print('Exception when calling MessagesApi->markAllMessagesAsReadApiMessagesReadAllPut: $e\n');
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

# **markMessageAsReadApiMessagesMessageIdReadPut**
> JsonObject markMessageAsReadApiMessagesMessageIdReadPut(messageId)

Mark Message As Read

标记消息为已读

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getMessagesApi();
final int messageId = 56; // int | 

try {
    final response = api.markMessageAsReadApiMessagesMessageIdReadPut(messageId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MessagesApi->markMessageAsReadApiMessagesMessageIdReadPut: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **messageId** | **int**|  | 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateMessageApiMessagesMessageIdPut**
> MessageResponse updateMessageApiMessagesMessageIdPut(messageId, messageUpdate)

Update Message

更新消息

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getMessagesApi();
final int messageId = 56; // int | 
final MessageUpdate messageUpdate = ; // MessageUpdate | 

try {
    final response = api.updateMessageApiMessagesMessageIdPut(messageId, messageUpdate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MessagesApi->updateMessageApiMessagesMessageIdPut: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **messageId** | **int**|  | 
 **messageUpdate** | [**MessageUpdate**](MessageUpdate.md)|  | 

### Return type

[**MessageResponse**](MessageResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

