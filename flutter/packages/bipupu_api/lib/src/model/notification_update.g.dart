// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_update.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotificationUpdate extends NotificationUpdate {
  @override
  final String? title;
  @override
  final String? content;
  @override
  final int? priority;
  @override
  final AppSchemasNotificationNotificationStatus? status;

  factory _$NotificationUpdate(
          [void Function(NotificationUpdateBuilder)? updates]) =>
      (NotificationUpdateBuilder()..update(updates))._build();

  _$NotificationUpdate._({this.title, this.content, this.priority, this.status})
      : super._();
  @override
  NotificationUpdate rebuild(
          void Function(NotificationUpdateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NotificationUpdateBuilder toBuilder() =>
      NotificationUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotificationUpdate &&
        title == other.title &&
        content == other.content &&
        priority == other.priority &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, content.hashCode);
    _$hash = $jc(_$hash, priority.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotificationUpdate')
          ..add('title', title)
          ..add('content', content)
          ..add('priority', priority)
          ..add('status', status))
        .toString();
  }
}

class NotificationUpdateBuilder
    implements Builder<NotificationUpdate, NotificationUpdateBuilder> {
  _$NotificationUpdate? _$v;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _content;
  String? get content => _$this._content;
  set content(String? content) => _$this._content = content;

  int? _priority;
  int? get priority => _$this._priority;
  set priority(int? priority) => _$this._priority = priority;

  AppSchemasNotificationNotificationStatus? _status;
  AppSchemasNotificationNotificationStatus? get status => _$this._status;
  set status(AppSchemasNotificationNotificationStatus? status) =>
      _$this._status = status;

  NotificationUpdateBuilder() {
    NotificationUpdate._defaults(this);
  }

  NotificationUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _title = $v.title;
      _content = $v.content;
      _priority = $v.priority;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotificationUpdate other) {
    _$v = other as _$NotificationUpdate;
  }

  @override
  void update(void Function(NotificationUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotificationUpdate build() => _build();

  _$NotificationUpdate _build() {
    final _$result = _$v ??
        _$NotificationUpdate._(
          title: title,
          content: content,
          priority: priority,
          status: status,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
