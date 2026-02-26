// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'fallback/fallback_client.dart';
import 'system/system_client.dart';
import 'authentication/authentication_client.dart';
import 'messages/messages_client.dart';
import 'blacklist/blacklist_client.dart';
import 'user_profile/user_profile_client.dart';
import 'users/users_client.dart';
import 'contacts/contacts_client.dart';
import 'service_accounts/service_accounts_client.dart';
import 'posters/posters_client.dart';
import 'admin/admin_client.dart';

/// bipupu `v0.2.0`.
///
/// BIPUPU API 服务.
class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '0.2.0';

  FallbackClient? _fallback;
  SystemClient? _system;
  AuthenticationClient? _authentication;
  MessagesClient? _messages;
  BlacklistClient? _blacklist;
  UserProfileClient? _userProfile;
  UsersClient? _users;
  ContactsClient? _contacts;
  ServiceAccountsClient? _serviceAccounts;
  PostersClient? _posters;
  AdminClient? _admin;

  FallbackClient get fallback => _fallback ??= FallbackClient(_dio, baseUrl: _baseUrl);

  SystemClient get system => _system ??= SystemClient(_dio, baseUrl: _baseUrl);

  AuthenticationClient get authentication => _authentication ??= AuthenticationClient(_dio, baseUrl: _baseUrl);

  MessagesClient get messages => _messages ??= MessagesClient(_dio, baseUrl: _baseUrl);

  BlacklistClient get blacklist => _blacklist ??= BlacklistClient(_dio, baseUrl: _baseUrl);

  UserProfileClient get userProfile => _userProfile ??= UserProfileClient(_dio, baseUrl: _baseUrl);

  UsersClient get users => _users ??= UsersClient(_dio, baseUrl: _baseUrl);

  ContactsClient get contacts => _contacts ??= ContactsClient(_dio, baseUrl: _baseUrl);

  ServiceAccountsClient get serviceAccounts => _serviceAccounts ??= ServiceAccountsClient(_dio, baseUrl: _baseUrl);

  PostersClient get posters => _posters ??= PostersClient(_dio, baseUrl: _baseUrl);

  AdminClient get admin => _admin ??= AdminClient(_dio, baseUrl: _baseUrl);
}
