# Bipupu API 文档

## 概述
Bipupu 是一个现代化的后端API服务，采用FastAPI框架开发，提供了完整的用户管理、认证和业务功能。

## 路由结构

### 根目录 (`/`)
- `GET /` - API信息
- `GET /health` - 系统健康检查

### 公共接口 (`/public`)
- `POST /public/register` - 用户注册
- `POST /public/login` - 用户登录
- `POST /public/refresh` - 刷新令牌
- `POST /public/logout` - 用户登出

### 客户端API (`/client`) - 需要用户认证

#### 个人资料 (`/client/profile`)
- `GET /client/profile/me` - 获取当前用户信息
- `GET /client/profile/profile` - 获取用户详细资料
- `PUT /client/profile/profile` - 更新用户详细资料
- `PUT /client/profile/online-status` - 更新用户在线状态

#### 消息系统 (`/client/messages`)
- `POST /client/messages/` - 创建消息
- `GET /client/messages/` - 获取消息列表
- `GET /client/messages/conversations/{user_id}` - 获取与指定用户的会话消息
- `GET /client/messages/unread/count` - 获取未读消息数量
- `GET /client/messages/stats` - 获取消息统计信息
- `GET /client/messages/{message_id}` - 获取指定消息
- `PUT /client/messages/{message_id}` - 更新消息
- `PUT /client/messages/{message_id}/read` - 标记消息为已读
- `PUT /client/messages/read-all` - 标记所有消息为已读
- `DELETE /client/messages/{message_id}` - 删除消息

#### 好友系统 (`/client/friends`)
- `POST /client/friends/` - 发送好友请求
- `GET /client/friends/` - 获取好友关系列表
- `GET /client/friends/requests` - 获取待处理的好友请求
- `GET /client/friends/friends` - 获取好友列表
- `PUT /client/friends/{friendship_id}/accept` - 接受好友请求
- `PUT /client/friends/{friendship_id}/reject` - 拒绝好友请求
- `DELETE /client/friends/{friendship_id}` - 删除好友关系

#### 黑名单系统 (`/client/blocks`)
- `POST /client/blocks` - 拉黑用户
- `DELETE /client/blocks/{user_id}` - 解除拉黑
- `GET /client/blocks` - 获取黑名单列表

### 管理员API (`/admin`) - 需要管理员权限
- `GET /admin/users` - 获取用户列表（分页）
- `GET /admin/users/{user_id}` - 获取指定用户
- `PUT /admin/users/{user_id}` - 更新用户信息
- `DELETE /admin/users/{user_id}` - 删除用户
- `PUT /admin/users/{user_id}/status` - 更新用户状态
- `GET /admin/users/stats` - 获取用户统计
- `GET /admin/system/health` - 系统健康检查

## 认证
- 所有需要认证的端点都需要在请求头中包含 `Authorization: Bearer {token}`
- 使用JWT令牌进行认证
- 访问令牌有效期为30分钟
- 刷新令牌用于获取新的访问令牌

## 错误处理
API使用统一的错误响应格式：
```json
{
  "success": false,
  "error": {
    "type": "ErrorType",
    "message": "错误信息",
    "code": "错误代码",
    "details": {}
  }
}
```

## 缓存策略
- 用户资料信息会被缓存30分钟
- 管理员用户列表会被缓存1分钟
- 用户好友列表会被缓存5分钟
- 统计信息会被缓存5分钟

当用户信息更新时，相关缓存会自动失效。

## 安全特性
- 密码使用Argon2算法加密
- 支持速率限制
- CORS配置基于Nginx配置
- 输入验证和清理