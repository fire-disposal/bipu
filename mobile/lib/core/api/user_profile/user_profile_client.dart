// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/success_response.dart';
import '../models/timezone_update.dart';
import '../models/user_password_update.dart';
import '../models/user_private.dart';
import '../models/user_update.dart';

part 'user_profile_client.g.dart';

@RestApi()
abstract class UserProfileClient {
  factory UserProfileClient(Dio dio, {String? baseUrl}) = _UserProfileClient;

  /// Upload Avatar.
  ///
  /// 上传并更新用户头像.
  @MultiPart()
  @POST('/api/profile/avatar')
  Future<UserPrivate> postApiProfileAvatar({
    @Part(name: 'file') required File file,
  });

  /// Get Current User Info.
  ///
  /// 获取当前用户信息.
  @GET('/api/profile/me')
  Future<UserPrivate> getApiProfileMe();

  /// Get Profile.
  ///
  /// 获取个人资料（兼容性接口）.
  @GET('/api/profile/')
  Future<UserPrivate> getApiProfile();

  /// Update Profile.
  ///
  /// 更新个人资料.
  @PUT('/api/profile/')
  Future<UserPrivate> putApiProfile({
    @Body() required UserUpdate body,
  });

  /// Update Password.
  ///
  /// 更新密码.
  @PUT('/api/profile/password')
  Future<SuccessResponse> putApiProfilePassword({
    @Body() required UserPasswordUpdate body,
  });

  /// Update Timezone.
  ///
  /// 更新时区.
  @PUT('/api/profile/timezone')
  Future<SuccessResponse> putApiProfileTimezone({
    @Body() required TimezoneUpdate body,
  });

  /// Get Push Settings.
  ///
  /// 获取推送设置（兼容性接口）.
  @GET('/api/profile/push-settings')
  Future<dynamic> getApiProfilePushSettings();

  /// Get User Avatar.
  ///
  /// 获取用户头像（公开接口）.
  @GET('/api/profile/avatar/{bipupu_id}')
  Future<void> getApiProfileAvatarBipupuId({
    @Path('bipupu_id') required String bipupuId,
  });
}
