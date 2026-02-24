# 消息功能模块

## 概述

本模块是BIPU机消息系统的移动端实现，完全重新设计以满足实际需求。消息功能不再是类微信的聊天页面，而是消息分类查看的消息列表，用于浏览收到/发出的消息详情。

## 核心设计理念

1. **非聊天式设计**：消息是单向传递的，不可撤回、不可编辑、不可转发
2. **消息分类查看**：按类型组织消息，便于管理和查找
3. **服务号订阅管理**：提供友好的服务号推送开关和自定义推送时间选择
4. **语音消息支持**：集成声纹信息图片显示与导出功能

## 功能模块

### 1. 消息列表 (`MessageListScreen`)
- **收到的消息**：通过消息类型字段为非系统筛选
- **发出的消息**：用户发送给其他用户的消息
- **系统消息**：通过消息类型字段为系统筛选
- **收藏消息**：用户标记为重要的消息

### 2. 消息详情 (`MessageDetailScreen`)
- 查看单条消息的完整内容
- 语音消息波形可视化显示
- 波形图片导出功能
- 消息收藏/取消收藏
- 消息删除操作

### 3. 服务号管理 (`ServiceSubscriptionScreen`)
- 服务号列表浏览
- 订阅/取消订阅服务号
- 推送时间设置（支持自定义时间选择）
- 推送启用/禁用开关
- 推送时间来源标识（自定义/默认）

### 4. 主消息页面 (`MessageMainScreen`)
- 整合所有消息功能入口
- 消息统计信息展示
- 快捷功能导航
- 未读消息计数

## 技术架构

### 状态管理
使用 Riverpod 2.0 进行状态管理：

```dart
// 核心 Provider
messageListProvider(MessageFilter) - 消息列表状态管理
messageDetailProvider(int) - 消息详情状态管理
serviceSubscriptionProvider - 服务号订阅状态管理
messagePollingProvider - 消息轮询服务

// 控制器
messageControllerProvider(MessageFilter) - 消息操作控制器
serviceSubscriptionControllerProvider - 服务号订阅控制器
```

### 数据模型
- `MessageResponse` - 消息响应模型（匹配后端API）
- `MessageFilter` - 消息筛选枚举
- `ServiceAccount` - 服务号模型

### UI组件
- 响应式设计，支持不同屏幕尺寸
- 使用 Material 3 设计语言
- 自定义波形可视化组件
- 时间选择器组件

## API集成

### 消息相关接口
- `GET /api/messages/` - 获取消息列表（支持 direction 参数）
- `GET /api/messages/poll` - 长轮询获取新消息
- `GET /api/messages/favorites` - 获取收藏消息
- `POST /api/messages/{id}/favorite` - 收藏消息
- `DELETE /api/messages/{id}` - 删除消息

### 服务号相关接口
- `GET /api/service_accounts/subscriptions` - 获取用户订阅列表
- `GET /api/service_accounts/{name}/settings` - 获取订阅设置
- `PUT /api/service_accounts/{name}/settings` - 更新订阅设置

## 特色功能

### 1. 语音消息波形可视化
- 使用 `WaveformImageExporter` 生成波形图片
- 支持高分辨率导出（PNG格式）
- 可自定义颜色和尺寸
- 支持批量导出

### 2. 智能时间显示
- 今天/昨天的时间格式化
- 推送时间智能解析
- 时间来源标识

### 3. 服务号推送管理
- 自定义推送时间设置
- 启用/禁用推送开关
- 推送时间来源追踪
- 批量操作支持

## 使用示例

### 导航到消息功能
```dart
// 导航到主消息页面
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const MessageMainScreen(),
  ),
);

// 导航到特定消息列表
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const MessageListScreen(
      initialFilter: MessageFilter.received,
    ),
  ),
);
```

### 使用消息控制器
```dart
final controller = ref.read(messageControllerProvider(MessageFilter.received));

// 加载消息
await controller.loadMessages();

// 收藏消息
await controller.addFavorite(messageId, note: '重要消息');

// 删除消息
await controller.deleteMessage(messageId);
```

## 设计原则

1. **一致性**：所有消息操作遵循不可撤回、不可编辑的原则
2. **可访问性**：支持屏幕阅读器和键盘导航
3. **性能优化**：分页加载、图片懒加载、状态缓存
4. **错误处理**：完善的错误提示和重试机制
5. **用户体验**：直观的操作流程，清晰的反馈提示

## 未来扩展

1. **消息搜索**：全文搜索和高级筛选
2. **消息分类**：用户自定义标签和分类
3. **批量操作**：批量删除、批量收藏
4. **消息统计**：详细的消息统计和分析
5. **推送通知**：实时消息推送提醒

## 注意事项

1. 消息一旦发送无法撤回或编辑
2. 系统消息和服务号消息有特殊标识
3. 语音消息需要后端提供 waveform 数据
4. 服务号推送时间设置需要后端支持
5. 所有操作都需要用户认证

## 依赖项

- flutter_riverpod: ^2.0.0
- hooks_riverpod: ^2.0.0
- shadcn_ui: ^0.0.1
- intl: ^0.18.0
- freezed_annotation: ^2.0.0

## 开发指南

1. 所有新功能必须添加相应的测试
2. UI组件必须支持深色模式
3. 国际化字符串必须使用本地化文件
4. 错误处理必须提供用户友好的提示
5. 性能敏感操作必须添加加载状态

## 维护者

- 消息功能模块维护团队
- 问题反馈：issues@bipupu.com
- 文档更新：docs@bipupu.com