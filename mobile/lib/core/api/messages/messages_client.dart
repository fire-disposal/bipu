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

  /// Get Received Messages.
  ///
  /// 获取用户的收件箱（接收的消息）.
  ///
  /// 参数：.
  /// - page: 页码（从1开始）.
  /// - page_size: 每页数量（1-100，默认20）.
  /// - since_id: 增量同步参数，只返回 id > since_id 的消息（默认0表示全量）.
  ///
  /// 返回：.
  /// - messages: 消息列表.
  /// - total: 总数.
  /// - page: 当前页码.
  /// - page_size: 每页数量.
  ///
  /// [page] - 页码.
  ///
  /// [pageSize] - 每页数量.
  ///
  /// [sinceId] - 增量同步ID.
  @GET('/api/messages/inbox')
  Future<MessageListResponse> getApiMessagesInbox({
    @Query('page') int? page = 1,
    @Query('page_size') int? pageSize = 20,
    @Query('since_id') int? sinceId = 0,
  });

  /// Get Sent Messages.
  ///
  /// 获取用户的发件箱（发送的消息）.
  ///
  /// 参数：.
  /// - page: 页码（从1开始）.
  /// - page_size: 每页数量（1-100，默认20）.
  /// - since_id: 增量同步参数，只返回 id > since_id 的消息（默认0表示全量）.
  ///
  /// 返回：.
  /// - messages: 消息列表.
  /// - total: 总数.
  /// - page: 当前页码.
  /// - page_size: 每页数量.
  ///
  /// 注：后端已经按 sender_bipupu_id 过滤，前端无需再次过滤.
  ///
  /// [page] - 页码.
  ///
  /// [pageSize] - 每页数量.
  ///
  /// [sinceId] - 增量同步ID.
  @GET('/api/messages/sent')
  Future<MessageListResponse> getApiMessagesSent({
    @Query('page') int? page = 1,
    @Query('page_size') int? pageSize = 20,
    @Query('since_id') int? sinceId = 0,
  });

  /// Long Poll Messages.
  ///
  /// 长轮询接口：获取新消息.
  ///
  /// 工作流程：.
  /// 1. 如果有比 last_msg_id 更新的消息，立即返回.
  /// 2. 否则每秒检查一次，直到超时.
  /// 3. 实现实时消息推送，同时避免频繁轮询.
  ///
  /// 参数：.
  /// - last_msg_id: 最后收到的消息ID（从0开始表示获取所有新消息）.
  /// - timeout: 轮询超时时间（1-120秒，默认30秒）.
  ///
  /// 返回：.
  /// - messages: 新消息列表.
  /// - has_more: 是否有更多消息（返回数量≥20时为true）.
  ///
  /// 优点：.
  /// - 实时性：有新消息立即返回，不需要等待超时.
  /// - 流量少：只返回新消息，不重复传输.
  /// - 负载低：无新消息时连接挂起，不进行数据库查询.
  ///
  /// [lastMsgId] - 最后收到的消息ID.
  ///
  /// [timeout] - 轮询超时时间（秒）.
  @GET('/api/messages/poll')
  Future<MessagePollResponse> getApiMessagesPoll({
    @Query('last_msg_id') int? lastMsgId = 0,
    @Query('timeout') int? timeout = 30,
  });

  /// Mark Single Message Read.
  ///
  /// 标记单条消息为已读.
  ///
  /// 参数：.
  /// - message_id: 消息ID.
  ///
  /// 返回：.
  /// - status: 操作状态.
  /// - message_id: 消息ID.
  @POST('/api/messages/{message_id}/read')
  Future<void> postApiMessagesMessageIdRead({
    @Path('message_id') required int messageId,
  });

  /// Mark Messages Read Batch.
  ///
  /// 批量标记消息为已读.
  ///
  /// 参数：.
  /// - message_ids: 消息ID列表.
  ///
  /// 返回：.
  /// - status: 操作状态.
  /// - count: 处理的消息数量.
  @POST('/api/messages/read-batch')
  Future<void> postApiMessagesReadBatch({
    @Body() required List<int> body,
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
  /// - favorites: 收藏消息列表.
  /// - total: 总数.
  /// - page: 当前页码.
  /// - page_size: 每页数量.
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
