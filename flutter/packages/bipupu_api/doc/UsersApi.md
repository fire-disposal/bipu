# openapi.api.UsersApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**deleteUserApiUsersUserIdDelete**](UsersApi.md#deleteuserapiusersuseriddelete) | **DELETE** /api/users/{user_id} | Delete User
[**getCurrentUserInfoApiUsersMeGet**](UsersApi.md#getcurrentuserinfoapiusersmeget) | **GET** /api/users/me | Get Current User Info
[**getUserApiUsersUserIdGet**](UsersApi.md#getuserapiusersuseridget) | **GET** /api/users/{user_id} | Get User
[**getUsersApiUsersGet**](UsersApi.md#getusersapiusersget) | **GET** /api/users/ | Get Users
[**loginApiUsersLoginPost**](UsersApi.md#loginapiusersloginpost) | **POST** /api/users/login | Login
[**registerUserApiUsersRegisterPost**](UsersApi.md#registeruserapiusersregisterpost) | **POST** /api/users/register | Register User
[**updateCurrentUserApiUsersMePut**](UsersApi.md#updatecurrentuserapiusersmeput) | **PUT** /api/users/me | Update Current User
[**updateUserApiUsersUserIdPut**](UsersApi.md#updateuserapiusersuseridput) | **PUT** /api/users/{user_id} | Update User


# **deleteUserApiUsersUserIdDelete**
> JsonObject deleteUserApiUsersUserIdDelete(userId)

Delete User

删除用户（需要超级用户权限）

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getUsersApi();
final int userId = 56; // int | 

try {
    final response = api.deleteUserApiUsersUserIdDelete(userId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling UsersApi->deleteUserApiUsersUserIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **int**|  | 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getCurrentUserInfoApiUsersMeGet**
> UserResponse getCurrentUserInfoApiUsersMeGet()

Get Current User Info

获取当前用户信息

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getUsersApi();

try {
    final response = api.getCurrentUserInfoApiUsersMeGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling UsersApi->getCurrentUserInfoApiUsersMeGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**UserResponse**](UserResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getUserApiUsersUserIdGet**
> UserResponse getUserApiUsersUserIdGet(userId)

Get User

获取指定用户（需要超级用户权限）

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getUsersApi();
final int userId = 56; // int | 

try {
    final response = api.getUserApiUsersUserIdGet(userId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling UsersApi->getUserApiUsersUserIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **int**|  | 

### Return type

[**UserResponse**](UserResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getUsersApiUsersGet**
> BuiltList<UserResponse> getUsersApiUsersGet(skip, limit)

Get Users

获取用户列表（需要超级用户权限）

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getUsersApi();
final int skip = 56; // int | 
final int limit = 56; // int | 

try {
    final response = api.getUsersApiUsersGet(skip, limit);
    print(response);
} catch on DioException (e) {
    print('Exception when calling UsersApi->getUsersApiUsersGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **skip** | **int**|  | [optional] [default to 0]
 **limit** | **int**|  | [optional] [default to 100]

### Return type

[**BuiltList&lt;UserResponse&gt;**](UserResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **loginApiUsersLoginPost**
> Token loginApiUsersLoginPost(userLogin)

Login

用户登录

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getUsersApi();
final UserLogin userLogin = ; // UserLogin | 

try {
    final response = api.loginApiUsersLoginPost(userLogin);
    print(response);
} catch on DioException (e) {
    print('Exception when calling UsersApi->loginApiUsersLoginPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userLogin** | [**UserLogin**](UserLogin.md)|  | 

### Return type

[**Token**](Token.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **registerUserApiUsersRegisterPost**
> UserResponse registerUserApiUsersRegisterPost(userCreate)

Register User

用户注册

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getUsersApi();
final UserCreate userCreate = ; // UserCreate | 

try {
    final response = api.registerUserApiUsersRegisterPost(userCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling UsersApi->registerUserApiUsersRegisterPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userCreate** | [**UserCreate**](UserCreate.md)|  | 

### Return type

[**UserResponse**](UserResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateCurrentUserApiUsersMePut**
> UserResponse updateCurrentUserApiUsersMePut(userUpdate)

Update Current User

更新当前用户信息

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getUsersApi();
final UserUpdate userUpdate = ; // UserUpdate | 

try {
    final response = api.updateCurrentUserApiUsersMePut(userUpdate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling UsersApi->updateCurrentUserApiUsersMePut: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userUpdate** | [**UserUpdate**](UserUpdate.md)|  | 

### Return type

[**UserResponse**](UserResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateUserApiUsersUserIdPut**
> UserResponse updateUserApiUsersUserIdPut(userId, userUpdate)

Update User

更新用户信息（需要超级用户权限）

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getUsersApi();
final int userId = 56; // int | 
final UserUpdate userUpdate = ; // UserUpdate | 

try {
    final response = api.updateUserApiUsersUserIdPut(userId, userUpdate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling UsersApi->updateUserApiUsersUserIdPut: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **int**|  | 
 **userUpdate** | [**UserUpdate**](UserUpdate.md)|  | 

### Return type

[**UserResponse**](UserResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

