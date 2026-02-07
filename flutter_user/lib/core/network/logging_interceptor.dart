import 'package:dio/dio.dart';
import '../utils/logger.dart';

class GlobalHttpInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.i("üõú [REQ] ${options.method} ${options.uri}");
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.i(
      "‚ú?[RES] ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}",
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    logger.e(
      "‚ù?[ERR] ${status ?? '-'} ${err.requestOptions.method} ${err.requestOptions.uri} ${err.message}",
    );
    handler.next(err);
  }
}
