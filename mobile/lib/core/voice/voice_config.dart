/// 语音服务配置文件：集中管理所有模型文件名和路径
class VoiceConfig {
  // ============ ASR 模型配置 ============
  static const Map<String, String> asrModelFiles = {
    'asr/encoder-epoch-99-avg-1.int8.onnx':
        'assets/models/asr/encoder-epoch-99-avg-1.int8.onnx',
    'asr/decoder-epoch-99-avg-1.onnx':
        'assets/models/asr/decoder-epoch-99-avg-1.onnx',
    'asr/joiner-epoch-99-avg-1.int8.onnx':
        'assets/models/asr/joiner-epoch-99-avg-1.int8.onnx',
    'asr/tokens.txt': 'assets/models/asr/tokens.txt',
  };

  // ASR 模型文件名常量
  static const String asrEncoder = 'encoder-epoch-99-avg-1.int8.onnx';
  static const String asrDecoder = 'decoder-epoch-99-avg-1.onnx';
  static const String asrJoiner = 'joiner-epoch-99-avg-1.int8.onnx';
  static const String asrTokens = 'tokens.txt';

  // ============ TTS 模型配置 ============
  static const Map<String, String> ttsModelFiles = {
    'tts/vits-aishell3.onnx': 'assets/models/tts/vits-aishell3.onnx',
    'tts/tokens.txt': 'assets/models/tts/tokens.txt',
    'tts/lexicon.txt': 'assets/models/tts/lexicon.txt',
    'tts/phone.fst': 'assets/models/tts/phone.fst',
    'tts/date.fst': 'assets/models/tts/date.fst',
    'tts/number.fst': 'assets/models/tts/number.fst',
    'tts/new_heteronym.fst': 'assets/models/tts/new_heteronym.fst',
  };

  // TTS 模型文件名常量
  static const String ttsModel = 'vits-aishell3';
  static const String ttsTokens = 'tokens';
  static const String ttsLexicon = 'lexicon';
  static const String ttsPhone = 'phone';
  static const String ttsDate = 'date';
  static const String ttsNumber = 'number';
  static const String ttsHeteronym = 'new_heteronym';

  // ============ ASR 配置参数 ============
  static const int asrSampleRate = 16000;
  static const int asrFeatureDim = 80;
  static const int asrNumThreads = 1;
  static const String asrProvider = 'cpu';
  static const String asrModelType = 'zipformer';
  static const bool asrDebug = false;
  static const bool asrEnableEndpoint = true;

  // ============ TTS 配置参数 ============
  static const int ttsNumThreads = 1;
  static const bool ttsDebug = false;
  static const int ttsDefaultSpeaker = 0;
  static const double ttsDefaultSpeed = 1.0;
}
