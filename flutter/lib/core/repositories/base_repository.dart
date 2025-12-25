/// 基础Repository类，封装通用的CRUD操作
library;

import 'package:openapi/openapi.dart';
import '../core.dart';
import '../injection/service_locator.dart';

/// 基础Repository接口
abstract class BaseRepository<T, ID> {
  /// 获取所有数据
  Future<List<T>> findAll({
    int skip = 0,
    int limit = 100,
    Map<String, dynamic>? filters,
  });

  /// 根据ID获取数据
  Future<T?> findById(ID id);

  /// 创建数据
  Future<T> create(T entity);

  /// 更新数据
  Future<T> update(ID id, T entity);

  /// 删除数据
  Future<void> delete(ID id);

  /// 批量删除
  Future<void> deleteBatch(List<ID> ids);

  /// 获取统计信息
  Future<Map<String, dynamic>> getStats();
}

/// API响应包装类
class ApiResponse<T> {
  final T? data;
  final String? error;
  final int statusCode;

  const ApiResponse({this.data, this.error, this.statusCode = 200});

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get hasError => error != null;
}

/// 基础Repository实现类
abstract class BaseRepositoryImpl<T, ID> implements BaseRepository<T, ID> {
  final Openapi _apiClient;
  final Logger _logger;

  BaseRepositoryImpl({Openapi? apiClient})
    : _apiClient = apiClient ?? ServiceLocatorConfig.get<Openapi>(),
      _logger = Logger();

  Openapi get apiClient => _apiClient;
  Logger get logger => _logger;

  /// 处理API响应
  ApiResponse<R> handleApiResponse<R>({
    required dynamic response,
    R Function(dynamic data)? dataMapper,
    String operation = 'API操作',
  }) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = dataMapper != null && response.data != null
            ? dataMapper(response.data)
            : response.data as R?;
        return ApiResponse<R>(data: data, statusCode: response.statusCode);
      } else {
        final errorMsg = 'API调用失败: ${response.statusCode}';
        Logger.error('$operation - $errorMsg');
        return ApiResponse<R>(error: errorMsg, statusCode: response.statusCode);
      }
    } catch (e) {
      final errorMsg = 'API处理异常: $e';
      Logger.error('$operation - $errorMsg');
      return ApiResponse<R>(error: errorMsg, statusCode: 500);
    }
  }

  /// 统一的错误处理
  String handleError(dynamic error, String operation) {
    String errorMessage;

    if (error is Exception) {
      errorMessage = error.toString();
    } else if (error is Error) {
      errorMessage = error.toString();
    } else {
      errorMessage = '未知错误: $error';
    }

    Logger.error('$operation 失败: $errorMessage');
    return errorMessage;
  }

  /// 分页参数构建
  Map<String, dynamic> buildPaginationParams({
    int skip = 0,
    int limit = 100,
    Map<String, dynamic>? additionalParams,
  }) {
    final params = <String, dynamic>{'skip': skip, 'limit': limit};

    if (additionalParams != null) {
      params.addAll(additionalParams);
    }

    return params;
  }

  /// 过滤参数构建
  Map<String, dynamic> buildFilterParams(Map<String, dynamic> filters) {
    final params = <String, dynamic>{};

    filters.forEach((key, value) {
      if (value != null) {
        params[key] = value;
      }
    });

    return params;
  }
}

/// 用户相关Repository基类
abstract class UserRepository<T> extends BaseRepositoryImpl<T, int> {
  UserRepository({super.apiClient});

  /// 获取用户统计信息
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await apiClient
          .getUsersApi()
          .adminGetUserStatsApiUsersAdminStatsGet();
      final apiResponse = handleApiResponse<Map<String, dynamic>>(
        response: response,
        dataMapper: (data) => data as Map<String, dynamic>,
        operation: '获取用户统计',
      );

      if (apiResponse.isSuccess && apiResponse.data != null) {
        return apiResponse.data as Map<String, dynamic>;
      }

      return {};
    } catch (e) {
      Logger.error('获取用户统计失败: $e');
      return {};
    }
  }
}

/// 设备相关Repository基类
abstract class DeviceRepository<T> extends BaseRepositoryImpl<T, int> {
  DeviceRepository({super.apiClient});

  /// 获取设备统计信息
  Future<Map<String, dynamic>> getDeviceStats() async {
    try {
      final response = await apiClient
          .getDevicesApi()
          .getDeviceStatsApiDevicesStatsGet();
      final apiResponse = handleApiResponse<Map<String, dynamic>>(
        response: response,
        dataMapper: (data) => data as Map<String, dynamic>,
        operation: '获取设备统计',
      );

      if (apiResponse.isSuccess && apiResponse.data != null) {
        return apiResponse.data as Map<String, dynamic>;
      }

      return {};
    } catch (e) {
      Logger.error('获取设备统计失败: $e');
      return {};
    }
  }
}

/// 消息相关Repository基类
abstract class MessageRepository<T> extends BaseRepositoryImpl<T, int> {
  MessageRepository({super.apiClient});

  /// 获取消息统计信息
  Future<Map<String, dynamic>> getMessageStats() async {
    try {
      final response = await apiClient
          .getMessagesApi()
          .getMessageStatsApiMessagesStatsGet();
      final apiResponse = handleApiResponse<Map<String, dynamic>>(
        response: response,
        dataMapper: (data) => data as Map<String, dynamic>,
        operation: '获取消息统计',
      );

      if (apiResponse.isSuccess && apiResponse.data != null) {
        return apiResponse.data as Map<String, dynamic>;
      }

      return {};
    } catch (e) {
      Logger.error('获取消息统计失败: $e');
      return {};
    }
  }
}
