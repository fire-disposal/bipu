// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_list.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DeviceList extends DeviceList {
  @override
  final BuiltList<DeviceResponse> items;
  @override
  final int total;
  @override
  final int page;
  @override
  final int size;

  factory _$DeviceList([void Function(DeviceListBuilder)? updates]) =>
      (DeviceListBuilder()..update(updates))._build();

  _$DeviceList._(
      {required this.items,
      required this.total,
      required this.page,
      required this.size})
      : super._();
  @override
  DeviceList rebuild(void Function(DeviceListBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeviceListBuilder toBuilder() => DeviceListBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeviceList &&
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
    return (newBuiltValueToStringHelper(r'DeviceList')
          ..add('items', items)
          ..add('total', total)
          ..add('page', page)
          ..add('size', size))
        .toString();
  }
}

class DeviceListBuilder implements Builder<DeviceList, DeviceListBuilder> {
  _$DeviceList? _$v;

  ListBuilder<DeviceResponse>? _items;
  ListBuilder<DeviceResponse> get items =>
      _$this._items ??= ListBuilder<DeviceResponse>();
  set items(ListBuilder<DeviceResponse>? items) => _$this._items = items;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  int? _page;
  int? get page => _$this._page;
  set page(int? page) => _$this._page = page;

  int? _size;
  int? get size => _$this._size;
  set size(int? size) => _$this._size = size;

  DeviceListBuilder() {
    DeviceList._defaults(this);
  }

  DeviceListBuilder get _$this {
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
  void replace(DeviceList other) {
    _$v = other as _$DeviceList;
  }

  @override
  void update(void Function(DeviceListBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DeviceList build() => _build();

  _$DeviceList _build() {
    _$DeviceList _$result;
    try {
      _$result = _$v ??
          _$DeviceList._(
            items: items.build(),
            total: BuiltValueNullFieldError.checkNotNull(
                total, r'DeviceList', 'total'),
            page: BuiltValueNullFieldError.checkNotNull(
                page, r'DeviceList', 'page'),
            size: BuiltValueNullFieldError.checkNotNull(
                size, r'DeviceList', 'size'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'DeviceList', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
