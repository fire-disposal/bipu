# openapi.api.FriendshipsApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**acceptFriendRequestApiFriendshipsFriendshipIdAcceptPut**](FriendshipsApi.md#acceptfriendrequestapifriendshipsfriendshipidacceptput) | **PUT** /api/friendships/{friendship_id}/accept | Accept Friend Request
[**adminDeleteFriendshipApiFriendshipsAdminFriendshipIdDelete**](FriendshipsApi.md#admindeletefriendshipapifriendshipsadminfriendshipiddelete) | **DELETE** /api/friendships/admin/{friendship_id} | Admin Delete Friendship
[**adminGetAllFriendshipsApiFriendshipsAdminAllGet**](FriendshipsApi.md#admingetallfriendshipsapifriendshipsadminallget) | **GET** /api/friendships/admin/all | Admin Get All Friendships
[**createFriendRequestApiFriendshipsPost**](FriendshipsApi.md#createfriendrequestapifriendshipspost) | **POST** /api/friendships/ | Create Friend Request
[**deleteFriendApiFriendshipsFriendshipIdDelete**](FriendshipsApi.md#deletefriendapifriendshipsfriendshipiddelete) | **DELETE** /api/friendships/{friendship_id} | Delete Friend
[**getFriendRequestsApiFriendshipsRequestsGet**](FriendshipsApi.md#getfriendrequestsapifriendshipsrequestsget) | **GET** /api/friendships/requests | Get Friend Requests
[**getFriendsApiFriendshipsFriendsGet**](FriendshipsApi.md#getfriendsapifriendshipsfriendsget) | **GET** /api/friendships/friends | Get Friends
[**getFriendshipsApiFriendshipsGet**](FriendshipsApi.md#getfriendshipsapifriendshipsget) | **GET** /api/friendships/ | Get Friendships
[**rejectFriendRequestApiFriendshipsFriendshipIdRejectPut**](FriendshipsApi.md#rejectfriendrequestapifriendshipsfriendshipidrejectput) | **PUT** /api/friendships/{friendship_id}/reject | Reject Friend Request


# **acceptFriendRequestApiFriendshipsFriendshipIdAcceptPut**
> FriendshipResponse acceptFriendRequestApiFriendshipsFriendshipIdAcceptPut(friendshipId)

Accept Friend Request

接受好友请求

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getFriendshipsApi();
final int friendshipId = 56; // int | 

try {
    final response = api.acceptFriendRequestApiFriendshipsFriendshipIdAcceptPut(friendshipId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FriendshipsApi->acceptFriendRequestApiFriendshipsFriendshipIdAcceptPut: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **friendshipId** | **int**|  | 

### Return type

[**FriendshipResponse**](FriendshipResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminDeleteFriendshipApiFriendshipsAdminFriendshipIdDelete**
> JsonObject adminDeleteFriendshipApiFriendshipsAdminFriendshipIdDelete(friendshipId)

Admin Delete Friendship

管理端：删除好友关系（需要超级用户权限）

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getFriendshipsApi();
final int friendshipId = 56; // int | 

try {
    final response = api.adminDeleteFriendshipApiFriendshipsAdminFriendshipIdDelete(friendshipId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FriendshipsApi->adminDeleteFriendshipApiFriendshipsAdminFriendshipIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **friendshipId** | **int**|  | 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminGetAllFriendshipsApiFriendshipsAdminAllGet**
> FriendshipList adminGetAllFriendshipsApiFriendshipsAdminAllGet(skip, limit, status)

Admin Get All Friendships

管理端：获取所有好友关系（需要超级用户权限）

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getFriendshipsApi();
final int skip = 56; // int | 
final int limit = 56; // int | 
final AppSchemasFriendshipFriendshipStatus status = ; // AppSchemasFriendshipFriendshipStatus | 

try {
    final response = api.adminGetAllFriendshipsApiFriendshipsAdminAllGet(skip, limit, status);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FriendshipsApi->adminGetAllFriendshipsApiFriendshipsAdminAllGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **skip** | **int**|  | [optional] [default to 0]
 **limit** | **int**|  | [optional] [default to 100]
 **status** | [**AppSchemasFriendshipFriendshipStatus**](.md)|  | [optional] 

### Return type

[**FriendshipList**](FriendshipList.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createFriendRequestApiFriendshipsPost**
> FriendshipResponse createFriendRequestApiFriendshipsPost(friendshipCreate)

Create Friend Request

发送好友请求

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getFriendshipsApi();
final FriendshipCreate friendshipCreate = ; // FriendshipCreate | 

try {
    final response = api.createFriendRequestApiFriendshipsPost(friendshipCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FriendshipsApi->createFriendRequestApiFriendshipsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **friendshipCreate** | [**FriendshipCreate**](FriendshipCreate.md)|  | 

### Return type

[**FriendshipResponse**](FriendshipResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteFriendApiFriendshipsFriendshipIdDelete**
> JsonObject deleteFriendApiFriendshipsFriendshipIdDelete(friendshipId)

Delete Friend

删除好友关系

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getFriendshipsApi();
final int friendshipId = 56; // int | 

try {
    final response = api.deleteFriendApiFriendshipsFriendshipIdDelete(friendshipId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FriendshipsApi->deleteFriendApiFriendshipsFriendshipIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **friendshipId** | **int**|  | 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getFriendRequestsApiFriendshipsRequestsGet**
> FriendshipList getFriendRequestsApiFriendshipsRequestsGet(skip, limit)

Get Friend Requests

获取待处理的好友请求

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getFriendshipsApi();
final int skip = 56; // int | 
final int limit = 56; // int | 

try {
    final response = api.getFriendRequestsApiFriendshipsRequestsGet(skip, limit);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FriendshipsApi->getFriendRequestsApiFriendshipsRequestsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **skip** | **int**|  | [optional] [default to 0]
 **limit** | **int**|  | [optional] [default to 100]

### Return type

[**FriendshipList**](FriendshipList.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getFriendsApiFriendshipsFriendsGet**
> BuiltList<UserResponse> getFriendsApiFriendshipsFriendsGet()

Get Friends

获取好友列表

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getFriendshipsApi();

try {
    final response = api.getFriendsApiFriendshipsFriendsGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling FriendshipsApi->getFriendsApiFriendshipsFriendsGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BuiltList&lt;UserResponse&gt;**](UserResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getFriendshipsApiFriendshipsGet**
> FriendshipList getFriendshipsApiFriendshipsGet(skip, limit, status)

Get Friendships

获取好友关系列表

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getFriendshipsApi();
final int skip = 56; // int | 
final int limit = 56; // int | 
final AppSchemasFriendshipFriendshipStatus status = ; // AppSchemasFriendshipFriendshipStatus | 

try {
    final response = api.getFriendshipsApiFriendshipsGet(skip, limit, status);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FriendshipsApi->getFriendshipsApiFriendshipsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **skip** | **int**|  | [optional] [default to 0]
 **limit** | **int**|  | [optional] [default to 100]
 **status** | [**AppSchemasFriendshipFriendshipStatus**](.md)|  | [optional] 

### Return type

[**FriendshipList**](FriendshipList.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **rejectFriendRequestApiFriendshipsFriendshipIdRejectPut**
> FriendshipResponse rejectFriendRequestApiFriendshipsFriendshipIdRejectPut(friendshipId)

Reject Friend Request

拒绝好友请求

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getFriendshipsApi();
final int friendshipId = 56; // int | 

try {
    final response = api.rejectFriendRequestApiFriendshipsFriendshipIdRejectPut(friendshipId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FriendshipsApi->rejectFriendRequestApiFriendshipsFriendshipIdRejectPut: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **friendshipId** | **int**|  | 

### Return type

[**FriendshipResponse**](FriendshipResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

