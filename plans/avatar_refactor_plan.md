# 头像管理重构计划

## 当前状态分析

### 现有 avatar_version 的用途
1. **缓存失效控制**：在 `/users/{bipupu_id}/avatar` 端点中用于生成 ETag
2. **版本跟踪**：记录头像更新次数
3. **HTTP 缓存优化**：支持 304 Not Modified 响应

### 问题
- `avatar_version` 在数据库中允许为 NULL，但 Pydantic 模型要求为整数
- 导致响应验证失败（ResponseValidationError）
- 当前设计支持多版本头像，但实际只存储一个

## 重构方案

### 核心设计原则
**一次只存在一个头像**，使用 `updated_at` 时间戳替代版本号进行缓存控制

### 方案对比

| 方面 | 当前方案 | 重构方案 |
|------|--------|--------|
| 头像存储 | avatar_data (BLOB) | avatar_data (BLOB) |
| 版本控制 | avatar_version (INT) | ❌ 移除 |
| 缓存失效 | 版本号 + 时间戳 | ✅ 时间戳 (updated_at) |
| ETag 生成 | version:timestamp | ✅ 直接使用 updated_at |
| 数据库迁移 | 需要 | ✅ 简单（删除列） |

## 实施步骤

### 1. 数据库迁移
```python
# 创建新的迁移文件
# 删除 avatar_version 列
op.drop_column('users', 'avatar_version')
op.drop_column('service_accounts', 'avatar_version')
```

### 2. 数据模型更新

#### User 模型 (`backend/app/models/user.py`)
- ❌ 删除 `avatar_version` 字段
- ❌ 删除 `increment_avatar_version()` 方法
- ✅ 保留 `updated_at` 字段（已存在）

#### ServiceAccount 模型 (`backend/app/models/service_account.py`)
- ❌ 删除 `avatar_version` 字段
- ❌ 删除 `increment_avatar_version()` 方法

### 3. Schema 更新

#### UserPrivate (`backend/app/schemas/user.py`)
- ❌ 删除 `avatar_version` 字段

#### ServiceAccountResponse (`backend/app/schemas/service_account.py`)
- ❌ 删除 `avatar_version` 字段

### 4. API 端点更新

#### 头像上传 (`backend/app/api/routes/profile.py`)
```python
# 上传头像时
current_user.avatar_data = avatar_data
# ❌ 删除: current_user.increment_avatar_version()
# ✅ 自动更新 updated_at（SQLAlchemy onupdate）
db.commit()
```

#### 头像获取 (`backend/app/api/routes/users.py`)
```python
# 生成 ETag 时
# ❌ 旧方式: version = user.avatar_version or 0
# ✅ 新方式: 直接使用 updated_at 时间戳
updated_at_timestamp = user.updated_at.timestamp() if user.updated_at else 0
etag_input = f"{updated_at_timestamp}".encode()
```

#### 服务账户头像 (`backend/app/api/routes/service_accounts.py`)
- 同样更新 ETag 生成逻辑

#### 管理后台 (`backend/app/api/routes/admin_web.py`)
```python
# ❌ 删除: service.increment_avatar_version()
# ✅ 自动更新 updated_at
```

### 5. 缓存键更新
- 保持不变：`avatar:{bipupu_id}`
- 缓存失效：当 `updated_at` 变化时自动失效

## 优势

1. **简化设计**：移除冗余的版本号字段
2. **自动管理**：`updated_at` 由 SQLAlchemy 自动维护
3. **解决验证错误**：不再有 NULL 值问题
4. **保留功能**：缓存控制和 ETag 机制完全保留
5. **一致性**：所有实体（User、ServiceAccount）统一处理

## 风险评估

| 风险 | 影响 | 缓解措施 |
|------|------|--------|
| 数据库迁移 | 低 | 简单的 DROP COLUMN 操作 |
| 缓存失效 | 低 | 时间戳同样有效 |
| 客户端兼容性 | 低 | 移除字段不影响现有客户端 |

## 实施顺序

1. ✅ 创建数据库迁移
2. ✅ 更新 User 和 ServiceAccount 模型
3. ✅ 更新 Schema 定义
4. ✅ 更新所有 API 端点
5. ✅ 测试验证
