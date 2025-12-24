//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'app_schemas_friendship_friendship_status.g.dart';

class AppSchemasFriendshipFriendshipStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'pending')
  static const AppSchemasFriendshipFriendshipStatus pending = _$pending;
  @BuiltValueEnumConst(wireName: r'accepted')
  static const AppSchemasFriendshipFriendshipStatus accepted = _$accepted;
  @BuiltValueEnumConst(wireName: r'blocked')
  static const AppSchemasFriendshipFriendshipStatus blocked = _$blocked;

  static Serializer<AppSchemasFriendshipFriendshipStatus> get serializer => _$appSchemasFriendshipFriendshipStatusSerializer;

  const AppSchemasFriendshipFriendshipStatus._(String name): super(name);

  static BuiltSet<AppSchemasFriendshipFriendshipStatus> get values => _$values;
  static AppSchemasFriendshipFriendshipStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class AppSchemasFriendshipFriendshipStatusMixin = Object with _$AppSchemasFriendshipFriendshipStatusMixin;

