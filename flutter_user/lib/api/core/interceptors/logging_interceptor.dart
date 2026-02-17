import 'package:dio/dio.dart';
import '../../../core/utils/logger.dart';

/// 日志拦截器
class LoggingInterceptor extends Interceptor {
  final bool request;
  final bool requestHeader;
  final bool requestBody;
  final bool responseHeader;
  final bool responseBody;
  final bool error;
  final bool compact;

  const LoggingInterceptor({
    this.request = true,
    this.requestHeader = false,
    this.requestBody = false,
    this.responseHeader = false,
    this.responseBody = true,
    this.error = true,
    this.compact = true,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (request) {
      _logRequest(options);
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (responseBody) {
      _logResponse(response);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (error) {
      _logError(err);
    }
    handler.next(err);
  }

  void _logRequest(RequestOptions options) {
    final method = options.method.toUpperCase();
    final uri = options.uri;

    logger.i('🚀 $method $uri');

    if (requestHeader && options.headers.isNotEmpty) {
      logger.i('Headers:');
      options.headers.forEach((key, value) {
        logger.i('  $key: $value');
      });
    }

    if (requestBody && options.data != null) {
      logger.i('Data:');
      logger.i(_formatData(options.data));
    }
  }

  void _logResponse(Response response) {
    final statusCode = response.statusCode;
    final method = response.requestOptions.method.toUpperCase();
    final uri = response.requestOptions.uri;

    final emoji = _getStatusEmoji(statusCode);
    logger.i('$emoji $method $uri - Status: $statusCode');

    if (responseHeader && response.headers.map.isNotEmpty) {
      logger.i('Headers:');
      response.headers.map.forEach((key, value) {
        logger.i('  $key: $value');
      });
    }

    if (responseBody && response.data != null) {
      logger.i('Data:');
      logger.i(_formatData(response.data));
    }
  }

  void _logError(DioException err) {
    final statusCode = err.response?.statusCode ?? 'Unknown';
    final method = err.requestOptions.method.toUpperCase();
    final uri = err.requestOptions.uri;

    logger.e('❌ $method $uri - Status: $statusCode - ${err.message}');

    if (err.response?.data != null) {
      logger.e('Error Data:');
      logger.e(_formatData(err.response!.data));
    }
  }

  String _getStatusEmoji(int? statusCode) {
    if (statusCode == null) return '❓';
    if (statusCode >= 200 && statusCode < 300) return '✅';
    if (statusCode >= 300 && statusCode < 400) return '↗️';
    if (statusCode >= 400 && statusCode < 500) return '⚠️';
    return '❌';
  }

  String _formatData(dynamic data) {
    if (data == null) return 'null';

    if (data is String) return data;

    if (data is Map || data is List) {
      try {
        if (compact) {
          // 紧凑格式，限制长度
          final jsonStr = data.toString();
          if (jsonStr.length > 500) {
            return '${jsonStr.substring(0, 500)}... (truncated)';
          }
          return jsonStr;
        } else {
          // 详细格式，使用JSON美化
          return data.toString();
        }
      } catch (e) {
        return data.toString();
      }
    }

    return data.toString();
  }
}
