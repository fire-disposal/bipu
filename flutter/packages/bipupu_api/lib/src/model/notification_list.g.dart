// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_list.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotificationList extends NotificationList {
  @override
  final BuiltList<NotificationResponse> items;
  @override
  final int total;
  @override
  final int page;
  @override
  final int size;

  factory _$NotificationList(
          [void Function(NotificationListBuilder)? updates]) =>
      (NotificationListBuilder()..update(updates))._build();

  _$NotificationList._(
      {required this.items,
      required this.total,
      required this.page,
      required this.size})
      : super._();
  @override
  NotificationList rebuild(void Function(NotificationListBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NotificationListBuilder toBuilder() =>
      NotificationListBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotificationList &&
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
    return (newBuiltValueToStringHelper(r'NotificationList')
          ..add('items', items)
          ..add('total', total)
          ..add('page', page)
          ..add('size', size))
        .toString();
  }
}

class NotificationListBuilder
    implements Builder<NotificationList, NotificationListBuilder> {
  _$NotificationList? _$v;

  ListBuilder<NotificationResponse>? _items;
  ListBuilder<NotificationResponse> get items =>
      _$this._items ??= ListBuilder<NotificationResponse>();
  set items(ListBuilder<NotificationResponse>? items) => _$this._items = items;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  int? _page;
  int? get page => _$this._page;
  set page(int? page) => _$this._page = page;

  int? _size;
  int? get size => _$this._size;
  set size(int? size) => _$this._size = size;

  NotificationListBuilder() {
    NotificationList._defaults(this);
  }

  NotificationListBuilder get _$this {
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
  void replace(NotificationList other) {
    _$v = other as _$NotificationList;
  }

  @override
  void update(void Function(NotificationListBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotificationList build() => _build();

  _$NotificationList _build() {
    _$NotificationList _$result;
    try {
      _$result = _$v ??
          _$NotificationList._(
            items: items.build(),
            total: BuiltValueNullFieldError.checkNotNull(
                total, r'NotificationList', 'total'),
            page: BuiltValueNullFieldError.checkNotNull(
                page, r'NotificationList', 'page'),
            size: BuiltValueNullFieldError.checkNotNull(
                size, r'NotificationList', 'size'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'NotificationList', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
