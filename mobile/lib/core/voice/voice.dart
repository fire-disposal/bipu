/// 导出统一的语音服务API
/// 所有业务层应该仅使用 VoiceService（通过 PagerAssistant 对接）
/// 底层实现细节（TTS、ASR、AudioPlayer）为内部实现，不对外暴露
library voice;

export 'voice_service_unified.dart';
