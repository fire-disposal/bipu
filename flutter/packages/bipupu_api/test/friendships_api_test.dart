import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for FriendshipsApi
void main() {
  final instance = Openapi().getFriendshipsApi();

  group(FriendshipsApi, () {
    // Accept Friend Request
    //
    // 接受好友请求
    //
    //Future<FriendshipResponse> acceptFriendRequestApiFriendshipsFriendshipIdAcceptPut(int friendshipId) async
    test('test acceptFriendRequestApiFriendshipsFriendshipIdAcceptPut', () async {
      // TODO
    });

    // Admin Delete Friendship
    //
    // 管理端：删除好友关系（需要超级用户权限）
    //
    //Future<JsonObject> adminDeleteFriendshipApiFriendshipsAdminFriendshipIdDelete(int friendshipId) async
    test('test adminDeleteFriendshipApiFriendshipsAdminFriendshipIdDelete', () async {
      // TODO
    });

    // Admin Get All Friendships
    //
    // 管理端：获取所有好友关系（需要超级用户权限）
    //
    //Future<FriendshipList> adminGetAllFriendshipsApiFriendshipsAdminAllGet({ int skip, int limit, AppSchemasFriendshipFriendshipStatus status }) async
    test('test adminGetAllFriendshipsApiFriendshipsAdminAllGet', () async {
      // TODO
    });

    // Create Friend Request
    //
    // 发送好友请求
    //
    //Future<FriendshipResponse> createFriendRequestApiFriendshipsPost(FriendshipCreate friendshipCreate) async
    test('test createFriendRequestApiFriendshipsPost', () async {
      // TODO
    });

    // Delete Friend
    //
    // 删除好友关系
    //
    //Future<JsonObject> deleteFriendApiFriendshipsFriendshipIdDelete(int friendshipId) async
    test('test deleteFriendApiFriendshipsFriendshipIdDelete', () async {
      // TODO
    });

    // Get Friend Requests
    //
    // 获取待处理的好友请求
    //
    //Future<FriendshipList> getFriendRequestsApiFriendshipsRequestsGet({ int skip, int limit }) async
    test('test getFriendRequestsApiFriendshipsRequestsGet', () async {
      // TODO
    });

    // Get Friends
    //
    // 获取好友列表
    //
    //Future<BuiltList<UserResponse>> getFriendsApiFriendshipsFriendsGet() async
    test('test getFriendsApiFriendshipsFriendsGet', () async {
      // TODO
    });

    // Get Friendships
    //
    // 获取好友关系列表
    //
    //Future<FriendshipList> getFriendshipsApiFriendshipsGet({ int skip, int limit, AppSchemasFriendshipFriendshipStatus status }) async
    test('test getFriendshipsApiFriendshipsGet', () async {
      // TODO
    });

    // Reject Friend Request
    //
    // 拒绝好友请求
    //
    //Future<FriendshipResponse> rejectFriendRequestApiFriendshipsFriendshipIdRejectPut(int friendshipId) async
    test('test rejectFriendRequestApiFriendshipsFriendshipIdRejectPut', () async {
      // TODO
    });

  });
}
