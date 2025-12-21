import 'package:openapi/openapi.dart';
import 'package:dio/dio.dart';

class CoreApi {
  static late final Openapi client;

  static void init() {
    // 这里的 Openapi 类就是你在 packages/.../lib/openapi.dart 里定义的那个类
    client = Openapi(dio: Dio(BaseOptions(baseUrl: 'http://localhost:8000')));
  }
}
