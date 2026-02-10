# BIPUPU 系统重构总结

## 重构日期
2026-02-10

## 核心变更

### 1. 用户身份体系
- ✅ 添加 `bipupu_id`（8位纯数字ID）作为核心标识
- ✅ `email` 改为可选字段
- ✅ 保留 `username` 用于登录
- ✅ 添加 `cosmic_profile` JSON 字段（存储生日、八字、MBTI等）
- ✅ 注册时自动生成唯一的 `bipupu_id`

### 2. 消息系统
- ✅ 简化消息模型，移除 `status`、`is_read`、`is_deleted` 等字段
- ✅ 添加 `sender_bipupu_id` 和 `receiver_bipupu_id` 字段
- ✅ 使用 `msg_type` 替代 `message_type`（支持 USER_POSTCARD、VOICE_TRANSCRIPT、COSMIC_BROADCAST）
- ✅ 保留 `pattern` JSON 字段用于控制 pupu 机显示/光效/屏保

### 3. 社交体系
- ✅ 创建 `TrustedContact` 模型替代复杂的好友系统
- ✅ 保留 `UserBlock` 黑名单模型
- ✅ 联系人关系单向（owner_id -> contact_id）
- ✅ 支持备注名（alias）

### 4. WebSocket 实时通讯
- ✅ 添加 `websockets` 依赖
- ✅ 创建 `ConnectionManager` 管理 WebSocket 连接
- ✅ 实现 `/ws` WebSocket 端点（基于 token 认证）
- ✅ 支持心跳机制（ping/pong）
- ✅ 新消息自动推送到在线用户

### 5. 头像系统
- ✅ 添加通过 `bipupu_id` 访问头像的端点
- ✅ `User.avatar_url` 属性自动生成 URL
- ✅ 支持头像上传到数据库（avatar_data）

### 6. API 接口

#### 认证接口
- `POST /api/public/register` - 注册（返回 bipupu_id）
- `POST /api/public/login` - 登录（返回 bipupu_id）
- `POST /api/public/refresh` - 刷新令牌

#### 用户接口
- `GET /api/client/users/{bipupu_id}` - 获取用户信息
- `GET /api/client/users/{bipupu_id}/avatar` - 获取用户头像

#### 消息接口（新）
- `POST /api/client/messages/` - 发送消息
- `GET /api/client/messages/?direction=sent|received` - 获取消息列表
- `DELETE /api/client/messages/{id}` - 删除消息

#### 联系人接口（新）
- `POST /api/client/contacts/` - 添加联系人
- `GET /api/client/contacts/` - 获取联系人列表
- `PUT /api/client/contacts/{id}` - 更新联系人备注
- `DELETE /api/client/contacts/{id}` - 删除联系人

#### WebSocket
- `WS /api/ws?token={access_token}` - WebSocket 连接

## 数据库迁移

迁移文件：`alembic/versions/refactor_bipupu_system.py`

运行迁移：
```bash
cd backend
alembic upgrade head
```

## 新增文件

### 模型
- `app/models/trusted_contact.py` - 联系人模型

### 核心工具
- `app/core/websocket.py` - WebSocket 连接管理器
- `app/core/user_utils.py` - 用户工具函数（生成 bipupu_id）

### Schemas
- `app/schemas/message_new.py` - 新消息 schemas
- `app/schemas/contact.py` - 联系人 schemas

### 服务
- `app/services/message_service_new.py` - 新消息服务

### 路由
- `app/api/routes/websocket.py` - WebSocket 路由
- `app/api/routes/client/users.py` - 用户公开信息路由
- `app/api/routes/client/contacts.py` - 联系人路由
- `app/api/routes/client/messages_new.py` - 新消息路由

## 兼容性说明

### 保留的功能
- 旧的 `Friendship` 模型仍然存在（可以逐步迁移）
- 旧的 `Message` 相关关系仍然存在
- 订阅系统保留

### 待清理的内容
根据重构指南，以下内容未来可以删除：
- `Friendship` 模型（用 `TrustedContact` 替代）
- 独立订阅系统（用服务号消息交互替代）
- 消息的 `status`、`is_read` 字段（由客户端管理）

## 测试建议

1. **注册测试**：验证 bipupu_id 正确生成
2. **登录测试**：验证返回包含 bipupu_id
3. **消息发送**：测试用户间消息发送
4. **WebSocket**：测试实时消息推送
5. **头像访问**：通过 bipupu_id 访问头像
6. **联系人管理**：添加、查看、删除联系人

## 下一步工作

1. 实现服务号系统（如 cosmic.fortune）
2. 创建订阅推送任务
3. 优化前端 Flutter App 以支持新接口
4. 添加隐私设置（是否只接收联系人消息）
5. 实现消息补拉机制（断线重连后拉取离线消息）
