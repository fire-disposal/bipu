# Flutter项目架构简化迁移计划（优化版）

## 1. 现状分析

### 当前架构概览
```
lib/
├── api/              # Retrofit API客户端（生成文件）
├── controllers/      # GetX控制器（7个）
├── core/            # 核心基础设施
│   ├── bluetooth/   # ✅ 蓝牙栈（保持原样）
│   ├── components/  # ✅ UI组件库（保持原样）
│   ├── config/      # ✅ 配置（保持原样）
│   ├── http/        # ⚠️ HTTP配置（可简化）
│   └── theme/       # ✅ 主题配置（保持原样）
├── pages/           # ✅ UI页面（保持原样）
├── repos/           # ❌ Repository层（6个，需合并）
└── shared/          # ✅ 共享资源
    └── models/      # ✅ 数据模型（保持原样）
```

### 当前问题清单
1. **Repository层冗余**：6个Repository类，每个都创建独立的Dio实例
2. **代码重复严重**：每个Repository都有相同的错误处理模式
3. **依赖注入臃肿**：main.dart中需要注入14个依赖
4. **类型不安全**：所有Repository返回`Map<String, dynamic>`
5. **错误处理分散**：没有统一的错误处理机制

## 2. 迁移目标架构

```
lib/
├── api/              # ✅ 保留（Retrofit生成文件）
├── controllers/      # ✅ 保留（简化逻辑）
├── core/            # ✅ 保留（蓝牙/UI/主题不变）
├── pages/           # ✅ 保留（UI不变）
├── services/        # 🆕 新增（合并API+Repository）
│   ├── base_service.dart    # 基础服务类
│   ├── auth_service.dart    # 认证服务
│   ├── message_service.dart # 消息服务
│   ├── contact_service.dart # 联系人服务
│   ├── profile_service.dart # 个人资料服务
│   ├── block_service.dart   # 黑名单服务
│   └── poster_service.dart  # 海报服务
└── shared/          # ✅ 保留
    └── models/      # ✅ 保留（数据模型）
```

## 3. 迁移路线图

### 🎯 阶段1：基础设施准备
**TODO-1.1**: 创建services目录结构
**TODO-1.2**: 实现BaseService基类
**TODO-1.3**: 创建统一的错误处理机制
**TODO-1.4**: 实现Token管理拦截器

### 🎯 阶段2：认证模块迁移
**TODO-2.1**: 创建AuthService替换AuthRepo
**TODO-2.2**: 更新AuthController使用新服务
**TODO-2.3**: 测试登录/注册/登出功能
**TODO-2.4**: 验证Token自动刷新机制

### 🎯 阶段3：消息模块迁移
**TODO-3.1**: 创建MessageService替换MessageRepo
**TODO-3.2**: 更新MessageController使用新服务
**TODO-3.3**: 测试消息发送/接收功能
**TODO-3.4**: 验证长轮询机制

### 🎯 阶段4：其他模块迁移
**TODO-4.1**: 创建ContactService替换ContactRepo
**TODO-4.2**: 创建ProfileService替换ProfileRepo
**TODO-4.3**: 创建BlockService替换BlockRepo
**TODO-4.4**: 创建PosterService替换PosterRepo

### 🎯 阶段5：清理优化
**TODO-5.1**: 删除repos目录
**TODO-5.2**: 简化main.dart依赖注入
**TODO-5.3**: 更新所有导入语句
**TODO-5.4**: 运行完整功能测试

## 4. 详细重构方案

### 4.1 BaseService实现方案

