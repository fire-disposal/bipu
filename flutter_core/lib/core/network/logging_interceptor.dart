import 'package:dio/dio.dart';
import '../utils/logger.dart';

class GlobalHttpInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.i(
      "🛜 [HTTP Request] | METHOD: ${options.method} | PATH: ${options.path}",
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.i(
      "✅ [HTTP Response] | STATUS: ${response.statusCode} | PATH: ${response.requestOptions.path}",
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.e(
      "❌ [HTTP Error] | STATUS: ${err.response?.statusCode} | PATH: ${err.requestOptions.path} | MSG: ${err.message}",
    );
    handler.next(err);
  }
}
