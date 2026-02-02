<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

Flutter Core 为 Bipupu 的跨应用核心网络/模型层，封装统一的 API 客户端与仓库。

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

- 需要在应用启动时初始化 `ApiClient` 并设置 `baseUrl`（指向后端 `/api` 根）。
	示例：

```dart
import 'package:flutter_core/core/network/api_client.dart';
import 'package:flutter_core/core/storage/token_storage.dart';

final api = ApiClient();
api.init(
	baseUrl: 'https://your-host/api', // 约定：'/api' 放在 baseUrl
	tokenStorage: MyTokenStorageImplementation(),
);
```

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

### 鉴权与自动刷新
- `AuthInterceptor` 会在请求中自动附加 `Authorization: Bearer <access_token>`。
- 当访问返回 `401` 时，拦截器会：
	- 使用独立 `Dio` 调用 `POST /api/public/refresh` 刷新令牌；
	- 并发到达的多个 401 会排队等待同一次刷新完成；
	- 刷新成功后自动重试原请求；若失败则清理本地 Token 并回调 `onUnauthorized()`。
- 需要在 `ApiClient.init` 时传入自定义的 `TokenStorage` 实现以读写 `access_token` 与 `refresh_token`。

### 认证（Public）
- 登录：`POST /api/public/login` → `AuthResponse`
- 注册：`POST /api/public/register` → `User`
- 刷新：`POST /api/public/refresh` → `AuthResponse`
- 登出：`POST /api/public/logout`

### 用户资料（Client/Profile）
- 当前用户：`GET /api/client/profile/me`
- 资料读取/更新：`GET/PUT /api/client/profile/profile`
- 在线状态：`PUT /api/client/profile/online-status`（传 `{is_online: bool}`）

### 消息（Client/Messages）
- 列表/创建：`GET/POST /api/client/messages/`
- 会话：`GET /api/client/messages/conversations/{user_id}`
- 未读数：`GET /api/client/messages/unread/count`（返回 `int`）
- 标记已读：`PUT /api/client/messages/{id}/read` / `PUT /api/client/messages/read-all`
- 收藏/取消：`POST/DELETE /api/client/messages/{id}/favorite`
- 归档：`PUT /api/client/messages/{id}/archive`
- 批量删除：`DELETE /api/client/messages/batch`

### 好友（Client/Friends）与黑名单（Client/Blocks）
- 参见 `flutter_core/lib/core/network/rest_client.dart` 对应方法

### 管理员（Admin）
- 用户管理：`GET /api/admin/users` 等
- 日志：`/api/admin/logs`、`/api/admin/logs/stats`

### 健康检查
- `GET /api/health`、`/api/ready`、`/api/live`

更多端点请参考仓库根目录的 API 文档与 `openapi.json`。

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
