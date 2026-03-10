# WebSocket API 文档

## 概述

WebSocket 接口用于实现实时消息推送，支持服务端向客户端推送新消息通知。

## 连接信息

| 属性 | 值 |
|------|-----|
| **URL** | `ws://<host>/api/ws?token=<access_token>` |
| **协议** | WebSocket (RFC 6455) |
| **消息格式** | JSON |
| **认证方式** | Query 参数 Token (JWT) |

## 连接流程

```
客户端                              服务端
  │                                   │
  ├─ 1. 连接 ws://host/api/ws ──────>│
  │   ?token=xxx                      │
  │                                   │
  │<─ 2. Token 验证 ─────────────────┤
  │                                   │
  │<─ 3. 连接建立 (101 Switching) ────┤
  │                                   │
  ├─ 4. 每 30s 发送 ping ───────────>│
  │                                   │
  │<─ 5. 服务端返回 pong ─────────────┤
```

## 消息协议

### 通用格式

```json
{
  "type": "消息类型",
  // ... 类型特定字段
}
```

### 支持的消息类型

#### 1. 心跳 - ping (客户端 → 服务端)

客户端每 30 秒发送一次，保持连接活跃。

**请求：**
```json
{
  "type": "ping"
}
```

**响应：**
```json
{
  "type": "pong"
}
```

#### 2. 新消息通知 - new_message (服务端 → 客户端)

当有新消息送达时，服务端主动推送。

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

**字段说明：**

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | int | 消息ID |
| `sender_id` | string | 发送者 Bipupu ID |
| `content` | string | 消息内容 |
| `message_type` | string | 消息类型：`normal`/`voice`/`system` |
| `created_at` | string | ISO 8601 格式时间 |

## 错误处理

### 连接关闭码

| 关闭码 | 原因 | 说明 |
|--------|------|------|
| `1008` | Policy Violation | Token 无效或过期 |
| `1006` | Abnormal Closure | 连接异常断开（网络问题） |
| `1000` | Normal Closure | 正常关闭 |

### 认证失败

当 Token 无效时，服务端会立即关闭连接并返回 1008。

```json
HTTP/1.1 403 Forbidden
WebSocket 关闭码: 1008
```

### 心跳超时

服务端在 30 秒内未收到客户端 ping，会主动发送 ping 检测。若 5 秒内无 pong 响应，断开连接。

## 客户端实现示例 (Flutter/Dart)

```dart
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';

class WebSocketClient {
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  final String baseUrl;
  final String token;
  
  WebSocketClient({required this.baseUrl, required this.token});
  
  /// 连接 WebSocket
  void connect() {
    final wsUrl = 'ws://$baseUrl/api/ws?token=$token';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    
    // 监听消息
    _channel!.stream.listen(
      (message) => _handleMessage(message),
      onError: (error) => print('WS Error: $error'),
      onDone: () {
        print('WS Disconnected');
        _reconnect();
      },
    );
    
    // 启动心跳
    _startHeartbeat();
  }
  
  /// 处理消息
  void _handleMessage(String message) {
    final data = json.decode(message);
    final type = data['type'];
    
    switch (type) {
      case 'pong':
        // 心跳响应，无需处理
        break;
      case 'new_message':
        final msg = data['data'];
        print('New message: ${msg['content']}');
        // TODO: 显示通知或更新UI
        break;
    }
  }
  
  /// 发送心跳
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 25),
      (_) => _send({'type': 'ping'}),
    );
  }
  
  /// 发送消息
  void _send(Map<String, dynamic> data) {
    _channel?.sink.add(json.encode(data));
  }
  
  /// 断线重连
  void _reconnect() {
    _heartbeatTimer?.cancel();
    Future.delayed(const Duration(seconds: 3), connect);
  }
  
  /// 断开连接
  void disconnect() {
    _heartbeatTimer?.cancel();
    _channel?.sink.close();
  }
}
```

## 注意事项

1. **Token 有效期**：WebSocket 连接建立时验证 Token，连接期间不重复验证
2. **多设备支持**：同一用户可在多个设备同时在线，消息会推送到所有设备
3. **重连策略**：建议实现指数退避重连（3s → 6s → 12s → 30s）
4. **后台处理**：App 进入后台时保持连接，系统可能会自动断开，需做好重连准备

## 变更日志

| 日期 | 版本 | 变更 |
|------|------|------|
| 2024-01-15 | 1.0 | 初始版本 |
