// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friendship_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FriendshipCreate extends FriendshipCreate {
  @override
  final int userId;
  @override
  final int friendId;
  @override
  final AppSchemasFriendshipFriendshipStatus? status;

  factory _$FriendshipCreate(
          [void Function(FriendshipCreateBuilder)? updates]) =>
      (FriendshipCreateBuilder()..update(updates))._build();

  _$FriendshipCreate._(
      {required this.userId, required this.friendId, this.status})
      : super._();
  @override
  FriendshipCreate rebuild(void Function(FriendshipCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FriendshipCreateBuilder toBuilder() =>
      FriendshipCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FriendshipCreate &&
        userId == other.userId &&
        friendId == other.friendId &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, friendId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FriendshipCreate')
          ..add('userId', userId)
          ..add('friendId', friendId)
          ..add('status', status))
        .toString();
  }
}

class FriendshipCreateBuilder
    implements Builder<FriendshipCreate, FriendshipCreateBuilder> {
  _$FriendshipCreate? _$v;

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

  FriendshipCreateBuilder() {
    FriendshipCreate._defaults(this);
  }

  FriendshipCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _userId = $v.userId;
      _friendId = $v.friendId;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FriendshipCreate other) {
    _$v = other as _$FriendshipCreate;
  }

  @override
  void update(void Function(FriendshipCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FriendshipCreate build() => _build();

  _$FriendshipCreate _build() {
    final _$result = _$v ??
        _$FriendshipCreate._(
          userId: BuiltValueNullFieldError.checkNotNull(
              userId, r'FriendshipCreate', 'userId'),
          friendId: BuiltValueNullFieldError.checkNotNull(
              friendId, r'FriendshipCreate', 'friendId'),
          status: status,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
