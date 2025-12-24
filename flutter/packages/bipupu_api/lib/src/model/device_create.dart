//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'device_create.g.dart';

/// 创建设备模式
///
/// Properties:
/// * [deviceIdentifier] - 设备唯一标识（BLE MAC/UUID/序列号）
/// * [userId] - 绑定用户ID，强制1:1
/// * [lastSeen] 
@BuiltValue()
abstract class DeviceCreate implements Built<DeviceCreate, DeviceCreateBuilder> {
  /// 设备唯一标识（BLE MAC/UUID/序列号）
  @BuiltValueField(wireName: r'device_identifier')
  String get deviceIdentifier;

  /// 绑定用户ID，强制1:1
  @BuiltValueField(wireName: r'user_id')
  int get userId;

  @BuiltValueField(wireName: r'last_seen')
  DateTime? get lastSeen;

  DeviceCreate._();

  factory DeviceCreate([void updates(DeviceCreateBuilder b)]) = _$DeviceCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DeviceCreateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DeviceCreate> get serializer => _$DeviceCreateSerializer();
}

class _$DeviceCreateSerializer implements PrimitiveSerializer<DeviceCreate> {
  @override
  final Iterable<Type> types = const [DeviceCreate, _$DeviceCreate];

  @override
  final String wireName = r'DeviceCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DeviceCreate object, {
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
  }

  @override
  Object serialize(
    Serializers serializers,
    DeviceCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DeviceCreateBuilder result,
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DeviceCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeviceCreateBuilder();
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

