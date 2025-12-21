import 'package:test/test.dart';
import 'package:openapi/openapi.dart';

/// tests for MessagesApi
void main() {
  final instance = Openapi().getMessagesApi();

  group(MessagesApi, () {
    // Create Message
    //
    // 创建消息
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
    // 获取消息列表
    //
    //Future<MessageList> getMessagesApiMessagesGet({ int skip, int limit, AppSchemasMessageMessageType messageType, AppSchemasMessageMessageStatus status, bool isRead }) async
    test('test getMessagesApiMessagesGet', () async {
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
