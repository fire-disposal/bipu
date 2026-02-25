# ASR 模型文件说明

## 所需文件

要使用 ASR（自动语音识别）功能，您需要在 `assets/models/asr/` 目录下放置以下模型文件：

1. **encoder-epoch-99-avg-1.int8.onnx** - 编码器模型（INT8量化）
2. **decoder-epoch-99-avg-1.int8.onnx** - 解码器模型（INT8量化）
3. **joiner-epoch-99-avg-1.int8.onnx** - 连接器模型（INT8量化）
4. **tokens.txt** - 令牌文件
5. **words.txt** - 词汇文件（可选，用于词级识别）

## 获取模型文件

### 方法 1：从原始仓库获取

这些文件可以从以下来源获取：

1. **Sherpa Onnx 官方仓库**：
   - 访问：https://github.com/k2-fsa/sherpa-onnx
   - 在 `sherpa-onnx` 仓库中查找预训练的中文 ASR 模型

2. **预训练模型**：
   - 模型名称：`sherpa-onnx-zipformer-zh-14M-2023-02-23`
   - 支持流式识别
   - 采样率：16000 Hz

### 方法 2：使用预训练模型

您可以从以下链接下载预训练模型：

```
https://huggingface.co/spaces/k2-fsa/sherpa-onnx-asr/tree/main
```

### 方法 3：自行训练

如果您需要自定义模型，可以参考以下资源：

1. **Icefall 训练框架**：https://github.com/k2-fsa/icefall
2. **ONNX 导出指南**：https://github.com/k2-fsa/sherpa-onnx/wiki

## 文件结构

放置好文件后，目录结构应该如下所示：

```
assets/models/asr/
├── encoder-epoch-99-avg-1.int8.onnx
├── decoder-epoch-99-avg-1.int8.onnx
├── joiner-epoch-99-avg-1.int8.onnx
├── tokens.txt
└── words.txt (可选)
```

## 模型规格

- **模型类型**：Zipformer（流式端到端ASR）
- **语言**：中文
- **采样率**：16000 Hz
- **音频格式**：PCM16，单声道
- **模型大小**：约 50-100 MB（INT8量化后）

## 使用说明

1. 将上述所有文件下载到 `assets/models/asr/` 目录
2. 确保文件名称与上述列表完全一致
3. 运行应用时，ASR 引擎会自动加载这些模型文件
4. 首次使用可能需要一些时间将模型文件复制到设备本地存储

## 音频要求

ASR 引擎对输入音频有以下要求：

1. **采样率**：16000 Hz
2. **格式**：PCM16，单声道
3. **位深度**：16位
4. **声道**：单声道
5. **音频长度**：建议 0.5-30 秒

## 性能指标

- **延迟**：流式识别，实时因子 < 0.1
- **准确率**：在 AISHELL-1 测试集上 CER < 5%
- **内存占用**：约 100-200 MB
- **CPU 使用率**：单线程约 10-20%

## 注意事项

1. **文件完整性**：确保所有必需文件都存在且完整
2. **音频预处理**：输入音频必须符合上述规格要求
3. **实时性**：流式识别支持实时语音转文字
4. **离线运行**：所有处理在设备本地完成，无需网络连接

## 故障排除

如果 ASR 功能无法正常工作，请检查：

1. ✅ 所有必需文件是否都存在
2. ✅ 文件名称是否完全正确
3. ✅ 文件是否完整（没有损坏）
4. ✅ 输入音频是否符合规格要求
5. ✅ 应用是否有读取权限

## 性能优化建议

1. **线程配置**：根据设备性能调整识别线程数
2. **缓冲区大小**：优化音频缓冲区大小以平衡延迟和准确率
3. **VAD 集成**：集成语音活动检测以减少误识别
4. **热词增强**：为特定词汇设置更高的识别权重

## 更新日志

- **2024-01-01**：初始版本说明
- **2024-01-26**：添加模型获取链接和性能指标
- **2024-02-15**：更新音频规格要求和故障排除指南

## 相关资源

1. **官方文档**：https://k2-fsa.github.io/sherpa/onnx/
2. **示例代码**：https://github.com/k2-fsa/sherpa-onnx/tree/master/examples
3. **模型仓库**：https://huggingface.co/k2-fsa
4. **社区支持**：https://github.com/k2-fsa/sherpa-onnx/discussions