// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UserProfile extends UserProfile {
  @override
  final int id;
  @override
  final String username;
  @override
  final String email;
  @override
  final String? nickname;
  @override
  final String? fullName;
  @override
  final bool isActive;
  @override
  final bool isSuperuser;
  @override
  final String role;
  @override
  final DateTime? lastActive;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;

  factory _$UserProfile([void Function(UserProfileBuilder)? updates]) =>
      (UserProfileBuilder()..update(updates))._build();

  _$UserProfile._(
      {required this.id,
      required this.username,
      required this.email,
      this.nickname,
      this.fullName,
      required this.isActive,
      required this.isSuperuser,
      required this.role,
      this.lastActive,
      required this.createdAt,
      this.updatedAt})
      : super._();
  @override
  UserProfile rebuild(void Function(UserProfileBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserProfileBuilder toBuilder() => UserProfileBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserProfile &&
        id == other.id &&
        username == other.username &&
        email == other.email &&
        nickname == other.nickname &&
        fullName == other.fullName &&
        isActive == other.isActive &&
        isSuperuser == other.isSuperuser &&
        role == other.role &&
        lastActive == other.lastActive &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, username.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, nickname.hashCode);
    _$hash = $jc(_$hash, fullName.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, isSuperuser.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, lastActive.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UserProfile')
          ..add('id', id)
          ..add('username', username)
          ..add('email', email)
          ..add('nickname', nickname)
          ..add('fullName', fullName)
          ..add('isActive', isActive)
          ..add('isSuperuser', isSuperuser)
          ..add('role', role)
          ..add('lastActive', lastActive)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class UserProfileBuilder implements Builder<UserProfile, UserProfileBuilder> {
  _$UserProfile? _$v;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _username;
  String? get username => _$this._username;
  set username(String? username) => _$this._username = username;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _nickname;
  String? get nickname => _$this._nickname;
  set nickname(String? nickname) => _$this._nickname = nickname;

  String? _fullName;
  String? get fullName => _$this._fullName;
  set fullName(String? fullName) => _$this._fullName = fullName;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  bool? _isSuperuser;
  bool? get isSuperuser => _$this._isSuperuser;
  set isSuperuser(bool? isSuperuser) => _$this._isSuperuser = isSuperuser;

  String? _role;
  String? get role => _$this._role;
  set role(String? role) => _$this._role = role;

  DateTime? _lastActive;
  DateTime? get lastActive => _$this._lastActive;
  set lastActive(DateTime? lastActive) => _$this._lastActive = lastActive;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  UserProfileBuilder() {
    UserProfile._defaults(this);
  }

  UserProfileBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _username = $v.username;
      _email = $v.email;
      _nickname = $v.nickname;
      _fullName = $v.fullName;
      _isActive = $v.isActive;
      _isSuperuser = $v.isSuperuser;
      _role = $v.role;
      _lastActive = $v.lastActive;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserProfile other) {
    _$v = other as _$UserProfile;
  }

  @override
  void update(void Function(UserProfileBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UserProfile build() => _build();

  _$UserProfile _build() {
    final _$result = _$v ??
        _$UserProfile._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'UserProfile', 'id'),
          username: BuiltValueNullFieldError.checkNotNull(
              username, r'UserProfile', 'username'),
          email: BuiltValueNullFieldError.checkNotNull(
              email, r'UserProfile', 'email'),
          nickname: nickname,
          fullName: fullName,
          isActive: BuiltValueNullFieldError.checkNotNull(
              isActive, r'UserProfile', 'isActive'),
          isSuperuser: BuiltValueNullFieldError.checkNotNull(
              isSuperuser, r'UserProfile', 'isSuperuser'),
          role: BuiltValueNullFieldError.checkNotNull(
              role, r'UserProfile', 'role'),
          lastActive: lastActive,
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'UserProfile', 'createdAt'),
          updatedAt: updatedAt,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
