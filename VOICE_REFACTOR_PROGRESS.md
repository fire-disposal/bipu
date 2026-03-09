# VOICE 层重构进展报告

## 已完成的工作

### 1. 删除的冗余文件（6 个）
- ❌ `asr_engine.dart` (485 行) - 改用系统 speech_to_text
- ❌ `tts_engine.dart` (123 行) - 简化为 tts_worker.dart
- ❌ `tts_isolate.dart` (224 行) - 简化后合并到 tts_worker.dart
- ❌ `audio_player.dart` (165 行) - 合并到 voice_service.dart
- ❌ `audio_resource_manager.dart` (79 行) - 单通话无需队列锁
- ❌ `model_manager.dart` (182 行) - 简化后合并到 tts_worker.dart
- ❌ `pager_assistant.dart` (216 行) - 职责重复，直接使用 VoiceService

**删除总行数：~1474 行**

### 2. 新增的简化文件（4 个）
- ✅ `voice_service.dart` (220 行) - 统一 TTS/ASR 入口
- ✅ `tts_worker.dart` (197 行) - Isolate TTS 生成
- ✅ `pager_vm.dart` (~300 行) - 替代 PagerCubit（未使用）
- ✅ `pager_phase.dart` (10 行) - 简化版状态枚举

**新增总行数：~727 行**

### 3. 净减少代码
**总计减少：~747 行（-51%）**

### 4. 依赖变更
```yaml
# 移除
- sherpa_onnx: ^1.12.20  # 仅用于 TTS，ASR 改用系统 API
- sound_stream: ^0.4.2   # 不再需要

# 新增
+ speech_to_text: ^7.3.0  # 系统 ASR
```

## 当前状态

### ✅ 可用组件
- `VoiceService` - 新的简化语音服务
- `TtsWorker` - TTS Isolate 后台生成
- `PagerVM` - 新的 ViewModel（备用）

### ⚠️ 保留的旧组件（为兼容现有 UI）
- `pager_cubit.dart` - 现有 UI 仍在使用
- `pager_state_machine.dart` - 状态定义
- `voice_service_unified.dart` - 备用

## 下一步工作

### Phase 1: 测试新 VoiceService
```bash
cd mobile && flutter pub get
# 测试 TTS 播放
# 测试 ASR 录音
```

### Phase 2: 迁移 PagerVM（可选）
如需完全迁移到 PagerVM，需要：
1. 修改 `pager_page.dart` 使用 `PagerVM`
2. 测试所有业务流程
3. 删除 `pager_cubit.dart` 和 `pager_state_machine.dart`

### Phase 3: 清理
- 删除未使用的旧文件
- 更新文档

## 架构对比

### 旧架构
```
PagerPage → PagerCubit (682 行) → PagerAssistant (216 行) → VoiceService (216 行)
                ↓                        ↓
        State Machine            TTSEngine + ASREngine
        (7 个状态类)              (各 100-400 行)
```

### 新架构
```
PagerPage → PagerVM (300 行) → VoiceService (220 行)
                                  ↓
                          TtsWorker (197 行) + System ASR
```

## 关键改进

1. **单例简化** - VoiceService 直接作为全局 singleton
2. **ASR 简化** - 使用系统 speech_to_text，删除 485 行复杂队列处理
3. **资源管理** - 删除 AudioResourceManager，单通话无需队列锁
4. **状态简化** - PagerVM 使用 ChangeNotifier 而非 Cubit

## 风险

1. **系统 ASR 识别率** - 可能不如本地 sherpa_onnx
2. **平台兼容性** - speech_to_text 在 iOS/Android 表现可能不同
3. **网络依赖** - 某些设备的系统 ASR 需要网络

## 建议

保留现有 `pager_cubit.dart` 和 `voice_service_unified.dart` 作为 fallback，逐步验证新架构的稳定性后再完全切换。
