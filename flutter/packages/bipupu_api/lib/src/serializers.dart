//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:openapi/src/date_serializer.dart';
import 'package:openapi/src/model/date.dart';

import 'package:openapi/src/model/admin_log_response.dart';
import 'package:openapi/src/model/app_models_message_message_type.dart';
import 'package:openapi/src/model/app_schemas_friendship_friendship_status.dart';
import 'package:openapi/src/model/app_schemas_message_message_status.dart';
import 'package:openapi/src/model/app_schemas_notification_notification_status.dart';
import 'package:openapi/src/model/device_create.dart';
import 'package:openapi/src/model/device_list.dart';
import 'package:openapi/src/model/device_response.dart';
import 'package:openapi/src/model/device_stats.dart';
import 'package:openapi/src/model/device_update.dart';
import 'package:openapi/src/model/friendship_create.dart';
import 'package:openapi/src/model/friendship_list.dart';
import 'package:openapi/src/model/friendship_response.dart';
import 'package:openapi/src/model/http_validation_error.dart';
import 'package:openapi/src/model/message_ack_event_create.dart';
import 'package:openapi/src/model/message_ack_event_response.dart';
import 'package:openapi/src/model/message_create.dart';
import 'package:openapi/src/model/message_list.dart';
import 'package:openapi/src/model/message_response.dart';
import 'package:openapi/src/model/message_stats.dart';
import 'package:openapi/src/model/message_update.dart';
import 'package:openapi/src/model/notification_create.dart';
import 'package:openapi/src/model/notification_list.dart';
import 'package:openapi/src/model/notification_response.dart';
import 'package:openapi/src/model/notification_stats.dart';
import 'package:openapi/src/model/notification_update.dart';
import 'package:openapi/src/model/token.dart';
import 'package:openapi/src/model/token_refresh.dart';
import 'package:openapi/src/model/user_create.dart';
import 'package:openapi/src/model/user_login.dart';
import 'package:openapi/src/model/user_profile.dart';
import 'package:openapi/src/model/user_response.dart';
import 'package:openapi/src/model/user_update.dart';
import 'package:openapi/src/model/validation_error.dart';
import 'package:openapi/src/model/validation_error_loc_inner.dart';

part 'serializers.g.dart';

@SerializersFor([
  AdminLogResponse,
  AppModelsMessageMessageType,
  AppSchemasFriendshipFriendshipStatus,
  AppSchemasMessageMessageStatus,
  AppSchemasNotificationNotificationStatus,
  DeviceCreate,
  DeviceList,
  DeviceResponse,
  DeviceStats,
  DeviceUpdate,
  FriendshipCreate,
  FriendshipList,
  FriendshipResponse,
  HTTPValidationError,
  MessageAckEventCreate,
  MessageAckEventResponse,
  MessageCreate,
  MessageList,
  MessageResponse,
  MessageStats,
  MessageUpdate,
  NotificationCreate,
  NotificationList,
  NotificationResponse,
  NotificationStats,
  NotificationUpdate,
  Token,
  TokenRefresh,
  UserCreate,
  UserLogin,
  UserProfile,
  UserResponse,
  UserUpdate,
  ValidationError,
  ValidationErrorLocInner,
])
Serializers serializers = (_$serializers.toBuilder()
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(MessageAckEventResponse)]),
        () => ListBuilder<MessageAckEventResponse>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(AdminLogResponse)]),
        () => ListBuilder<AdminLogResponse>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(UserResponse)]),
        () => ListBuilder<UserResponse>(),
      )
      ..add(const OneOfSerializer())
      ..add(const AnyOfSerializer())
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer())
    ).build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
