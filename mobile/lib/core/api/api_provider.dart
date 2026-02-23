import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dio/dio.dart';
import 'rest_client.dart';
import 'dio_client.dart';

/// API客户端提供者
final restClientProvider = Provider<RestClient>((ref) {
  final dio = ref.watch(dioClientProvider);
  return RestClient(dio);
});

/// 长轮询API客户端提供者
final pollingRestClientProvider = Provider<RestClient>((ref) {
  final dio = ref.watch(pollingDioClientProvider);
  return RestClient(dio);
});

/// API响应包装器
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponse({required this.success, this.data, this.error, this.statusCode});

  factory ApiResponse.success(T data) => ApiResponse(success: true, data: data);

  factory ApiResponse.error(String error, {int? statusCode}) =>
      ApiResponse(success: false, error: error, statusCode: statusCode);
}

/// API异常处理
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final DioException? dioException;

  ApiException(this.message, {this.statusCode, this.dioException});

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' ($statusCode)' : ''}';
}

/// API工具类
class ApiUtils {
  /// 处理API调用，统一异常处理
  static Future<ApiResponse<T>> handleApiCall<T>(
    Future<T> apiCall, {
    String? errorMessage,
  }) async {
    try {
      final data = await apiCall;
      return ApiResponse.success(data);
    } on DioException catch (e) {
      final error = _parseDioError(e);
      return ApiResponse.error(error, statusCode: e.response?.statusCode);
    } catch (e) {
      return ApiResponse.error(errorMessage ?? '未知错误: $e');
    }
  }

  /// 解析Dio错误
  static String _parseDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      if (data is Map<String, dynamic>) {
        final detail = data['detail'];
        if (detail is String) return detail;
        if (detail is List && detail.isNotEmpty) {
          return detail.first.toString();
        }
      }

      switch (statusCode) {
        case 400:
          return '请求参数错误';
        case 401:
          return '未授权，请重新登录';
        case 403:
          return '权限不足';
        case 404:
          return '资源不存在';
        case 429:
          return '请求过于频繁，请稍后再试';
        case 500:
          return '服务器内部错误';
        default:
          return '网络错误 ($statusCode)';
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时';
      case DioExceptionType.sendTimeout:
        return '发送超时';
      case DioExceptionType.receiveTimeout:
        return '接收超时';
      case DioExceptionType.badCertificate:
        return '证书错误';
      case DioExceptionType.badResponse:
        return '服务器响应错误';
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.connectionError:
        return '网络连接错误';
      case DioExceptionType.unknown:
        return '未知网络错误';
    }
  }

  /// 检查响应是否成功
  static bool isSuccess(int? statusCode) {
    return statusCode != null && statusCode >= 200 && statusCode < 300;
  }

  /// 从响应中提取错误信息
  static String? extractErrorFromResponse(Map<String, dynamic> response) {
    if (response.containsKey('detail')) {
      final detail = response['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        return detail.first.toString();
      }
    }
    return null;
  }
}
