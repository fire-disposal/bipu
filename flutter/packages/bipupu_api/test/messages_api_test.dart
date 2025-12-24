import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for MessagesApi
void main() {
  final instance = Openapi().getMessagesApi();

  group(MessagesApi, () {
    // Admin Delete Message
    //
    // 管理端：删除消息（需要超级用户权限）
    //
    //Future<JsonObject> adminDeleteMessageApiMessagesAdminMessageIdDelete(int messageId) async
    test('test adminDeleteMessageApiMessagesAdminMessageIdDelete', () async {
      // TODO
    });

    // Admin Get All Messages
    //
    // 管理端：获取所有消息（需要超级用户权限）
    //
    //Future<MessageList> adminGetAllMessagesApiMessagesAdminAllGet({ int skip, int limit, AppModelsMessageMessageType messageType, AppSchemasMessageMessageStatus status, int senderId, int receiverId }) async
    test('test adminGetAllMessagesApiMessagesAdminAllGet', () async {
      // TODO
    });

    // Admin Get Message Stats
    //
    // 管理端：获取系统消息统计（需要超级用户权限）
    //
    //Future<JsonObject> adminGetMessageStatsApiMessagesAdminStatsGet() async
    test('test adminGetMessageStatsApiMessagesAdminStatsGet', () async {
      // TODO
    });

    // Create Message
    //
    // 创建消息 - IM核心功能
    //
    //Future<MessageResponse> createMessageApiMessagesPost(MessageCreate messageCreate) async
    test('test createMessageApiMessagesPost', () async {
      // TODO
    });

    // Delete Message
    //
    // 删除消息
    //
    //Future<JsonObject> deleteMessageApiMessagesMessageIdDelete(int messageId) async
    test('test deleteMessageApiMessagesMessageIdDelete', () async {
      // TODO
    });

    // Delete Read Messages
    //
    // 删除所有已读消息
    //
    //Future<JsonObject> deleteReadMessagesApiMessagesDelete() async
    test('test deleteReadMessagesApiMessagesDelete', () async {
      // TODO
    });

    // Get Conversation Messages
    //
    // 获取与指定用户的会话消息 - IM核心功能
    //
    //Future<MessageList> getConversationMessagesApiMessagesConversationsUserIdGet(int userId, { int skip, int limit }) async
    test('test getConversationMessagesApiMessagesConversationsUserIdGet', () async {
      // TODO
    });

    // Get Message
    //
    // 获取指定消息
    //
    //Future<MessageResponse> getMessageApiMessagesMessageIdGet(int messageId) async
    test('test getMessageApiMessagesMessageIdGet', () async {
      // TODO
    });

    // Get Message Stats
    //
    // 获取消息统计信息
    //
    //Future<MessageStats> getMessageStatsApiMessagesStatsGet() async
    test('test getMessageStatsApiMessagesStatsGet', () async {
      // TODO
    });

    // Get Messages
    //
    // 获取消息列表 - 支持IM会话查询
    //
    //Future<MessageList> getMessagesApiMessagesGet({ int skip, int limit, AppModelsMessageMessageType messageType, AppSchemasMessageMessageStatus status, bool isRead, int senderId, int receiverId, DateTime startDate, DateTime endDate }) async
    test('test getMessagesApiMessagesGet', () async {
      // TODO
    });

    // Get Recent Messages
    //
    // 获取最近消息 - IM实时同步
    //
    //Future<MessageList> getRecentMessagesApiMessagesRecentGet({ int hours, int skip, int limit }) async
    test('test getRecentMessagesApiMessagesRecentGet', () async {
      // TODO
    });

    // Get Unread Messages
    //
    // 获取未读消息 - IM轮询接口
    //
    //Future<MessageList> getUnreadMessagesApiMessagesUnreadGet({ int skip, int limit }) async
    test('test getUnreadMessagesApiMessagesUnreadGet', () async {
      // TODO
    });

    // Mark All Messages As Read
    //
    // 标记所有消息为已读
    //
    //Future<JsonObject> markAllMessagesAsReadApiMessagesReadAllPut() async
    test('test markAllMessagesAsReadApiMessagesReadAllPut', () async {
      // TODO
    });

    // Mark Message As Read
    //
    // 标记消息为已读
    //
    //Future<JsonObject> markMessageAsReadApiMessagesMessageIdReadPut(int messageId) async
    test('test markMessageAsReadApiMessagesMessageIdReadPut', () async {
      // TODO
    });

    // Update Message
    //
    // 更新消息
    //
    //Future<MessageResponse> updateMessageApiMessagesMessageIdPut(int messageId, MessageUpdate messageUpdate) async
    test('test updateMessageApiMessagesMessageIdPut', () async {
      // TODO
    });

  });
}
