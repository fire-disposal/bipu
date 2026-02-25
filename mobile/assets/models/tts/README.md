# TTS 模型文件说明

## 所需文件

要使用 TTS 功能，您需要在 `assets/models/tts/` 目录下放置以下模型文件：

1. **vits-zh-hf-fanchen-C.onnx** - 主要的 TTS 模型文件
2. **tokens.txt** - 令牌文件
3. **lexicon.txt** - 词典文件
4. **phone.fst** - 音素 FST 文件
5. **date.fst** - 日期 FST 文件
6. **number.fst** - 数字 FST 文件
7. **new_heteronym.fst** - 异读词 FST 文件

## 获取模型文件

### 方法 1：从原始仓库获取

这些文件可以从以下来源获取：

1. **Sherpa Onnx 官方仓库**：
   - 访问：https://github.com/k2-fsa/sherpa-onnx
   - 在 `sherpa-onnx` 仓库中查找预训练的中文 TTS 模型

2. **VITS 模型**：
   - 模型名称：`vits-zh-aishell3`
   - 支持 174 个说话人（speaker ID: 0-173）
   - 采样率：22050 Hz

### 方法 2：使用预训练模型

您可以从以下链接下载预训练模型：

```
https://huggingface.co/spaces/k2-fsa/sherpa-onnx-tts/tree/main
```

### 方法 3：自行训练

如果您需要自定义模型，可以参考以下资源：

1. **VITS 训练教程**：https://github.com/jaywalnut310/vits
2. **ONNX 导出指南**：https://github.com/k2-fsa/sherpa-onnx/wiki

## 文件结构

放置好文件后，目录结构应该如下所示：

```
assets/models/tts/
├── vits-zh-hf-fanchen-C.onnx
├── tokens.txt
├── lexicon.txt
├── phone.fst
├── date.fst
├── number.fst
└── new_heteronym.fst
```

## 模型规格

- **模型类型**：VITS (Variational Inference with adversarial learning for end-to-end Text-to-Speech)
- **语言**：中文
- **说话人数量**：174
- **采样率**：22050 Hz
- **模型大小**：约 200-300 MB（取决于量化方式）

## 使用说明

1. 将上述所有文件下载到 `assets/models/tts/` 目录
2. 确保文件名称与上述列表完全一致
3. 运行应用时，TTS 引擎会自动加载这些模型文件
4. 首次使用可能需要一些时间将模型文件复制到设备本地存储

## 注意事项

1. **文件完整性**：确保所有 7 个文件都存在且完整
2. **文件权限**：确保应用有读取这些文件的权限
3. **存储空间**：模型文件较大，请确保设备有足够的存储空间
4. **首次加载**：首次初始化 TTS 引擎可能需要较长时间（30-60秒）

## 故障排除

如果 TTS 功能无法正常工作，请检查：

1. ✅ 所有 7 个文件是否都存在
2. ✅ 文件名称是否完全正确
3. ✅ 文件是否完整（没有损坏）
4. ✅ 应用是否有读取权限
5. ✅ 设备存储空间是否充足

## 性能优化

1. **量化模型**：使用 INT8 量化模型可以减少内存占用
2. **线程数**：可以在代码中调整 `numThreads` 参数
3. **缓存**：频繁使用的语音可以缓存到本地

## 更新日志

- **2024-01-01**：初始版本说明
- **2024-01-26**：添加模型获取链接和故障排除指南