// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_notification.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$EmailNotification extends EmailNotification {
  @override
  final String toEmail;
  @override
  final String subject;
  @override
  final String body;
  @override
  final String? htmlBody;

  factory _$EmailNotification(
          [void Function(EmailNotificationBuilder)? updates]) =>
      (EmailNotificationBuilder()..update(updates))._build();

  _$EmailNotification._(
      {required this.toEmail,
      required this.subject,
      required this.body,
      this.htmlBody})
      : super._();
  @override
  EmailNotification rebuild(void Function(EmailNotificationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EmailNotificationBuilder toBuilder() =>
      EmailNotificationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EmailNotification &&
        toEmail == other.toEmail &&
        subject == other.subject &&
        body == other.body &&
        htmlBody == other.htmlBody;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, toEmail.hashCode);
    _$hash = $jc(_$hash, subject.hashCode);
    _$hash = $jc(_$hash, body.hashCode);
    _$hash = $jc(_$hash, htmlBody.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'EmailNotification')
          ..add('toEmail', toEmail)
          ..add('subject', subject)
          ..add('body', body)
          ..add('htmlBody', htmlBody))
        .toString();
  }
}

class EmailNotificationBuilder
    implements Builder<EmailNotification, EmailNotificationBuilder> {
  _$EmailNotification? _$v;

  String? _toEmail;
  String? get toEmail => _$this._toEmail;
  set toEmail(String? toEmail) => _$this._toEmail = toEmail;

  String? _subject;
  String? get subject => _$this._subject;
  set subject(String? subject) => _$this._subject = subject;

  String? _body;
  String? get body => _$this._body;
  set body(String? body) => _$this._body = body;

  String? _htmlBody;
  String? get htmlBody => _$this._htmlBody;
  set htmlBody(String? htmlBody) => _$this._htmlBody = htmlBody;

  EmailNotificationBuilder() {
    EmailNotification._defaults(this);
  }

  EmailNotificationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _toEmail = $v.toEmail;
      _subject = $v.subject;
      _body = $v.body;
      _htmlBody = $v.htmlBody;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EmailNotification other) {
    _$v = other as _$EmailNotification;
  }

  @override
  void update(void Function(EmailNotificationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EmailNotification build() => _build();

  _$EmailNotification _build() {
    final _$result = _$v ??
        _$EmailNotification._(
          toEmail: BuiltValueNullFieldError.checkNotNull(
              toEmail, r'EmailNotification', 'toEmail'),
          subject: BuiltValueNullFieldError.checkNotNull(
              subject, r'EmailNotification', 'subject'),
          body: BuiltValueNullFieldError.checkNotNull(
              body, r'EmailNotification', 'body'),
          htmlBody: htmlBody,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
