// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Token extends Token {
  @override
  final String accessToken;
  @override
  final String? refreshToken;
  @override
  final String? tokenType;
  @override
  final int expiresIn;
  @override
  final BuiltMap<String, JsonObject?>? user;

  factory _$Token([void Function(TokenBuilder)? updates]) =>
      (TokenBuilder()..update(updates))._build();

  _$Token._(
      {required this.accessToken,
      this.refreshToken,
      this.tokenType,
      required this.expiresIn,
      this.user})
      : super._();
  @override
  Token rebuild(void Function(TokenBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TokenBuilder toBuilder() => TokenBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Token &&
        accessToken == other.accessToken &&
        refreshToken == other.refreshToken &&
        tokenType == other.tokenType &&
        expiresIn == other.expiresIn &&
        user == other.user;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accessToken.hashCode);
    _$hash = $jc(_$hash, refreshToken.hashCode);
    _$hash = $jc(_$hash, tokenType.hashCode);
    _$hash = $jc(_$hash, expiresIn.hashCode);
    _$hash = $jc(_$hash, user.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Token')
          ..add('accessToken', accessToken)
          ..add('refreshToken', refreshToken)
          ..add('tokenType', tokenType)
          ..add('expiresIn', expiresIn)
          ..add('user', user))
        .toString();
  }
}

class TokenBuilder implements Builder<Token, TokenBuilder> {
  _$Token? _$v;

  String? _accessToken;
  String? get accessToken => _$this._accessToken;
  set accessToken(String? accessToken) => _$this._accessToken = accessToken;

  String? _refreshToken;
  String? get refreshToken => _$this._refreshToken;
  set refreshToken(String? refreshToken) => _$this._refreshToken = refreshToken;

  String? _tokenType;
  String? get tokenType => _$this._tokenType;
  set tokenType(String? tokenType) => _$this._tokenType = tokenType;

  int? _expiresIn;
  int? get expiresIn => _$this._expiresIn;
  set expiresIn(int? expiresIn) => _$this._expiresIn = expiresIn;

  MapBuilder<String, JsonObject?>? _user;
  MapBuilder<String, JsonObject?> get user =>
      _$this._user ??= MapBuilder<String, JsonObject?>();
  set user(MapBuilder<String, JsonObject?>? user) => _$this._user = user;

  TokenBuilder() {
    Token._defaults(this);
  }

  TokenBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accessToken = $v.accessToken;
      _refreshToken = $v.refreshToken;
      _tokenType = $v.tokenType;
      _expiresIn = $v.expiresIn;
      _user = $v.user?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Token other) {
    _$v = other as _$Token;
  }

  @override
  void update(void Function(TokenBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Token build() => _build();

  _$Token _build() {
    _$Token _$result;
    try {
      _$result = _$v ??
          _$Token._(
            accessToken: BuiltValueNullFieldError.checkNotNull(
                accessToken, r'Token', 'accessToken'),
            refreshToken: refreshToken,
            tokenType: tokenType,
            expiresIn: BuiltValueNullFieldError.checkNotNull(
                expiresIn, r'Token', 'expiresIn'),
            user: _user?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'user';
        _user?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'Token', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
