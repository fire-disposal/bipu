// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/contact_create.dart';
import '../models/contact_list_response.dart';
import '../models/contact_response.dart';
import '../models/contact_update.dart';
import '../models/success_response.dart';

part 'contacts_client.g.dart';

@RestApi()
abstract class ContactsClient {
  factory ContactsClient(Dio dio, {String? baseUrl}) = _ContactsClient;

  /// Get Contacts.
  ///
  /// 获取联系人列表.
  ///
  /// 参数：.
  /// - page: 页码（从1开始）.
  /// - page_size: 每页数量（1-100）.
  ///
  /// 返回：.
  /// - 成功：返回联系人列表.
  /// - 失败：400（参数错误）.
  ///
  /// [page] - 页码.
  ///
  /// [pageSize] - 每页数量.
  @GET('/api/contacts/')
  Future<ContactListResponse> getApiContacts({
    @Query('page') int? page = 1,
    @Query('page_size') int? pageSize = 20,
  });

  /// Create Contact.
  ///
  /// 添加联系人.
  ///
  /// 参数：.
  /// - contact_id: 联系人用户ID.
  /// - alias: 备注名（可选，最多50字符）.
  ///
  /// 返回：.
  /// - 成功：返回创建的联系人.
  /// - 失败：400（参数错误）或404（用户不存在）或409（已是联系人）.
  @POST('/api/contacts/')
  Future<ContactResponse> postApiContacts({
    @Body() required ContactCreate body,
  });

  /// Update Contact.
  ///
  /// 更新联系人备注.
  ///
  /// 参数：.
  /// - contact_id: 联系人用户ID.
  /// - alias: 新的备注名（可选，最多50字符）.
  ///
  /// 返回：.
  /// - 成功：返回更新成功消息.
  /// - 失败：404（联系人不存在）.
  @PUT('/api/contacts/{contact_id}')
  Future<SuccessResponse> putApiContactsContactId({
    @Path('contact_id') required String contactId,
    @Body() required ContactUpdate body,
  });

  /// Delete Contact.
  ///
  /// 删除联系人.
  ///
  /// 参数：.
  /// - contact_id: 联系人用户ID.
  ///
  /// 返回：.
  /// - 成功：204 No Content.
  /// - 失败：404（联系人不存在）.
  @DELETE('/api/contacts/{contact_id}')
  Future<void> deleteApiContactsContactId({
    @Path('contact_id') required String contactId,
  });
}
