//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'device_stats.g.dart';

/// 设备统计信息
///
/// Properties:
/// * [total] 
/// * [online] 
/// * [offline] 
/// * [error] 
/// * [maintenance] 
@BuiltValue()
abstract class DeviceStats implements Built<DeviceStats, DeviceStatsBuilder> {
  @BuiltValueField(wireName: r'total')
  int get total;

  @BuiltValueField(wireName: r'online')
  int get online;

  @BuiltValueField(wireName: r'offline')
  int get offline;

  @BuiltValueField(wireName: r'error')
  int get error;

  @BuiltValueField(wireName: r'maintenance')
  int get maintenance;

  DeviceStats._();

  factory DeviceStats([void updates(DeviceStatsBuilder b)]) = _$DeviceStats;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DeviceStatsBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DeviceStats> get serializer => _$DeviceStatsSerializer();
}

class _$DeviceStatsSerializer implements PrimitiveSerializer<DeviceStats> {
  @override
  final Iterable<Type> types = const [DeviceStats, _$DeviceStats];

  @override
  final String wireName = r'DeviceStats';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DeviceStats object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'total';
    yield serializers.serialize(
      object.total,
      specifiedType: const FullType(int),
    );
    yield r'online';
    yield serializers.serialize(
      object.online,
      specifiedType: const FullType(int),
    );
    yield r'offline';
    yield serializers.serialize(
      object.offline,
      specifiedType: const FullType(int),
    );
    yield r'error';
    yield serializers.serialize(
      object.error,
      specifiedType: const FullType(int),
    );
    yield r'maintenance';
    yield serializers.serialize(
      object.maintenance,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DeviceStats object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DeviceStatsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'total':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.total = valueDes;
          break;
        case r'online':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.online = valueDes;
          break;
        case r'offline':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.offline = valueDes;
          break;
        case r'error':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.error = valueDes;
          break;
        case r'maintenance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.maintenance = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DeviceStats deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeviceStatsBuilder();
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

