// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/favorite_create.dart';
import '../models/favorite_list_response.dart';
import '../models/favorite_response.dart';
import '../models/message_create.dart';
import '../models/message_list_response.dart';
import '../models/message_poll_response.dart';
import '../models/message_response.dart';

part 'messages_client.g.dart';

@RestApi()
abstract class MessagesClient {
  factory MessagesClient(Dio dio, {String? baseUrl}) = _MessagesClient;

  /// Send Message.
  ///
  /// 发送消息.
  ///
  /// 支持：.
  /// - 用户间传讯（receiver_id 为用户的 bipupu_id）.
  /// - 向服务号发送消息（receiver_id 为服务号 ID）.
  ///
  /// 参数：.
  /// - receiver_id: 接收者ID.
  /// - content: 消息内容（1-5000字符）.
  /// - message_type: 消息类型（NORMAL, VOICE, SYSTEM）.
  /// - pattern: 扩展模式数据（可选）.
  /// - waveform: 音频波形数据（可选，0-255整数数组，最多128个点）.
  ///
  /// 返回：.
  /// - 成功：返回创建的消息.
  /// - 失败：400（参数错误）或404（接收者不存在）.
  @POST('/api/messages/')
  Future<MessageResponse> postApiMessages({
    @Body() required MessageCreate body,
  });

  /// Get Messages.
  ///
  /// 获取消息列表.
  ///
  /// 参数：.
  /// - direction: sent（发件箱）或 received（收件箱）.
  /// - page: 页码（从1开始）.
  /// - page_size: 每页数量（1-100）.
  ///
  /// 返回：.
  /// - 成功：返回消息列表.
  /// - 失败：400（参数错误）.
  ///
  /// [direction] - sent 或 received.
  @GET('/api/messages/')
  Future<MessageListResponse> getApiMessages({
    @Query('direction') String? direction = 'received',
    @Query('page') int? page = 1,
    @Query('page_size') int? pageSize = 20,
  });

  /// Poll Messages.
  ///
  /// 长轮询接口：.
  /// 如果数据库有比 last_msg_id 更新的消息，立即返回。.
  /// 如果没有，则异步等待直到有新消息或超时。.
  ///
  /// 参数：.
  /// - last_msg_id: 最后收到的消息ID.
  /// - timeout: 轮询超时时间（1-120秒）.
  ///
  /// 返回：.
  /// - 成功：返回新消息列表和是否有更多消息的标志.
  /// - 失败：400（参数错误）.
  ///
  /// [lastMsgId] - 最后收到的消息ID.
  ///
  /// [timeout] - 轮询超时时间（秒）.
  @GET('/api/messages/poll')
  Future<MessagePollResponse> getApiMessagesPoll({
    @Query('last_msg_id') int? lastMsgId = 0,
    @Query('timeout') int? timeout = 30,
  });

  /// Get Favorites.
  ///
  /// 获取收藏消息列表.
  ///
  /// 参数：.
  /// - page: 页码（从1开始）.
  /// - page_size: 每页数量（1-100）.
  ///
  /// 返回：.
  /// - 成功：返回收藏消息列表.
  /// - 失败：400（参数错误）.
  @GET('/api/messages/favorites')
  Future<FavoriteListResponse> getApiMessagesFavorites({
    @Query('page') int? page = 1,
    @Query('page_size') int? pageSize = 20,
  });

  /// Add Favorite.
  ///
  /// 收藏消息.
  ///
  /// 参数：.
  /// - message_id: 消息ID.
  /// - note: 备注（可选，最多200字符）.
  ///
  /// 返回：.
  /// - 成功：返回创建的收藏.
  /// - 失败：404（消息不存在）或409（已收藏）.
  @POST('/api/messages/{message_id}/favorite')
  Future<FavoriteResponse> postApiMessagesMessageIdFavorite({
    @Path('message_id') required int messageId,
    @Body() required FavoriteCreate body,
  });

  /// Remove Favorite.
  ///
  /// 取消收藏消息.
  ///
  /// 参数：.
  /// - message_id: 消息ID.
  ///
  /// 返回：.
  /// - 成功：204 No Content.
  /// - 失败：404（收藏不存在）.
  @DELETE('/api/messages/{message_id}/favorite')
  Future<void> deleteApiMessagesMessageIdFavorite({
    @Path('message_id') required int messageId,
  });

  /// Delete Message.
  ///
  /// 删除消息（仅限发送者）.
  ///
  /// 参数：.
  /// - message_id: 消息ID.
  ///
  /// 返回：.
  /// - 成功：204 No Content.
  /// - 失败：404（消息不存在）或403（无权限）.
  @DELETE('/api/messages/{message_id}')
  Future<void> deleteApiMessagesMessageId({
    @Path('message_id') required int messageId,
  });
}
