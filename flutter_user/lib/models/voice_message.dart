class VoiceMessage {
  final String text;
  final String waveData; // Base64 encoded

  VoiceMessage({required this.text, required this.waveData});

  Map<String, dynamic> toJson() {
    return {'text': text, 'wave_data': waveData};
  }

  factory VoiceMessage.fromJson(Map<String, dynamic> json) {
    return VoiceMessage(
      text: json['text'] as String,
      waveData: json['wave_data'] as String,
    );
  }
}
