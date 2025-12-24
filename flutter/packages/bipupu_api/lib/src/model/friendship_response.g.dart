// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friendship_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FriendshipResponse extends FriendshipResponse {
  @override
  final int userId;
  @override
  final int friendId;
  @override
  final AppSchemasFriendshipFriendshipStatus? status;
  @override
  final int id;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;

  factory _$FriendshipResponse(
          [void Function(FriendshipResponseBuilder)? updates]) =>
      (FriendshipResponseBuilder()..update(updates))._build();

  _$FriendshipResponse._(
      {required this.userId,
      required this.friendId,
      this.status,
      required this.id,
      required this.createdAt,
      this.updatedAt})
      : super._();
  @override
  FriendshipResponse rebuild(
          void Function(FriendshipResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FriendshipResponseBuilder toBuilder() =>
      FriendshipResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FriendshipResponse &&
        userId == other.userId &&
        friendId == other.friendId &&
        status == other.status &&
        id == other.id &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, friendId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FriendshipResponse')
          ..add('userId', userId)
          ..add('friendId', friendId)
          ..add('status', status)
          ..add('id', id)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class FriendshipResponseBuilder
    implements Builder<FriendshipResponse, FriendshipResponseBuilder> {
  _$FriendshipResponse? _$v;

  int? _userId;
  int? get userId => _$this._userId;
  set userId(int? userId) => _$this._userId = userId;

  int? _friendId;
  int? get friendId => _$this._friendId;
  set friendId(int? friendId) => _$this._friendId = friendId;

  AppSchemasFriendshipFriendshipStatus? _status;
  AppSchemasFriendshipFriendshipStatus? get status => _$this._status;
  set status(AppSchemasFriendshipFriendshipStatus? status) =>
      _$this._status = status;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  FriendshipResponseBuilder() {
    FriendshipResponse._defaults(this);
  }

  FriendshipResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _userId = $v.userId;
      _friendId = $v.friendId;
      _status = $v.status;
      _id = $v.id;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FriendshipResponse other) {
    _$v = other as _$FriendshipResponse;
  }

  @override
  void update(void Function(FriendshipResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FriendshipResponse build() => _build();

  _$FriendshipResponse _build() {
    final _$result = _$v ??
        _$FriendshipResponse._(
          userId: BuiltValueNullFieldError.checkNotNull(
              userId, r'FriendshipResponse', 'userId'),
          friendId: BuiltValueNullFieldError.checkNotNull(
              friendId, r'FriendshipResponse', 'friendId'),
          status: status,
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'FriendshipResponse', 'id'),
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'FriendshipResponse', 'createdAt'),
          updatedAt: updatedAt,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
