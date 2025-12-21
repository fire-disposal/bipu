//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:openapi/src/model/app_schemas_notification_notification_status.dart';
import 'package:openapi/src/model/app_schemas_notification_notification_type.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notification_update.g.dart';

/// 更新通知模式
///
/// Properties:
/// * [title]
/// * [content]
/// * [notificationType]
/// * [priority]
/// * [status]
/// * [target]
/// * [config]
/// * [scheduledAt]
/// * [retryCount]
/// * [result]
/// * [errorMessage]
@BuiltValue()
abstract class NotificationUpdate
    implements Built<NotificationUpdate, NotificationUpdateBuilder> {
  @BuiltValueField(wireName: r'title')
  String? get title;

  @BuiltValueField(wireName: r'content')
  String? get content;

  @BuiltValueField(wireName: r'notification_type')
  AppSchemasNotificationNotificationType? get notificationType;
  // enum notificationTypeEnum {  push,  email,  sms,  webhook,  };

  @BuiltValueField(wireName: r'priority')
  int? get priority;

  @BuiltValueField(wireName: r'status')
  AppSchemasNotificationNotificationStatus? get status;
  // enum statusEnum {  pending,  sent,  failed,  cancelled,  };

  @BuiltValueField(wireName: r'target')
  String? get target;

  @BuiltValueField(wireName: r'config')
  BuiltMap<String, JsonObject?>? get config;

  @BuiltValueField(wireName: r'scheduled_at')
  DateTime? get scheduledAt;

  @BuiltValueField(wireName: r'retry_count')
  int? get retryCount;

  @BuiltValueField(wireName: r'result')
  String? get result;

  @BuiltValueField(wireName: r'error_message')
  String? get errorMessage;

  NotificationUpdate._();

  factory NotificationUpdate([void updates(NotificationUpdateBuilder b)]) =
      _$NotificationUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotificationUpdateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotificationUpdate> get serializer =>
      _$NotificationUpdateSerializer();
}

class _$NotificationUpdateSerializer
    implements PrimitiveSerializer<NotificationUpdate> {
  @override
  final Iterable<Type> types = const [NotificationUpdate, _$NotificationUpdate];

  @override
  final String wireName = r'NotificationUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotificationUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.title != null) {
      yield r'title';
      yield serializers.serialize(
        object.title,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.content != null) {
      yield r'content';
      yield serializers.serialize(
        object.content,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.notificationType != null) {
      yield r'notification_type';
      yield serializers.serialize(
        object.notificationType,
        specifiedType:
            const FullType.nullable(AppSchemasNotificationNotificationType),
      );
    }
    if (object.priority != null) {
      yield r'priority';
      yield serializers.serialize(
        object.priority,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.status != null) {
      yield r'status';
      yield serializers.serialize(
        object.status,
        specifiedType:
            const FullType.nullable(AppSchemasNotificationNotificationStatus),
      );
    }
    if (object.target != null) {
      yield r'target';
      yield serializers.serialize(
        object.target,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.config != null) {
      yield r'config';
      yield serializers.serialize(
        object.config,
        specifiedType: const FullType.nullable(
            BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
      );
    }
    if (object.scheduledAt != null) {
      yield r'scheduled_at';
      yield serializers.serialize(
        object.scheduledAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.retryCount != null) {
      yield r'retry_count';
      yield serializers.serialize(
        object.retryCount,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.result != null) {
      yield r'result';
      yield serializers.serialize(
        object.result,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.errorMessage != null) {
      yield r'error_message';
      yield serializers.serialize(
        object.errorMessage,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    NotificationUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object,
            specifiedType: specifiedType)
        .toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required NotificationUpdateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.title = valueDes;
          break;
        case r'content':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.content = valueDes;
          break;
        case r'notification_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType.nullable(AppSchemasNotificationNotificationType),
          ) as AppSchemasNotificationNotificationType?;
          if (valueDes == null) continue;
          result.notificationType = valueDes;
          break;
        case r'priority':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.priority = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(
                AppSchemasNotificationNotificationStatus),
          ) as AppSchemasNotificationNotificationStatus?;
          if (valueDes == null) continue;
          result.status = valueDes;
          break;
        case r'target':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.target = valueDes;
          break;
        case r'config':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(
                BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
          ) as BuiltMap<String, JsonObject?>?;
          if (valueDes == null) continue;
          result.config.replace(valueDes);
          break;
        case r'scheduled_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.scheduledAt = valueDes;
          break;
        case r'retry_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.retryCount = valueDes;
          break;
        case r'result':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.result = valueDes;
          break;
        case r'error_message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.errorMessage = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotificationUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotificationUpdateBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}
