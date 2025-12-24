import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for MessageAckApi
void main() {
  final instance = Openapi().getMessageAckApi();

  group(MessageAckApi, () {
    // Admin Get Ack Stats
    //
    // 管理端：获取消息回执统计（需要超级用户权限）
    //
    //Future<JsonObject> adminGetAckStatsApiMessageAckAdminStatsGet() async
    test('test adminGetAckStatsApiMessageAckAdminStatsGet', () async {
      // TODO
    });

    // Admin Get All Ack Events
    //
    // 管理端：获取所有消息回执事件（需要超级用户权限）
    //
    //Future<BuiltList<MessageAckEventResponse>> adminGetAllAckEventsApiMessageAckAdminAllGet({ int skip, int limit }) async
    test('test adminGetAllAckEventsApiMessageAckAdminAllGet', () async {
      // TODO
    });

    // Create Message Ack Event
    //
    // 创建消息回执事件
    //
    //Future<MessageAckEventResponse> createMessageAckEventApiMessageAckPost(MessageAckEventCreate messageAckEventCreate) async
    test('test createMessageAckEventApiMessageAckPost', () async {
      // TODO
    });

    // Get Message Ack Events
    //
    // 获取指定消息的所有回执事件
    //
    //Future<BuiltList<MessageAckEventResponse>> getMessageAckEventsApiMessageAckMessageMessageIdGet(int messageId) async
    test('test getMessageAckEventsApiMessageAckMessageMessageIdGet', () async {
      // TODO
    });

  });
}
