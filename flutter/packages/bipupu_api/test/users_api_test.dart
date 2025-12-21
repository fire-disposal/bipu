import 'package:test/test.dart';
import 'package:openapi/openapi.dart';

/// tests for UsersApi
void main() {
  final instance = Openapi().getUsersApi();

  group(UsersApi, () {
    // Delete User
    //
    // 删除用户（需要超级用户权限）
    //
    //Future<JsonObject> deleteUserApiUsersUserIdDelete(int userId) async
    test('test deleteUserApiUsersUserIdDelete', () async {
      // TODO
    });

    // Get Current User Info
    //
    // 获取当前用户信息
    //
    //Future<UserResponse> getCurrentUserInfoApiUsersMeGet() async
    test('test getCurrentUserInfoApiUsersMeGet', () async {
      // TODO
    });

    // Get User
    //
    // 获取指定用户（需要超级用户权限）
    //
    //Future<UserResponse> getUserApiUsersUserIdGet(int userId) async
    test('test getUserApiUsersUserIdGet', () async {
      // TODO
    });

    // Get Users
    //
    // 获取用户列表（需要超级用户权限）
    //
    //Future<BuiltList<UserResponse>> getUsersApiUsersGet({ int skip, int limit }) async
    test('test getUsersApiUsersGet', () async {
      // TODO
    });

    // Login
    //
    // 用户登录
    //
    //Future<Token> loginApiUsersLoginPost(UserLogin userLogin) async
    test('test loginApiUsersLoginPost', () async {
      // TODO
    });

    // Register User
    //
    // 用户注册
    //
    //Future<UserResponse> registerUserApiUsersRegisterPost(UserCreate userCreate) async
    test('test registerUserApiUsersRegisterPost', () async {
      // TODO
    });

    // Update Current User
    //
    // 更新当前用户信息
    //
    //Future<UserResponse> updateCurrentUserApiUsersMePut(UserUpdate userUpdate) async
    test('test updateCurrentUserApiUsersMePut', () async {
      // TODO
    });

    // Update User
    //
    // 更新用户信息（需要超级用户权限）
    //
    //Future<UserResponse> updateUserApiUsersUserIdPut(int userId, UserUpdate userUpdate) async
    test('test updateUserApiUsersUserIdPut', () async {
      // TODO
    });
  });
}
