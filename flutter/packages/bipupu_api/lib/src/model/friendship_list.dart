//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:openapi/src/model/friendship_response.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'friendship_list.g.dart';

/// FriendshipList
///
/// Properties:
/// * [items] 
/// * [total] 
/// * [page] 
/// * [size] 
@BuiltValue()
abstract class FriendshipList implements Built<FriendshipList, FriendshipListBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<FriendshipResponse> get items;

  @BuiltValueField(wireName: r'total')
  int get total;

  @BuiltValueField(wireName: r'page')
  int get page;

  @BuiltValueField(wireName: r'size')
  int get size;

  FriendshipList._();

  factory FriendshipList([void updates(FriendshipListBuilder b)]) = _$FriendshipList;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FriendshipListBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FriendshipList> get serializer => _$FriendshipListSerializer();
}

class _$FriendshipListSerializer implements PrimitiveSerializer<FriendshipList> {
  @override
  final Iterable<Type> types = const [FriendshipList, _$FriendshipList];

  @override
  final String wireName = r'FriendshipList';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FriendshipList object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(FriendshipResponse)]),
    );
    yield r'total';
    yield serializers.serialize(
      object.total,
      specifiedType: const FullType(int),
    );
    yield r'page';
    yield serializers.serialize(
      object.page,
      specifiedType: const FullType(int),
    );
    yield r'size';
    yield serializers.serialize(
      object.size,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FriendshipList object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FriendshipListBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(FriendshipResponse)]),
          ) as BuiltList<FriendshipResponse>;
          result.items.replace(valueDes);
          break;
        case r'total':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.total = valueDes;
          break;
        case r'page':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.page = valueDes;
          break;
        case r'size':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.size = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FriendshipList deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FriendshipListBuilder();
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

