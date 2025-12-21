// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_list.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MessageList extends MessageList {
  @override
  final BuiltList<MessageResponse> items;
  @override
  final int total;
  @override
  final int page;
  @override
  final int size;
  @override
  final int unreadCount;

  factory _$MessageList([void Function(MessageListBuilder)? updates]) =>
      (MessageListBuilder()..update(updates))._build();

  _$MessageList._(
      {required this.items,
      required this.total,
      required this.page,
      required this.size,
      required this.unreadCount})
      : super._();
  @override
  MessageList rebuild(void Function(MessageListBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MessageListBuilder toBuilder() => MessageListBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MessageList &&
        items == other.items &&
        total == other.total &&
        page == other.page &&
        size == other.size &&
        unreadCount == other.unreadCount;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jc(_$hash, page.hashCode);
    _$hash = $jc(_$hash, size.hashCode);
    _$hash = $jc(_$hash, unreadCount.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MessageList')
          ..add('items', items)
          ..add('total', total)
          ..add('page', page)
          ..add('size', size)
          ..add('unreadCount', unreadCount))
        .toString();
  }
}

class MessageListBuilder implements Builder<MessageList, MessageListBuilder> {
  _$MessageList? _$v;

  ListBuilder<MessageResponse>? _items;
  ListBuilder<MessageResponse> get items =>
      _$this._items ??= ListBuilder<MessageResponse>();
  set items(ListBuilder<MessageResponse>? items) => _$this._items = items;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  int? _page;
  int? get page => _$this._page;
  set page(int? page) => _$this._page = page;

  int? _size;
  int? get size => _$this._size;
  set size(int? size) => _$this._size = size;

  int? _unreadCount;
  int? get unreadCount => _$this._unreadCount;
  set unreadCount(int? unreadCount) => _$this._unreadCount = unreadCount;

  MessageListBuilder() {
    MessageList._defaults(this);
  }

  MessageListBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _total = $v.total;
      _page = $v.page;
      _size = $v.size;
      _unreadCount = $v.unreadCount;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MessageList other) {
    _$v = other as _$MessageList;
  }

  @override
  void update(void Function(MessageListBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MessageList build() => _build();

  _$MessageList _build() {
    _$MessageList _$result;
    try {
      _$result = _$v ??
          _$MessageList._(
            items: items.build(),
            total: BuiltValueNullFieldError.checkNotNull(
                total, r'MessageList', 'total'),
            page: BuiltValueNullFieldError.checkNotNull(
                page, r'MessageList', 'page'),
            size: BuiltValueNullFieldError.checkNotNull(
                size, r'MessageList', 'size'),
            unreadCount: BuiltValueNullFieldError.checkNotNull(
                unreadCount, r'MessageList', 'unreadCount'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'MessageList', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