```dart
// lib/services/base_service.dart
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/api_config.dart';

/// 服务层统一错误类型
enum ServiceErrorType {
  network,
  server,
  unauthorized,
  validation,
  unknown,
}

/// 服务层统一错误
class ServiceError {
  final String message;
  final ServiceErrorType type;
  final int? statusCode;
  
  ServiceError(this.message, this.type, {this.statusCode});
  
  @override
  String toString() => 'ServiceError($type): $message';
}

/// 服务层统一响应
class ServiceResponse<T> {
  final T? data;
  final ServiceError? error;
  final bool success;
  
  ServiceResponse.success(this.data) 
    : success = true, error = null;
    
  ServiceResponse.failure(this.error) 
    : success = false, data = null;
}

/// 基础服务类 - 所有服务的基类
abstract class BaseService {
  static Dio? _sharedDio;
  
  Dio get dio {
    _sharedDio ??= _createDio();
    return _sharedDio!;
  }
  
  Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    
    // 添加拦截器
    dio.interceptors.add(_createTokenInterceptor());
    dio.interceptors.add(_createLoggingInterceptor());
    
    return dio;
  }
  
  // 统一的HTTP方法封装
  Future<ServiceResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    T Function(Map<String, dynamic>)? fromJson,
  }) => _request<T>('GET', path, query: query, fromJson: fromJson);
  
  Future<ServiceResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(Map<String, dynamic>)? fromJson,
  }) => _request<T>('POST', path, data: data, fromJson: fromJson);
  
  Future<ServiceResponse<T>> put<T>(
    String path, {
    dynamic data,
    T Function(Map<String, dynamic>)? fromJson,
  }) => _request<T>('PUT', path, data: data, fromJson: fromJson);
  
  Future<ServiceResponse<T>> delete<T>(
    String path, {
    T Function(Map<String, dynamic>)? fromJson,
  }) => _request<T>('DELETE', path, fromJson: fromJson);
  
  // 统一的请求处理
  Future<ServiceResponse<T>> _request<T>(
    String method,
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await dio.request<T>(
        path,
        data: data,
        queryParameters: query,
        options: Options(method: method),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (fromJson != null && response.data is Map<String, dynamic>) {
          final parsedData = fromJson(response.data as Map<String, dynamic>);
          return ServiceResponse.success(parsedData);
        }
        return ServiceResponse.success(response.data as T);
      } else {
        return ServiceResponse.failure(ServiceError(
          '请求失败: ${response.statusCode}',
          ServiceErrorType.server,
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      return ServiceResponse.failure(_handleDioError(e));
    } catch (e) {
      return ServiceResponse.failure(ServiceError(
        e.toString(),
        ServiceErrorType.unknown,
      ));
    }
  }
  
  // 错误处理
  ServiceError _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ServiceError('网络连接超时', ServiceErrorType.network);
    } else if (e.type == DioExceptionType.connectionError) {
      return ServiceError('网络连接错误', ServiceErrorType.network);
    } else if (e.response?.statusCode == 401) {
      return ServiceError('未授权访问', ServiceErrorType.unauthorized);
    } else if (e.response?.statusCode == 400) {
      return ServiceError('请求参数错误', ServiceErrorType.validation);
    } else if (e.response?.statusCode == 500) {
      return ServiceError('服务器内部错误', ServiceErrorType.server);
    }
    
    return ServiceError(e.message ?? '未知错误', ServiceErrorType.unknown);
  }
  
  // Token拦截器
  InterceptorsWrapper _createTokenInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            // 重试原始请求
            final response = await dio.request(
              error.requestOptions.path,
              data: error.requestOptions.data,
              queryParameters: error.requestOptions.queryParameters,
              options: Options(
                method: error.requestOptions.method,
                headers: error.requestOptions.headers,
              ),
            );
            return handler.resolve(response);
          }
        }
        return handler.next(error);
      },
    );
  }
  
  // 日志拦截器
  InterceptorsWrapper _createLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          print('🚀 ${options.method} ${options.path}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('✅ ${response.statusCode} ${response.requestOptions.path}');
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          print('❌ ${error.response?.statusCode} ${error.requestOptions.path}');
        }
        return handler.next(error);
      },
    );
  }
  
  // Token管理
  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
  
  Future<bool> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }
    
    try {
      final response = await dio.post(
        '/api/public/refresh',
        data: {'refresh_token': refreshToken},
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await prefs.setString('access_token', data['access_token'] as String);
        
        if (data['refresh_token'] != null) {
          await prefs.setString(
            'refresh_token',
            data['refresh_token'] as String,
          );
        }
        
        return true;
      }
    } catch (_) {
      // 刷新失败
    }
    
    return false;
  }
}
```

### 4.2 AuthService重构方案

```dart
// lib/services/auth_service.dart
import 'package:get/get.dart';
import 'base_service.dart';
import '../models/user_model.dart';

/// 认证服务 - 替换AuthRepo
class AuthService extends BaseService {
  static AuthService get instance => Get.find();
  
  final RxBool isLoading = false.obs;
  final RxBool isLoggedIn = false.obs;
  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  
  /// 登录
  Future<ServiceResponse<Token>> login(String username, String password) async {
    isLoading.value = true;
    
    final response = await post<Token>(
      '/api/public/login',
      data: {'username': username, 'password': password},
      fromJson: (json) => Token.fromJson(json),
    );
    
    isLoading.value = false;
    
    if (response.success && response.data != null) {
      // 保存Token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', response.data!.accessToken);
      
      if (response.data!.refreshToken != null) {
        await prefs.setString('refresh_token', response.data!.refreshToken!);
      }
      
      // 加载用户信息
      await loadCurrentUser();
      
      Get.snackbar('成功', '登录成功');
    } else if (response.error != null) {
      Get.snackbar('错误', response.error!.message);
    }
    
    return response;
  }
  
  /// 加载当前用户
  Future<void> loadCurrentUser() async {
    final response = await get<UserModel>(
      '/api/profile/me',
      fromJson: (json) => UserModel.fromJson(json),
    );
    
    if (response.success && response.data != null) {
      currentUser.value = response.data;
      isLoggedIn.value = true;
    } else {
      isLoggedIn.value = false;
      currentUser.value = null;
    }
  }
  
  /// 检查认证状态
  Future<void> checkAuthStatus() async {
    final token = await _getAccessToken();
    if (token != null && token.isNotEmpty) {
      await loadCurrentUser();
    }
  }
  
  /// 登出
  Future<void> logout() async {
    try {
      await post('/api/public/logout');
    } catch (_) {
      // 忽略登出API错误
    }
    
    // 清除本地存储
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    
    // 重置状态
    isLoggedIn.value = false;
    currentUser.value = null;
    
    Get.snackbar('成功', '已登出');
  }
}
```

