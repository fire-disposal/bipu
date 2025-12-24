// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friendship_list.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FriendshipList extends FriendshipList {
  @override
  final BuiltList<FriendshipResponse> items;
  @override
  final int total;
  @override
  final int page;
  @override
  final int size;

  factory _$FriendshipList([void Function(FriendshipListBuilder)? updates]) =>
      (FriendshipListBuilder()..update(updates))._build();

  _$FriendshipList._(
      {required this.items,
      required this.total,
      required this.page,
      required this.size})
      : super._();
  @override
  FriendshipList rebuild(void Function(FriendshipListBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FriendshipListBuilder toBuilder() => FriendshipListBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FriendshipList &&
        items == other.items &&
        total == other.total &&
        page == other.page &&
        size == other.size;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jc(_$hash, page.hashCode);
    _$hash = $jc(_$hash, size.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FriendshipList')
          ..add('items', items)
          ..add('total', total)
          ..add('page', page)
          ..add('size', size))
        .toString();
  }
}

class FriendshipListBuilder
    implements Builder<FriendshipList, FriendshipListBuilder> {
  _$FriendshipList? _$v;

  ListBuilder<FriendshipResponse>? _items;
  ListBuilder<FriendshipResponse> get items =>
      _$this._items ??= ListBuilder<FriendshipResponse>();
  set items(ListBuilder<FriendshipResponse>? items) => _$this._items = items;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  int? _page;
  int? get page => _$this._page;
  set page(int? page) => _$this._page = page;

  int? _size;
  int? get size => _$this._size;
  set size(int? size) => _$this._size = size;

  FriendshipListBuilder() {
    FriendshipList._defaults(this);
  }

  FriendshipListBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _total = $v.total;
      _page = $v.page;
      _size = $v.size;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FriendshipList other) {
    _$v = other as _$FriendshipList;
  }

  @override
  void update(void Function(FriendshipListBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FriendshipList build() => _build();

  _$FriendshipList _build() {
    _$FriendshipList _$result;
    try {
      _$result = _$v ??
          _$FriendshipList._(
            items: items.build(),
            total: BuiltValueNullFieldError.checkNotNull(
                total, r'FriendshipList', 'total'),
            page: BuiltValueNullFieldError.checkNotNull(
                page, r'FriendshipList', 'page'),
            size: BuiltValueNullFieldError.checkNotNull(
                size, r'FriendshipList', 'size'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'FriendshipList', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
