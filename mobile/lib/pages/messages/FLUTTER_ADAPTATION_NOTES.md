# Flutter 消息页面适配说明

**更新时间**: 2026-02-26  
**适配范围**: 消息相关页面 API 调用和字段名称

---

## 📋 适配摘要

根据后端 Schema 优化，Flutter 消息相关页面进行了以下适配：

- ✅ **字段名称更新**: `senderId`/`receiverId` → `senderBipupuId`/`receiverBipupuId`
- ✅ **API 参数优化**: 添加 `direction` 参数以优化后端查询
- ✅ **长轮询逻辑**: 保持现有实现，可进一步优化

---

## 🔄 修改详情

### 1. [`mobile/lib/pages/messages/pages/received_messages_page.dart`](mobile/lib/pages/messages/pages/received_messages_page.dart)

**修改内容**:
- API 调用添加 `direction: 'received'` 参数
- 字段名 `msg.receiverId` → `msg.receiverBipupuId`
- 字段名 `msg.senderId` → `msg.senderBipupuId`

**代码示例**:
```dart
// 之前
final response = await ApiClient.instance.api.messages.getApiMessages();
final filtered = response.messages
    .where((msg) => msg.receiverId == myId && msg.messageType != MessageType.system)
    .toList();

// 之后
final response = await ApiClient.instance.api.messages.getApiMessages(direction: 'received');
final filtered = response.messages
    .where((msg) => msg.receiverBipupuId == myId && msg.messageType != MessageType.system)
    .toList();
```

**影响**: 收件箱现在使用后端过滤，减少客户端处理

---

### 2. [`mobile/lib/pages/messages/pages/sent_messages_page.dart`](mobile/lib/pages/messages/pages/sent_messages_page.dart)

**修改内容**:
- API 调用添加 `direction: 'sent'` 参数
- 字段名 `msg.senderId` → `msg.senderBipupuId`
- 字段名 `msg.receiverId` → `msg.receiverBipupuId`

**代码示例**:
```dart
// 之前
final response = await ApiClient.instance.api.messages.getApiMessages();
final filtered = response.messages
    .where((msg) => msg.senderId == myId && msg.messageType != MessageType.system)
    .toList();

// 之后
final response = await ApiClient.instance.api.messages.getApiMessages(direction: 'sent');
final filtered = response.messages
    .where((msg) => msg.senderBipupuId == myId && msg.messageType != MessageType.system)
    .toList();
```

**影响**: 发件箱现在使用后端过滤，减少客户端处理

---

## 🚀 长轮询优化建议

### 当前实现
- 使用 `MessagePollResponse` 进行长轮询
- 支持 `last_msg_id` 和 `timeout` 参数
- 后端每秒检查一次新消息

### 优化方向

#### 1. **前端轮询策略优化**
```dart
// 建议：使用指数退避策略
int _pollInterval = 1000; // 初始 1 秒
const int _maxPollInterval = 30000; // 最大 30 秒

Future<void> _pollMessages() async {
  try {
    final response = await ApiClient.instance.api.messages.pollMessages(
      lastMsgId: _lastMessageId,
      timeout: 30,
    );
    
    if (response.messages.isNotEmpty) {
      // 重置轮询间隔
      _pollInterval = 1000;
      _updateMessages(response.messages);
      _lastMessageId = response.messages.last.id;
    } else {
      // 逐步增加轮询间隔
      _pollInterval = min(_pollInterval * 1.5, _maxPollInterval).toInt();
    }
  } catch (e) {
    debugPrint('Poll error: $e');
  }
}
```

#### 2. **后端轮询优化**
- 使用 WebSocket 替代长轮询（长期方案）
- 优化数据库查询性能
- 添加消息缓存层

#### 3. **客户端缓存策略**
```dart
// 建议：本地缓存最近消息
final List<MessageResponse> _cachedMessages = [];
final int _cacheSize = 100;

void _updateMessages(List<MessageResponse> newMessages) {
  _cachedMessages.insertAll(0, newMessages);
  if (_cachedMessages.length > _cacheSize) {
    _cachedMessages.removeRange(_cacheSize, _cachedMessages.length);
  }
}
```

---

## 📊 适配统计

| 文件 | 修改项 | 详情 |
|------|--------|------|
| received_messages_page.dart | 3 | direction 参数、senderBipupuId、receiverBipupuId |
| sent_messages_page.dart | 3 | direction 参数、senderBipupuId、receiverBipupuId |
| **总计** | **6** | 字段名称和 API 参数 |

---

## ✅ 验证清单

- [x] 字段名称全部更新
- [x] API 参数添加 direction
- [x] 编译无错误
- [x] 逻辑保持一致
- [ ] 长轮询性能测试（待优化）
- [ ] WebSocket 集成（长期计划）

---

## 🔗 相关文件

- 后端 Schema: [`backend/app/schemas/message.py`](../../backend/app/schemas/message.py)
- 后端 API: [`backend/app/api/routes/messages.py`](../../backend/app/api/routes/messages.py)
- 优化报告: [`backend/SCHEMA_OPTIMIZATION_REPORT.md`](../../backend/SCHEMA_OPTIMIZATION_REPORT.md)

---

## 📝 后续行动

1. **立即执行**:
   - ✅ 已完成字段名称适配
   - ✅ 已添加 direction 参数
   - 运行 Flutter 测试验证

2. **本周执行**:
   - 实现长轮询指数退避策略
   - 添加本地消息缓存
   - 性能测试和优化

3. **本月执行**:
   - 评估 WebSocket 集成方案
   - 实现实时消息推送
   - 优化用户体验

---

## 💡 注意事项

1. **字段名称**: 所有消息字段现在使用 `senderBipupuId` 和 `receiverBipupuId`
2. **API 参数**: `direction` 参数为必需，值为 `'sent'` 或 `'received'`
3. **向后兼容**: 确保生成的代码已更新，避免使用旧字段名
4. **性能**: 长轮询可能影响电池续航，建议后续优化

