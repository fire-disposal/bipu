//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'device_response.g.dart';

/// 设备响应模式
///
/// Properties:
/// * [deviceIdentifier] - 设备唯一标识（BLE MAC/UUID/序列号）
/// * [userId] - 绑定用户ID，强制1:1
/// * [lastSeen] 
/// * [id] 
/// * [createdAt] 
/// * [updatedAt] 
@BuiltValue()
abstract class DeviceResponse implements Built<DeviceResponse, DeviceResponseBuilder> {
  /// 设备唯一标识（BLE MAC/UUID/序列号）
  @BuiltValueField(wireName: r'device_identifier')
  String get deviceIdentifier;

  /// 绑定用户ID，强制1:1
  @BuiltValueField(wireName: r'user_id')
  int get userId;

  @BuiltValueField(wireName: r'last_seen')
  DateTime? get lastSeen;

  @BuiltValueField(wireName: r'id')
  int get id;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updated_at')
  DateTime? get updatedAt;

  DeviceResponse._();

  factory DeviceResponse([void updates(DeviceResponseBuilder b)]) = _$DeviceResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DeviceResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DeviceResponse> get serializer => _$DeviceResponseSerializer();
}

class _$DeviceResponseSerializer implements PrimitiveSerializer<DeviceResponse> {
  @override
  final Iterable<Type> types = const [DeviceResponse, _$DeviceResponse];

  @override
  final String wireName = r'DeviceResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DeviceResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'device_identifier';
    yield serializers.serialize(
      object.deviceIdentifier,
      specifiedType: const FullType(String),
    );
    yield r'user_id';
    yield serializers.serialize(
      object.userId,
      specifiedType: const FullType(int),
    );
    if (object.lastSeen != null) {
      yield r'last_seen';
      yield serializers.serialize(
        object.lastSeen,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(int),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.updatedAt != null) {
      yield r'updated_at';
      yield serializers.serialize(
        object.updatedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    DeviceResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DeviceResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'device_identifier':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.deviceIdentifier = valueDes;
          break;
        case r'user_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.userId = valueDes;
          break;
        case r'last_seen':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.lastSeen = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.id = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'updated_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.updatedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DeviceResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeviceResponseBuilder();
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

