# openapi.api.SystemApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**healthCheckHealthGet**](SystemApi.md#healthcheckhealthget) | **GET** /health | Health Check


# **healthCheckHealthGet**
> JsonObject healthCheckHealthGet()

Health Check

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getSystemApi();

try {
    final response = api.healthCheckHealthGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling SystemApi->healthCheckHealthGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

