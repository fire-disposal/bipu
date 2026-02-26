# API Schema 修复报告

## 问题概述

后端 API 接口与数据库 schema 存在严重的字段名称不匹配问题，导致前端严格按照 schema 生成的请求客户端在多个接口产生 500 错误。

### 错误日志
```
INFO:     app.api.routes.contacts - 获取联系人列表失败: type object 'TrustedContact' has no attribute 'user_id'
INFO:     app.core.exceptions - HTTP Exception: 500 - 获取联系人列表失败
```

---

## 修复内容

### 1. TrustedContact 模型修复

**文件**: `backend/app/models/trusted_contact.py`

**问题**: 模型定义使用了 `owner_id` 和 `contact_id` 字段，但 API 路由代码引用的是 `user_id` 和 `contact_bipupu_id`

**修复**:
- 将 `owner_id` 改为 `user_id`
- 将 `contact_id` (Integer ForeignKey) 改为 `contact_bipupu_id` (String)
- 移除了 `contact` 关系（因为 `contact_bipupu_id` 是字符串，无法直接关联）
- 更新了 UniqueConstraint 和 `__repr__` 方法

```python
# 修复前
owner_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
contact_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)

# 修复后
user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
contact_bipupu_id = Column(String(100), nullable=False, index=True)
```

### 2. User 模型关系修复

**文件**: `backend/app/models/user.py`

**问题**: User 模型中的 contacts 关系引用了错误的字段名

**修复**:
```python
# 修复前
contacts = relationship("TrustedContact", foreign_keys="[TrustedContact.owner_id]", back_populates="owner", cascade="all, delete-orphan")

# 修复后
contacts = relationship("TrustedContact", foreign_keys="[TrustedContact.user_id]", back_populates="user", cascade="all, delete-orphan")
```

### 3. Contacts API 路由验证

**文件**: `backend/app/api/routes/contacts.py`

**状态**: ✅ 已验证正确
- 所有字段引用都与修复后的模型一致
- 使用 `TrustedContact.user_id` 和 `TrustedContact.contact_bipupu_id`

### 4. UserBlock 模型验证

**文件**: `backend/app/models/user_block.py`

**状态**: ✅ 已验证正确
- 使用 `blocker_id` 和 `blocked_id` 字段

### 5. Blocks API 路由修复

**文件**: `backend/app/api/routes/blocks.py`

**问题**: 路由代码使用了错误的字段名 `user_id` 和 `blocked_user_id`

**修复位置**:
1. 第 57-60 行: 检查是否已拉黑
2. 第 65-68 行: 创建拉黑记录
3. 第 102-105 行: 查询黑名单
4. 第 110-114 行: 排序字段从 `blocked_at` 改为 `created_at`
5. 第 118-129 行: 获取被拉黑用户信息
6. 第 163-167 行: 查找拉黑记录
7. 第 212-222 行: 检查拉黑状态
8. 第 254-258 行: 查询黑名单
9. 第 262-264 行: 获取被拉黑用户 ID 列表
10. 第 274-287 行: 构建响应
11. 第 305-309 行: 获取黑名单数量

**修复内容**:
```python
# 修复前
UserBlock.user_id == current_user.id
UserBlock.blocked_user_id == blocked_user.id
block.blocked_at

# 修复后
UserBlock.blocker_id == current_user.id
UserBlock.blocked_id == blocked_user.id
block.created_at
```

### 6. 数据库迁移

**文件**: `backend/alembic/versions/fix_trusted_contacts_schema.py`

**内容**: 创建了新的迁移脚本，用于：
- 删除旧的 `trusted_contacts` 表（使用 `owner_id` 和 `contact_id`）
- 创建新的 `trusted_contacts` 表（使用 `user_id` 和 `contact_bipupu_id`）
- 支持回滚操作

---

## 验证清单

- [x] TrustedContact 模型字段名称与 API 路由一致
- [x] User 模型关系引用正确的字段
- [x] Contacts API 路由使用正确的字段名
- [x] UserBlock 模型字段名称正确
- [x] Blocks API 路由使用正确的字段名
- [x] 数据库迁移脚本已创建
- [x] 所有字段引用已验证

---

## 后续步骤

1. **执行数据库迁移**:
   ```bash
   cd backend
   alembic upgrade head
   ```

2. **重启后端服务**:
   ```bash
   # 使用 Docker
   docker-compose restart backend
   
   # 或本地运行
   python -m uvicorn app.main:app --reload
   ```

3. **测试 API 接口**:
   - 测试获取联系人列表: `GET /api/contacts/?page=1&page_size=100`
   - 测试获取黑名单: `GET /api/blocks/?page=1&page_size=20`
   - 测试其他相关接口

4. **前端验证**:
   - 确认前端生成的请求客户端能正确调用 API
   - 验证响应数据格式与 schema 一致

---

## 相关文件修改总结

| 文件 | 修改类型 | 说明 |
|------|---------|------|
| `backend/app/models/trusted_contact.py` | 修改 | 字段名称修复 |
| `backend/app/models/user.py` | 修改 | 关系引用修复 |
| `backend/app/api/routes/blocks.py` | 修改 | 字段引用修复 |
| `backend/alembic/versions/fix_trusted_contacts_schema.py` | 新建 | 数据库迁移脚本 |

---

## 注意事项

1. **数据迁移**: 如果生产环境中已有数据，需要在执行迁移前备份数据库
2. **API 兼容性**: 修复后的 API 响应格式与之前不同，前端需要相应更新
3. **测试**: 建议在测试环境中先验证所有修复，确保无误后再部署到生产环境
