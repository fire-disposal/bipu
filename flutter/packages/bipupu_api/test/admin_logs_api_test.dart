import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for AdminLogsApi
void main() {
  final instance = Openapi().getAdminLogsApi();

  group(AdminLogsApi, () {
    // Delete Admin Log
    //
    // 删除管理员日志（需要超级用户权限）
    //
    //Future<JsonObject> deleteAdminLogApiAdminLogsLogIdDelete(int logId) async
    test('test deleteAdminLogApiAdminLogsLogIdDelete', () async {
      // TODO
    });

    // Get Admin Log
    //
    // 获取指定管理员日志（需要超级用户权限）
    //
    //Future<AdminLogResponse> getAdminLogApiAdminLogsLogIdGet(int logId) async
    test('test getAdminLogApiAdminLogsLogIdGet', () async {
      // TODO
    });

    // Get Admin Log Stats
    //
    // 获取管理员操作日志统计（需要超级用户权限）
    //
    //Future<JsonObject> getAdminLogStatsApiAdminLogsStatsGet() async
    test('test getAdminLogStatsApiAdminLogsStatsGet', () async {
      // TODO
    });

    // Get Admin Logs
    //
    // 获取管理员操作日志（需要超级用户权限）
    //
    //Future<BuiltList<AdminLogResponse>> getAdminLogsApiAdminLogsGet({ int skip, int limit, int adminId, String action, Date startDate, Date endDate }) async
    test('test getAdminLogsApiAdminLogsGet', () async {
      // TODO
    });

  });
}
