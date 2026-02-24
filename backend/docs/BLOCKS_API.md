# 黑名单API文档

## 概述

黑名单API提供用户之间的拉黑管理功能。用户可以将其他用户加入黑名单，阻止双方互相发送消息。黑名单关系是单向的，且需要用户认证才能访问。

## 基础信息

- **基础路径**: `/api/blocks`
- **认证方式**: Bearer Token (JWT)
- **权限要求**: 需要用户认证，无需管理员权限

## API端点

### 1. 拉黑用户

将指定用户加入黑名单。

**请求**
- **方法**: `POST /api/blocks`
- **Content-Type**: `application/json`
- **请求体**:
  ```json
  {
    "bipupu_id": "string"  // 要拉黑的用户Bipupu ID
  }
  ```

**响应**
- **成功** (200 OK):
  ```json
  {
    "message": "用户已拉黑"
  }
  ```
- **失败**:
  - 400 Bad Request: 不能拉黑自己、用户已在黑名单中
  - 404 Not Found: 用户不存在
  - 500 Internal Server Error: 数据库操作失败

**示例**
```bash
curl -X POST http://localhost:8000/api/blocks \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"bipupu_id": "10000001"}'
```

### 2. 解除拉黑用户

从黑名单中移除指定用户。

**请求**
- **方法**: `DELETE /api/blocks/{bipupu_id}`
- **路径参数**:
  - `bipupu_id`: 要解除拉黑的用户Bipupu ID

**响应**
- **成功** (200 OK):
  ```json
  {
    "message": "用户已解除拉黑"
  }
  ```
- **失败**:
  - 404 Not Found: 用户不存在或不在黑名单中
  - 500 Internal Server Error: 数据库操作失败

**示例**
```bash
curl -X DELETE http://localhost:8000/api/blocks/10000001 \
  -H "Authorization: Bearer <token>"
```

### 3. 获取黑名单列表

获取当前用户的黑名单列表，支持分页。

**请求**
- **方法**: `GET /api/bl