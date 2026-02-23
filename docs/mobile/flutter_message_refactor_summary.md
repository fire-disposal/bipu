# Flutter 消息重构实现总结

## 📋 更新内容

根据 `message_refactor.md` 文档，已完成以下 Flutter 部分的更新：

---

## 1. 消息模型更新

### 文件：`lib/shared/models/message_model.dart`

#### 新增 `waveform` 字段

**MessageCreate**:
```dart
@freezed
class MessageCreate with _$MessageCreate {
  const factory MessageCreate({
    required String receiverId,
    required String content,
    @Default('NORMAL') String messageType,
    Map<String, dynamic>? pattern,
    List<int>? waveform,  // 新增：音频振幅包络数据
  }) = _MessageCreate;
}
```

**MessageResponse**:
```dart
@freezed
class MessageResponse with _$MessageResponse {
  const factory MessageResponse({
    required int id,
    required String senderBipupuId,
    required String receiverBipupuId,
    required String content,
    required String messageType,
    Map<String, dynamic>? pattern,
    List<int>? waveform,  // 新增：音频振幅包络数据
    required DateTime createdAt,
  }) = _MessageResponse;
}
```

**字段规范**:
- 类型：`List<int>?`
- 格式：0-255 的整数数组
- 建议长度：不超过 128

---

## 2. REST API 客户端更新

### 文件：`lib/core/api/rest_client.dart`

#### 新增长轮询 API

```dart
/// 长轮询获取新消息
@GET('/api/messages/poll')
Future<List<Map<String, dynamic>>> pollMessages({
  @Query('last_msg_id') required int lastMsgId,
  @Query('timeout') int? timeout,
});
```

**参数说明**:
- `last_msg_id`: 最后收到的消息 ID，初始为 0
- `timeout`: 超时时间（秒），默认 30，最大 120

**响应**: 新消息数组（`List<Map<String, dynamic>>`）

---

## 3. 长轮询服务更新

### 文件：`lib/core/services/polling_service.dart`

#### 适配新 API

**更新内容**:
1. 使用新的 `/api/messages/poll` 端点
2. 正确传递 `last_msg_id` 和 `timeout` 参数
3. 响应解析为 `List<MessageResponse>`

**核心代码**:
```dart
Future<void> _pollOnce() async {
  final lastMsgId = _lastMessageId ?? 0;
  
  final response = await _dio.get<List>(
    '/api/messages/poll',
    queryParameters: {
      'last_msg_id': lastMsgId,
      'timeout': 30,
    },
  );

  if (response.data != null && response.data!.isNotEmpty) {
    final newMessages = response.data!
        .map((msg) => MessageResponse.fromJson(msg))
        .toList();
    
    _messageStreamController.add(newMessages);
    _lastMessageId = newMessages.last.id;
  }
}
```

---

## 4. 波形可视化工具

### 文件：`lib/shared/widgets/waveform_visualizer.dart`

#### WaveformValidator - 数据验证

```dart
// 验证波形数据
WaveformValidator.validate(waveform);  // bool

// 规范化数据
WaveformValidator.normalize(waveform);  // List<int>

// 缩放到指定长度
WaveformValidator.scale(waveform, 64);  // List<int>
```

#### WaveformPainter - 波形绘制

```dart
// 绘制到 Canvas
WaveformPainter.drawWaveform(
  waveform,
  canvas,
  size,
  color: Colors.blue,
  style: WaveformStyle.line,  // 或 WaveformStyle.bar
);

// 创建预览字符串
final preview = WaveformPainter.createPreview(waveform);
// 输出：▁▂▃▄▅▆▇█
```

#### WaveformVisualizer - 可视化组件

```dart
WaveformVisualizer(
  waveform: message.waveform,
  width: 200,
  height: 60,
  color: Theme.of(context).colorScheme.primary,
  style: WaveformStyle.line,
)
```

#### WaveformInfo - 波形信息

```dart
final info = WaveformInfo.fromWaveform(waveform);
print('采样点：${info?.sampleCount}');
print('峰值：${info?.peak}');
print('平均：${info?.average}');
print('预览：${info?.preview}');
```

---

## 5. 波形图片导出工具

### 文件：`lib/shared/widgets/waveform_image_exporter.dart`

#### WaveformImageExporter - 导出功能

**导出为 PNG 字节**:
```dart
final pngBytes = await WaveformImageExporter.exportToPng(
  waveform,
  width: 400,
  height: 120,
  color: Colors.blue,
  backgroundColor: Colors.white,
);
```

**保存到文件**:
```dart
final filePath = await WaveformImageExporter.saveToFile(
  waveform,
  fileName: 'voice_message_123',
);
```

**生成缩略图**:
```dart
final thumbnail = await WaveformImageExporter.generateThumbnail(
  waveform,
  size: 64,
);
```

**批量导出**:
```dart
final paths = await WaveformImageExporter.batchExport(
  waveforms,
  outputDir: '/path/to/output',
  fileNamePrefix: 'waveform',
);
```

#### WaveformImagePreview - 图片预览组件

```dart
WaveformImagePreview(
  waveform: message.waveform,
  width: 200,
  height: 60,
  color: Colors.blue,
)
```

---

## 6. 使用示例

### 发送语音消息

```dart
// 创建语音消息
final message = MessageCreate(
  receiverId: 'user456',
  content: '这是一条语音消息',
  messageType: 'VOICE',
  waveform: [12, 45, 100, 20, 78, 90, 34, 67],  // 波形数据
);

// 发送
await ref.read(restClientProvider).sendMessage(message.toJson());
```

### 显示语音消息波形

```dart
// 在消息气泡中显示波形
if (message.messageType == 'VOICE' && message.waveform != null) {
  WaveformVisualizer(
    waveform: message.waveform,
    width: double.infinity,
    height: 60,
    color: Theme.of(context).colorScheme.primary,
  );
}
```

### 导出波形图片

```dart
// 导出并分享
final pngBytes = await WaveformImageExporter.exportToPng(
  message.waveform,
  width: 400,
  height: 120,
);

if (pngBytes != null) {
  // 分享或保存
  await Share.shareXFiles([XFile.fromData(pngBytes)]);
}
```

---

## 7. 后续工作

### 需要运行的命令

```bash
cd D:\code\WORKING\bipupu\mobile

# 1. 安装依赖
flutter pub get

# 2. 运行代码生成器
flutter pub run build_runner build --delete-conflicting-outputs
```

### 待完成的工作

1. **集成到消息气泡组件** - 在 `msg_bubble.dart` 中添加波形显示
2. **语音消息播放功能** - 集成音频播放
3. **录音功能** - 录制音频并生成 waveform 数据
4. **长轮询集成** - 在 App 生命周期中管理轮询服务

---

## 8. API 对照表

| 后端 API | Flutter 方法 | 说明 |
|----------|-------------|------|
| `POST /api/messages/` | `restClient.sendMessage()` | 发送消息（支持 waveform） |
| `GET /api/messages/poll` | `pollingService._pollOnce()` | 长轮询获取新消息 |
| `waveform: number[]` | `List<int>? waveform` | 波形数据字段 |

---

## 9. 注意事项

1. **波形数据验证**: 使用 `WaveformValidator.validate()` 确保数据有效
2. **内存管理**: 大量波形数据使用 `scale()` 缩放以减少内存
3. **性能优化**: 长波形使用 `WaveformStyle.bar` 绘制更快
4. **缓存**: 导出的图片可以缓存以避免重复生成

---

**文档版本**: 1.0  
**更新时间**: 2026-02-23
