import 'package:test/test.dart';
import 'package:openapi/openapi.dart';

/// tests for SystemApi
void main() {
  final instance = Openapi().getSystemApi();

  group(SystemApi, () {
    // Health Check
    //
    //Future<JsonObject> healthCheckHealthGet() async
    test('test healthCheckHealthGet', () async {
      // TODO
    });
  });
}
