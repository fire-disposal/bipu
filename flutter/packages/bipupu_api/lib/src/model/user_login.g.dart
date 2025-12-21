// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_login.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UserLogin extends UserLogin {
  @override
  final String username;
  @override
  final String password;

  factory _$UserLogin([void Function(UserLoginBuilder)? updates]) =>
      (UserLoginBuilder()..update(updates))._build();

  _$UserLogin._({required this.username, required this.password}) : super._();
  @override
  UserLogin rebuild(void Function(UserLoginBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserLoginBuilder toBuilder() => UserLoginBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserLogin &&
        username == other.username &&
        password == other.password;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, username.hashCode);
    _$hash = $jc(_$hash, password.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UserLogin')
          ..add('username', username)
          ..add('password', password))
        .toString();
  }
}

class UserLoginBuilder implements Builder<UserLogin, UserLoginBuilder> {
  _$UserLogin? _$v;

  String? _username;
  String? get username => _$this._username;
  set username(String? username) => _$this._username = username;

  String? _password;
  String? get password => _$this._password;
  set password(String? password) => _$this._password = password;

  UserLoginBuilder() {
    UserLogin._defaults(this);
  }

  UserLoginBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _username = $v.username;
      _password = $v.password;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserLogin other) {
    _$v = other as _$UserLogin;
  }

  @override
  void update(void Function(UserLoginBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UserLogin build() => _build();

  _$UserLogin _build() {
    final _$result = _$v ??
        _$UserLogin._(
          username: BuiltValueNullFieldError.checkNotNull(
              username, r'UserLogin', 'username'),
          password: BuiltValueNullFieldError.checkNotNull(
              password, r'UserLogin', 'password'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
