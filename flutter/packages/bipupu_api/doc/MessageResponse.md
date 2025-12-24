# openapi.model.MessageResponse

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**title** | **String** |  | 
**content** | **String** |  | 
**messageType** | [**AppModelsMessageMessageType**](AppModelsMessageMessageType.md) |  | 
**priority** | **int** |  | [optional] [default to 0]
**deviceId** | **int** |  | [optional] 
**pattern** | [**BuiltMap&lt;String, JsonObject&gt;**](JsonObject.md) |  | [optional] 
**senderId** | **int** |  | 
**receiverId** | **int** |  | 
**id** | **int** |  | 
**status** | [**AppSchemasMessageMessageStatus**](AppSchemasMessageMessageStatus.md) |  | 
**isRead** | **bool** |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**deliveredAt** | [**DateTime**](DateTime.md) |  | [optional] 
**readAt** | [**DateTime**](DateTime.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


