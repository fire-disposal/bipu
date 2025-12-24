import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for HealthApi
void main() {
  final instance = Openapi().getHealthApi();

  group(HealthApi, () {
    // Health Check
    //
    // 健康检查端点
    //
    //Future<JsonObject> healthCheckApiHealthGet() async
    test('test healthCheckApiHealthGet', () async {
      // TODO
    });

    // Liveness Check
    //
    // 存活检查端点
    //
    //Future<JsonObject> livenessCheckApiHealthLiveGet() async
    test('test livenessCheckApiHealthLiveGet', () async {
      // TODO
    });

    // Readiness Check
    //
    // 就绪检查端点
    //
    //Future<JsonObject> readinessCheckApiHealthReadyGet() async
    test('test readinessCheckApiHealthReadyGet', () async {
      // TODO
    });

  });
}
