# Bipupu API 文档

本文档详细描述 Bipupu 后端提供的所有 API 接口，包括认证、消息、联系人、用户管理等模块。

---

## 📋 目录

1. [基础信息](#基础信息)
2. [认证接口](#认证接口)
3. [消息接口](#消息接口)
4. [联系人接口](#联系人接口)
5. [黑名单接口](#黑名单接口)
6. [用户接口](#用户接口)
7. [个人资料接口](#个人资料接口)
8. [服务号接口](#服务号接口)
9. [海报接口](#海报接口)
10. [管理后台接口](#管理后台接口)
11. [WebSocket 接口](#websocket-接口)
12. [错误码](#错误码)

---

## 基础信息

### 基础 URL

```
开发环境: http://localhost:8000/api
生产环境: https://api.yourdomain.com/api
```

### 认证方式

所有需要认证的接口使用 **Bearer Token**:

```http
Authorization: Bearer <access_token>
```

### 请求格式

- **Content-Type**: `application/json`
- **字符编码**: UTF-8

### 响应格式

```json
{
  "data": {},           // 响应数据
  "message": "success", // 状态消息
  "code": 200          // 状态码
}
```

---

## 认证接口

### 1. 用户注册

**POST** `/public/register`

#### 请求参数

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| username | string | ✅ | 用户名 (3-50字符) |
| password | string | ✅ | 密码 (6-128字符) |
| nickname | string | ❌ | 昵称 (最大50字符) |

#### 请求示例

```json
{
  "username": "john_doe",
  "password": "secure_password123",
  "nickname": "John"
}
```

#### 响应示例

```json
{
  "id": 1,
  "username": "john_doe",
  "nickname": "John",
  "bipupu_id": "10000001",
  "created_at": "2024-01-15T10:30:00+00:00"
}
```

#### 错误码

| 状态码 | 说明 |
|--------|------|
| 400 | 用户名已存在或参数无效 |
| 422 | 请求体格式错误 |

---

### 2. 用户登录

**POST** `/public/login`

#### 请求参数

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| username | string | ✅ | 用户名 |
| password | string | ✅ | 密码 |

#### 请求示例

```json
{
  "username": "john_doe",
  "password": "secure_password123"
}
```

#### 响应示例

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "expires_in": 900
}
```

#### 错误码

| 状态码 | 说明 |
|--------|------|
| 401 | 用户名或密码错误 |
| 403 | 用户已被禁用 |

---

### 3. 刷新令牌

**POST** `/public/refresh`

#### 请求参数

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| refresh_token | string | ✅ | 刷新令牌 |

#### 响应示例

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "expires_in": 900
}
```

---

### 4. 用户登出

**POST** `/public/logout`

需要认证: ✅

#### 响应示例

```json
{
  "message": "登出成功"
}
```

---

## 消息接口

### 1. 获取消息列表

**GET** `/messages/`

需要认证: ✅

#### 查询参数

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| direction | string | ❌ | 方向: `sent` 或 `received` (默认: received) |
| page | int | ❌ | 页码 (默认: 1) |
| page_size | int | ❌ | 每页数量 (默认: 20, 最大: 100) |
| since_id | int | ❌ | 增量同步: 只返回 id > since_id 的消息 |

#### 响应示例

```json
{
  "messages": [
    {
      "id": 1,
      "sender_bipupu_id": "10000001",
      "receiver_bipupu_id": "10000002",
      "content": "Hello!",
      "message_type": "normal",
      "is_read": false,
      "created_at": "2024-01-15T10:30:00+00:00"
    }
  ],
  "total": 100,
  "page": 1,
  "page_size": 20
}
```

---

### 2. 发送消息

**POST** `/messages/`

需要认证: ✅

#### 请求参数

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| receiver_id | string | ✅ | 接收者 Bipupu ID |
| content | string | ✅ | 消息内容 (1-5000字符) |
| message_type | string | ❌ | 类型: `normal`, `voice`, `system` (默认: normal) |
| pattern | object | ❌ | 消息样式模式 |
| waveform | array | ❌ | 语音波形数据 (最大128个整数) |

#### 请求示例

```json
{
  "receiver_id": "10000002",
  "content": "Hello, how are you?",
  "message_type": "normal"
}
```

#### 响应示例

```json
{
  "id": 1,
  "sender_bipupu_id": "10000001",
  "receiver_bipupu_id": "10000002",
  "content": "Hello, how are you?",
  "message_type": "normal",
  "is_read": false,
  "created_at": "2024-01-15T10:30:00+00:00"
}
```

#### 错误码

| 状态码 | 说明 |
|--------|------|
| 400 | 接收者不存在或在黑名单中 |
| 429 | 发送频率限制 (30条/分钟) |

---

### 3. 获取消息详情

**GET** `/messages/{id}`

需要认证: ✅

#### 路径参数

| 参数 | 类型 | 说明 |
|------|------|------|
| id | int | 消息 ID |

#### 响应示例

```json
{
  "id": 1,
  "sender_bipupu_id": "10000001",
  "receiver_bipupu_id": "10000002",
  "content": "Hello!",
  "message_type": "normal",
  "is_read": true,
  "created_at": "2024-01-15T10:30:00+00:00"
}
```

---

### 4. 删除消息

**DELETE** `/messages/{id}`

需要认证: ✅

#### 路径参数

| 参数 | 类型 | 说明 |
|------|------|------|
| id | int | 消息 ID |

#### 响应示例

```json
{
  "message": "消息已删除"
}
```

---

### 5. 收藏消息

**POST** `/messages/{id}/favorite`

需要认证: ✅

#### 路径参数

| 参数 | 类型 | 说明 |
|------|------|------|
| id | int | 消息 ID |

#### 响应示例

```json
{
  "id": 1,
  "message_id": 1,
  "user_id": 1,
  "created_at": "2024-01-15T10:30:00+00:00"
}
```

---

### 6. 长轮询获取新消息

**GET** `/messages/poll`

需要认证: ✅

#### 查询参数

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| last_msg_id | int | ❌ | 最后收到的消息 ID (默认: 0) |
| timeout | int | ❌ | 超时时间秒数 (默认: 30, 最大: 120) |

#### 响应示例

```json
{
  "messages": [
    {
      "id": 3,
      "sender_bipupu_id": "10000001",
      "receiver_bipupu_id": "10000002",
      "content": "New message!",
      "message_type": "normal",
      "created_at": "2024-01-15T10:31:00+00:00"
    }
  ],
  "has_more": false
}
```

> 注: 如果没有新消息，连接会挂起直到超时或有新消息到达。

---

## 联系人接口

### 1. 获取联系人列表

**GET** `/contacts/`

需要认证: ✅

#### 查询参数

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| page | int | ❌ | 页码 (默认: 1) |
| page_size | int | ❌ | 每页数量 (默认: 20, 最大: 100) |

#### 响应示例

```json
{
  "items": [
    {
      "id": 1,
      "contact_bipupu_id": "10000002",
      "alias": "Friend",
      "created_at": "2024-01-15T10:30:00+00:00"
    }
  ],
  "total": 10,
  "page": 1,
  "page_size": 20
}
```

---

### 2. 添加联系人

**POST** `/contacts/`

需要认证: ✅

#### 请求参数

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| bipupu_id | string | ✅ | 联系人 Bipupu ID |
| alias | string | ❌ | 别名 |

#### 响应示例

```json
{
  "id": 1,
  "contact_bipupu_id": "10000002",
  "alias": "Friend",
  "created_at": "2024-01-15T10:30:00+00:00"
}
```

---

### 3. 编辑联系人

**PUT** `/contacts/{id}`

需要认证: ✅

#### 路径参数

| 参数 | 类型 | 说明 |
|------|------|------|
| id | int | 联系人 ID |

#### 请求参数

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| alias | string | ❌ | 新别名 |

#### 响应示例

```json
{
  "id": 1,
  "contact_bipupu_id": "10000002",
  "alias": "New Alias",
  "created_at": "2024-01-15T10:30:00+00:00"
}
```

---

### 4. 删除联系人

**DELETE** `/contacts/{id}`

需要认证: ✅

#### 路径参数

| 参数 | 类型 | 说明 |
|------|------|------|
| id | int | 联系人 ID |

#### 响应示例

```json
{
  "message": "联系人已删除"
}
```

---

## 黑名单接口

### 1. 拉黑用户

**POST** `/blocks`

需要认证: ✅

#### 请求参数

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| bipupu_id | string | ✅ | 要拉黑的用户 Bipupu ID |

#### 响应示例

```json
{
  "message": "用户已拉黑"
}
```

#### 错误码

| 状态码 | 说明 |
|--------|------|
| 400 | 不能拉黑自己或用户已在黑名单中 |
| 404 | 用户不存在 |

---

### 2. 解除拉黑

**DELETE** `/blocks/{bipupu_id}`

需要认证: ✅

#### 路径参数

| 参数 | 类型 | 说明 |
|------|------|------|
| bipupu_id | string | 要解除拉黑的用户 Bipupu ID |

#### 响应示例

```json
{
  "message": "用户已解除拉黑"
}
```

---

### 3. 获取黑名单列表

**GET** `/blocks`

需要认证: ✅

#### 查询参数

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| page | int | ❌ | 页码 (默认: 1) |
| page_size | int | ❌ | 每页数量 (默认: 20, 最大: 100) |

#### 响应示例

```json
{
  "items": [
    {
      "id": 1,
      "blocked_bipupu_id": "10000003",
      "blocked_nickname": "User3",
      "created_at": "2024-01-15T10:30:00+00:00"
    }
  ],
  "total": 5,
  "page": 1,
  "page_size": 20
}
```

---

## 用户接口

### 1. 搜索用户

**GET** `/users/search`

需要认证: ✅

#### 查询参数

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| q | string | ✅ | 搜索关键词 (用户名或昵称) |

#### 响应示例

```json
{
  "items": [
    {
      "bipupu_id": "10000002",
      "username": "jane_doe",
      "nickname": "Jane"
    }
  ],
  "total": 1
}
```

---

### 2. 获取用户公开信息

**GET** `/users/{bipupu_id}`

需要认证: ✅

#### 路径参数

| 参数 | 类型 | 说明 |
|------|------|------|
| bipupu_id | string | 用户 Bipupu ID |

#### 响应示例

```json
{
  "bipupu_id": "10000002",
  "username": "jane_doe",
  "nickname": "Jane",
  "avatar_url": "https://api.example.com/api/users/10000002/avatar"
}
```

---

### 3. 获取用户头像

**GET** `/users/{bipupu_id}/avatar`

#### 路径参数

| 参数 | 类型 | 说明 |
|------|------|------|
| bipupu_id | string | 用户 Bipupu ID |

#### 响应

返回头像图片 (JPEG/PNG)，支持 ETag 缓存。

---

## 个人资料接口

### 1. 获取当前用户信息

**GET** `/profile/me`

需要认证: ✅

#### 响应示例

```json
{
  "id": 1,
  "username": "john_doe",
  "nickname": "John",
  "bipupu_id": "10000001",
  "timezone": "Asia/Shanghai",
  "birth_date": "1990-01-01",
  "zodiac_sign": "Capricorn",
  "chinese_zodiac": "Horse",
  "mbti": "INTJ",
  "created_at": "2024-01-15T10:30:00+00:00"
}
```

---

### 2. 更新个人资料

**PUT** `/profile/me`

需要认证: ✅

#### 请求参数

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| nickname | string | ❌ | 昵称 |
| timezone | string | ❌ | 时区 |
| birth_date | string | ❌ | 生日 (YYYY-MM-DD) |
| mbti | string | ❌ | MBTI 类型 |

#### 响应示例

```json
{
  "id": 1,
  "username": "john_doe",
  "nickname": "John Updated",
  "bipupu_id": "10000001",
  "timezone": "Asia/Shanghai",
  "updated_at": "2024-01-15T11:00:00+00:00"
}
```

---

### 3. 上传头像

**POST** `/profile/avatar`

需要认证: ✅

#### 请求格式

`Content-Type: multipart/form-data`

#### 请求参数

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| file | file | ✅ | 图片文件 (JPEG/PNG, 最大 10MB) |

#### 响应示例

```json
{
  "avatar_url": "https://api.example.com/api/users/10000001/avatar",
  "updated_at": "2024-01-15T11:00:00+00:00"
}
```

---

### 4. 修改密码

**POST** `/profile/password`

需要认证: ✅

#### 请求参数

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| old_password | string | ✅ | 旧密码 |
| new_password | string | ✅ | 新密码 (6-128字符) |

#### 响应示例

```json
{
  "message": "密码修改成功"
}
```

---

## 服务号接口

### 1. 获取服务号列表

**GET** `/service_accounts/`

需要认证: ✅

#### 查询参数

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| page | int | ❌ | 页码 (默认: 1) |
| page_size | int | ❌ | 每页数量 (默认: 20, 最大: 100) |

#### 响应示例

```json
{
  "items": [
    {
      "name": "news_daily",
      "description": "每日新闻推送",
      "is_subscribed": true,
      "push_time": "08:00",
      "avatar_url": "https://api.example.com/api/service_accounts/news_daily/avatar"
    }
  ],
  "total": 10,
  "page": 1,
  "page_size": 20
}
```

---

### 2. 获取服务号详情

**GET** `/service_accounts/{name}`

需要认证: ✅

#### 路径参数

| 参数 | 类型 | 说明 |
|------|------|------|
| name | string | 服务号名称 |

#### 响应示例

```json
{
  "name": "news_daily",
  "description": "每日新闻推送",
  "is_subscribed": true,
  "push_time": "08:00",
  "created_at": "2024-01-15T10:30:00+00:00"
}
```

---

### 3. 订阅服务号

**POST** `/subscriptions`

需要认证: ✅

#### 请求参数

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| service_account_name | string | ✅ | 服务号名称 |

#### 响应示例

```json
{
  "id": 1,
  "service_account_name": "news_daily",
  "created_at": "2024-01-15T10:30:00+00:00"
}
```

---

### 4. 取消订阅

**DELETE** `/subscriptions/{name}`

需要认证: ✅

#### 路径参数

| 参数 | 类型 | 说明 |
|------|------|------|
| name | string | 服务号名称 |

#### 响应示例

```json
{
  "message": "取消订阅成功"
}
```

---

## 海报接口

### 1. 获取海报列表

**GET** `/posters/`

#### 查询参数

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| page | int | ❌ | 页码 (默认: 1) |
| page_size | int | ❌ | 每页数量 (默认: 20, 最大: 100) |

#### 响应示例

```json
{
  "posters": [
    {
      "id": 1,
      "title": "Welcome",
      "content": "Welcome to Bipupu!",
      "image_url": "https://api.example.com/api/posters/1/image",
      "created_at": "2024-01-15T10:30:00+00:00"
    }
  ],
  "total": 10,
  "page": 1,
  "page_size": 20
}
```

---

### 2. 获取海报详情

**GET** `/posters/{id}`

#### 路径参数

| 参数 | 类型 | 说明 |
|------|------|------|
| id | int | 海报 ID |

#### 响应示例

```json
{
  "id": 1,
  "title": "Welcome",
  "content": "Welcome to Bipupu!",
  "image_url": "https://api.example.com/api/posters/1/image",
  "created_at": "2024-01-15T10:30:00+00:00"
}
```

---

## 管理后台接口

### 1. 管理员登录

**POST** `/admin/login`

#### 请求参数

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| username | string | ✅ | 管理员用户名 |
| password | string | ✅ | 密码 |

#### 响应示例

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer"
}
```

---

### 2. 获取用户列表

**GET** `/admin/users`

需要管理员认证: ✅

#### 查询参数

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| page | int | ❌ | 页码 (默认: 1) |
| page_size | int | ❌ | 每页数量 (默认: 20) |
| search | string | ❌ | 搜索关键词 |

#### 响应示例

```json
{
  "items": [
    {
      "id": 1,
      "username": "john_doe",
      "nickname": "John",
      "bipupu_id": "10000001",
      "is_active": true,
      "created_at": "2024-01-15T10:30:00+00:00"
    }
  ],
  "total": 100,
  "page": 1,
  "page_size": 20
}
```

---

### 3. 获取消息列表

**GET** `/admin/messages`

需要管理员认证: ✅

#### 查询参数

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| page | int | ❌ | 页码 (默认: 1) |
| page_size | int | ❌ | 每页数量 (默认: 20) |
| sender_id | string | ❌ | 发送者 ID |
| receiver_id | string | ❌ | 接收者 ID |

---

### 4. 获取服务号列表

**GET** `/admin/service_accounts`

需要管理员认证: ✅

#### 查询参数

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| page | int | ❌ | 页码 (默认: 1) |
| page_size | int | ❌ | 每页数量 (默认: 20) |

---

## WebSocket 接口

### 连接信息

| 属性 | 值 |
|------|-----|
| **URL** | `ws://<host>/api/ws?token=<access_token>` |
| **协议** | WebSocket (RFC 6455) |
| **消息格式** | JSON |

### 消息类型

#### 客户端 → 服务端

**心跳 ping**

```json
{
  "type": "ping"
}
```

#### 服务端 → 客户端

**心跳响应 pong**

```json
{
  "type": "pong"
}
```

**新消息通知**

```json
{
  "type": "new_message",
  "data": {
    "id": 123,
    "sender_id": "10000001",
    "content": "消息内容",
    "message_type": "normal",
    "created_at": "2024-01-15T10:30:00+00:00"
  }
}
```

### 连接关闭码

| 关闭码 | 原因 | 说明 |
|--------|------|------|
| 1008 | Policy Violation | Token 无效或过期 |
| 1006 | Abnormal Closure | 连接异常断开 |
| 1000 | Normal Closure | 正常关闭 |

详细文档请参考 [WEBSOCKET_API.md](./WEBSOCKET_API.md)

---

## 错误码

### HTTP 状态码

| 状态码 | 说明 |
|--------|------|
| 200 | 请求成功 |
| 201 | 创建成功 |
| 400 | 请求参数错误 |
| 401 | 未认证 |
| 403 | 无权限 |
| 404 | 资源不存在 |
| 409 | 资源冲突 |
| 422 | 验证错误 |
| 429 | 请求过于频繁 |
| 500 | 服务器内部错误 |

### 业务错误码

| 错误码 | 说明 |
|--------|------|
| USER_NOT_FOUND | 用户不存在 |
| USER_ALREADY_EXISTS | 用户已存在 |
| INVALID_CREDENTIALS | 凭据无效 |
| TOKEN_EXPIRED | 令牌过期 |
| TOKEN_INVALID | 令牌无效 |
| RATE_LIMIT_EXCEEDED | 超出频率限制 |
| BLOCKED_USER | 用户已被拉黑 |
| MESSAGE_NOT_FOUND | 消息不存在 |
| CONTACT_NOT_FOUND | 联系人不存在 |
| SERVICE_ACCOUNT_NOT_FOUND | 服务号不存在 |

---

## 示例代码

### cURL 示例

```bash
# 登录
curl -X POST http://localhost:8000/api/public/login \
  -H "Content-Type: application/json" \
  -d '{"username": "john", "password": "secret"}'

# 发送消息 (需要替换 <token>)
curl -X POST http://localhost:8000/api/messages/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"receiver_id": "10000002", "content": "Hello!"}'

# 获取消息列表
curl http://localhost:8000/api/messages/ \
  -H "Authorization: Bearer <token>"
```

### Python 示例

```python
import requests

# 登录
response = requests.post(
    "http://localhost:8000/api/public/login",
    json={"username": "john", "password": "secret"}
)
token = response.json()["access_token"]

# 发送消息
headers = {"Authorization": f"Bearer {token}"}
response = requests.post(
    "http://localhost:8000/api/messages/",
    headers=headers,
    json={"receiver_id": "10000002", "content": "Hello!"}
)
print(response.json())
```

---

## 参考文档

- [WebSocket API 文档](./WEBSOCKET_API.md)
- [OpenAPI 规范](../backend/openapi.json)
- [后端代码审查报告](../backend/BACKEND_CODE_REVIEW.md)

---

**最后更新**: 2026年3月24日
**API 版本**: 1.0
**文档版本**: 1.0
