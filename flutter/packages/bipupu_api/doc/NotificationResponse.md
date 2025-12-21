# openapi.model.NotificationResponse

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**title** | **String** |  | 
**content** | **String** |  | 
**notificationType** | [**AppSchemasNotificationNotificationType**](AppSchemasNotificationNotificationType.md) |  | 
**priority** | **int** |  | [optional] [default to 0]
**target** | **String** |  | 
**config** | [**BuiltMap&lt;String, JsonObject&gt;**](JsonObject.md) |  | [optional] 
**scheduledAt** | [**DateTime**](DateTime.md) |  | [optional] 
**messageId** | **int** |  | [optional] 
**id** | **int** |  | 
**userId** | **int** |  | 
**status** | [**AppSchemasNotificationNotificationStatus**](AppSchemasNotificationNotificationStatus.md) |  | 
**retryCount** | **int** |  | 
**maxRetries** | **int** |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**sentAt** | [**DateTime**](DateTime.md) |  | [optional] 
**result** | **String** |  | [optional] 
**errorMessage** | **String** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


