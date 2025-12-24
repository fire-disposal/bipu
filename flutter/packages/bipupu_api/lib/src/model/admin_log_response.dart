//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'admin_log_response.g.dart';

/// 管理员操作日志响应模式
///
/// Properties:
/// * [adminId] - 管理员ID
/// * [action] - 操作类型
/// * [detail] 
/// * [timestamp] - 操作时间
/// * [id] 
@BuiltValue()
abstract class AdminLogResponse implements Built<AdminLogResponse, AdminLogResponseBuilder> {
  /// 管理员ID
  @BuiltValueField(wireName: r'admin_id')
  int get adminId;

  /// 操作类型
  @BuiltValueField(wireName: r'action')
  String get action;

  @BuiltValueField(wireName: r'detail')
  BuiltMap<String, JsonObject?>? get detail;

  /// 操作时间
  @BuiltValueField(wireName: r'timestamp')
  DateTime? get timestamp;

  @BuiltValueField(wireName: r'id')
  int get id;

  AdminLogResponse._();

  factory AdminLogResponse([void updates(AdminLogResponseBuilder b)]) = _$AdminLogResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AdminLogResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AdminLogResponse> get serializer => _$AdminLogResponseSerializer();
}

class _$AdminLogResponseSerializer implements PrimitiveSerializer<AdminLogResponse> {
  @override
  final Iterable<Type> types = const [AdminLogResponse, _$AdminLogResponse];

  @override
  final String wireName = r'AdminLogResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AdminLogResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'admin_id';
    yield serializers.serialize(
      object.adminId,
      specifiedType: const FullType(int),
    );
    yield r'action';
    yield serializers.serialize(
      object.action,
      specifiedType: const FullType(String),
    );
    if (object.detail != null) {
      yield r'detail';
      yield serializers.serialize(
        object.detail,
        specifiedType: const FullType.nullable(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
      );
    }
    if (object.timestamp != null) {
      yield r'timestamp';
      yield serializers.serialize(
        object.timestamp,
        specifiedType: const FullType(DateTime),
      );
    }
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AdminLogResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AdminLogResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'admin_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.adminId = valueDes;
          break;
        case r'action':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.action = valueDes;
          break;
        case r'detail':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
          ) as BuiltMap<String, JsonObject?>?;
          if (valueDes == null) continue;
          result.detail.replace(valueDes);
          break;
        case r'timestamp':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.timestamp = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.id = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AdminLogResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AdminLogResponseBuilder();
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

