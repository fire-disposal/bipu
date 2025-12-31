import 'package:dio/dio.dart';
import '../utils/logger.dart';

class GlobalHttpInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    Logger.info(
      "🛜 [HTTP Request] | METHOD: ${options.method} | PATH: ${options.path}",
    );
    // 如果你想看更详细的 data，可以加上：
    if (options.data != null) {
      Logger.debug("Payload: ${options.data}");
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    Logger.info(
      "✅ [HTTP Response] | STATUS: ${response.statusCode} | DATA: ${response.data}",
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Logger.error("❌ [HTTP Error] | MESSAGE: ${err.message}");
    super.onError(err, handler);
  }
}
