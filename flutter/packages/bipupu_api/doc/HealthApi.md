# openapi.api.HealthApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**healthCheckApiHealthGet**](HealthApi.md#healthcheckapihealthget) | **GET** /api/health/ | Health Check
[**livenessCheckApiHealthLiveGet**](HealthApi.md#livenesscheckapihealthliveget) | **GET** /api/health/live | Liveness Check
[**readinessCheckApiHealthReadyGet**](HealthApi.md#readinesscheckapihealthreadyget) | **GET** /api/health/ready | Readiness Check


# **healthCheckApiHealthGet**
> JsonObject healthCheckApiHealthGet()

Health Check

健康检查端点

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getHealthApi();

try {
    final response = api.healthCheckApiHealthGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling HealthApi->healthCheckApiHealthGet: $e\n');
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

# **livenessCheckApiHealthLiveGet**
> JsonObject livenessCheckApiHealthLiveGet()

Liveness Check

存活检查端点

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getHealthApi();

try {
    final response = api.livenessCheckApiHealthLiveGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling HealthApi->livenessCheckApiHealthLiveGet: $e\n');
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

# **readinessCheckApiHealthReadyGet**
> JsonObject readinessCheckApiHealthReadyGet()

Readiness Check

就绪检查端点

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getHealthApi();

try {
    final response = api.readinessCheckApiHealthReadyGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling HealthApi->readinessCheckApiHealthReadyGet: $e\n');
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