### 4.3 AuthController简化方案

```dart
// lib/controllers/auth_controller.dart（简化后）
import 'package:get/get.dart';
import '../services/auth_service.dart';

/// 认证控制器 - 只处理UI逻辑
class AuthController extends GetxController {
  static AuthController get to => Get.find();
  
  final AuthService _auth = AuthService.instance;
  
  // UI状态
  final username = ''.obs;
  final password = ''.obs;
  final showPassword = false.obs;
  final isLoading = _auth.isLoading;
  
  // 计算属性
  bool get canLogin => username.value.isNotEmpty && password.value.isNotEmpty;
  bool get isLoggedIn => _auth.isLoggedIn.value;
  UserModel? get currentUser => _auth.currentUser.value;
  
  /// 登录
  Future<void> login() async {
    if (!canLogin) {
      Get.snackbar('提示', '请输入用户名和密码');
      return;
    }
    
    final response = await _auth.login(username.value, password.value);
    
    if (response.success) {
      Get.offAllNamed('/main');
    }
  }
  
  /// 清空表单
  void clearForm() {
    username.value = '';
    password.value = '';
  }
  
  /// 切换密码可见性
  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }
}
```

### 4.4 其他服务模板

```dart
// lib/services/message_service.dart（模板）
import 'package:get/get.dart';
import 'base_service.dart';
import '../models/message_model.dart';

/// 消息服务 - 替换MessageRepo
class MessageService extends BaseService {
  static MessageService get instance => Get.find();
  
  final messages = <MessageResponse>[].obs;
  final favorites = <MessageResponse>[].obs;
  final isLoading = false.obs;
  
  /// 发送消息
  Future<ServiceResponse<MessageResponse>> sendMessage({
    required String receiverId,
    required String content,
    String messageType = 'NORMAL',
    Map<String, dynamic>? pattern,
    List<int>? waveform,
  }) async {
    isLoading.value = true;
    
    final response = await post<MessageResponse>(
      '/api/messages/',
      data: {
        'receiver_id': receiverId,
        'content': content,
        'message_type': messageType,
        if (pattern != null) 'pattern': pattern,
        if (waveform != null) 'waveform': waveform,
      },
      fromJson: (json) => MessageResponse.fromJson(json),
    );
    
    isLoading.value = false;
    
    if (response.success && response.data != null) {
      messages.insert(0, response.data!);
      Get.snackbar('成功', '消息发送成功');
    } else if (response.error != null) {
      Get.snackbar('错误', response.error!.message);
    }
    
    return response;
  }
  
  // 其他方法：getMessages, pollMessages, addFavorite等
}
```

## 5. 代码迁移对照表

| 原文件 | 新文件 | 迁移内容 | 状态 |
|--------|--------|----------|------|
| `repos/auth_repo.dart` | `services/auth_service.dart` | 认证逻辑 | TODO-2.1 |
| `repos/message_repo.dart` | `services/message_service.dart` | 消息逻辑 | TODO-3.1 |
| `repos/contact_repo.dart` | `services/contact_service.dart` | 联系人逻辑 | TODO-4.1 |
| `repos/profile_repo.dart` | `services/profile_service.dart` | 个人资料逻辑 | TODO-4.2 |
| `repos/block_repo.dart` | `services/block_service.dart` | 黑名单逻辑 | TODO-4.3 |
| `repos/poster_repo.dart` | `services/poster_service.dart` | 海报逻辑 | TODO-4.4 |
| `controllers/auth_controller.dart` | 同文件更新 | 使用AuthService | TODO-2.2 |
| `controllers/message_controller.dart` | 同文件更新 | 使用MessageService | TODO-3.2 |
| `main.dart
