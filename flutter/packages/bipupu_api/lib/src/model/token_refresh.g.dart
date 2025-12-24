// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_refresh.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TokenRefresh extends TokenRefresh {
  @override
  final String refreshToken;

  factory _$TokenRefresh([void Function(TokenRefreshBuilder)? updates]) =>
      (TokenRefreshBuilder()..update(updates))._build();

  _$TokenRefresh._({required this.refreshToken}) : super._();
  @override
  TokenRefresh rebuild(void Function(TokenRefreshBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TokenRefreshBuilder toBuilder() => TokenRefreshBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TokenRefresh && refreshToken == other.refreshToken;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, refreshToken.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TokenRefresh')
          ..add('refreshToken', refreshToken))
        .toString();
  }
}

class TokenRefreshBuilder
    implements Builder<TokenRefresh, TokenRefreshBuilder> {
  _$TokenRefresh? _$v;

  String? _refreshToken;
  String? get refreshToken => _$this._refreshToken;
  set refreshToken(String? refreshToken) => _$this._refreshToken = refreshToken;

  TokenRefreshBuilder() {
    TokenRefresh._defaults(this);
  }

  TokenRefreshBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _refreshToken = $v.refreshToken;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TokenRefresh other) {
    _$v = other as _$TokenRefresh;
  }

  @override
  void update(void Function(TokenRefreshBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TokenRefresh build() => _build();

  _$TokenRefresh _build() {
    final _$result = _$v ??
        _$TokenRefresh._(
          refreshToken: BuiltValueNullFieldError.checkNotNull(
              refreshToken, r'TokenRefresh', 'refreshToken'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
